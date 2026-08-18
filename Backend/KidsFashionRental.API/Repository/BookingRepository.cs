using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;
using System.Text.Json;

namespace KidsFashionRental.API.Repository;

public class BookingRepository : IBookingRepository
{
    private static bool _dbInitialized = false;
    private static readonly object _dbLock = new();

    public BookingRepository()
    {
        EnsureDbInitialized();
    }

    private void EnsureDbInitialized()
    {
        lock (_dbLock)
        {
            try
            {
                using var conn = new Microsoft.Data.SqlClient.SqlConnection(AppConfiguration.ConnectionString);
                conn.Open();

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
                        IF COL_LENGTH('tblBookings', 'DeliverySession') IS NULL
                            ALTER TABLE tblBookings ADD DeliverySession VARCHAR(20) NULL;
                        IF COL_LENGTH('tblBookings', 'ReturnSession') IS NULL
                            ALTER TABLE tblBookings ADD ReturnSession VARCHAR(20) NULL;";
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
CREATE OR ALTER PROCEDURE SP_AddBooking
    @CompanyID INT, @BookingNo VARCHAR(50), @CustomerID INT, @BookingCreatedBy INT,
    @BookingDate DATE, @StartDate DATE, @EndDate DATE, @DeliveryDate DATE, @ReturnDate DATE,
    @RentDays INT, @TotalRentAmount DECIMAL(18,2), @DiscountAmount DECIMAL(18,2),
    @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2), @RemainingAmount DECIMAL(18,2),
    @TotalAmount DECIMAL(18,2), @ExtraChargePerDay DECIMAL(18,2), @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX), @BookingDetailsJson NVARCHAR(MAX),
    @DeliverySession VARCHAR(20) = NULL, @ReturnSession VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO tblBookings(CompanyID,BookingNo,CustomerID,BookingCreatedBy,BookingDate,StartDate,EndDate,
            DeliveryDate,ReturnDate,RentDays,TotalRentAmount,DiscountAmount,DepositAmount,AdvanceAmount,
            RemainingAmount,TotalAmount,ExtraChargePerDay,BookingStatus,PaymentStatus,Notes,
            DeliverySession,ReturnSession)
        VALUES(@CompanyID,@BookingNo,@CustomerID,@BookingCreatedBy,@BookingDate,@StartDate,@EndDate,
            @DeliveryDate,@ReturnDate,@RentDays,@TotalRentAmount,@DiscountAmount,@DepositAmount,@AdvanceAmount,
            @RemainingAmount,@TotalAmount,@ExtraChargePerDay,@BookingStatus,@PaymentStatus,@Notes,
            @DeliverySession,@ReturnSession);

        DECLARE @BookingID INT = SCOPE_IDENTITY();

        INSERT INTO tblBookingDetails(BookingID,ProductID,ProductCode,ProductName,Size,Color,RentAmount,DepositAmount,DiscountPercent,FinalRentAmount)
        SELECT @BookingID, ProductID, ProductCode, ProductName, Size, Color, RentAmount, DepositAmount, DiscountPercent, FinalRentAmount
        FROM OPENJSON(@BookingDetailsJson)
        WITH (
            ProductID INT, ProductCode VARCHAR(50), ProductName VARCHAR(200), Size VARCHAR(50), Color VARCHAR(50),
            RentAmount DECIMAL(18,2), DepositAmount DECIMAL(18,2), DiscountPercent DECIMAL(18,2), FinalRentAmount DECIMAL(18,2)
        );

        UPDATE P SET IsAvailable = 0, CurrentBookingID = @BookingID, NextAvailableDate = DATEADD(DAY,1,@ReturnDate)
        FROM tblProducts P
        INNER JOIN tblBookingDetails BD ON P.ProductID = BD.ProductID
        WHERE BD.BookingID = @BookingID;

        INSERT INTO tblNotifications(CompanyID,Title,Message,NotificationType,ReferenceID,UserID)
        VALUES(@CompanyID,'New Booking','Booking '+@BookingNo+' created','Booking',@BookingID,@BookingCreatedBy);

        COMMIT;
        SELECT 1 AS Success, 'Booking Added Successfully' AS Message, @BookingID AS ID, @BookingNo AS BookingNo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID, '' AS BookingNo;
    END CATCH
END";
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
CREATE OR ALTER PROCEDURE SP_UpdateBooking
    @BookingID INT, @DeliveryDate DATE, @ReturnDate DATE, @RentDays INT,
    @TotalRentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2),
    @RemainingAmount DECIMAL(18,2), @TotalAmount DECIMAL(18,2), @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX),
    @DeliverySession VARCHAR(20) = NULL, @ReturnSession VARCHAR(20) = NULL
AS
BEGIN
    UPDATE tblBookings SET
        DeliveryDate=@DeliveryDate, ReturnDate=@ReturnDate, RentDays=@RentDays,
        TotalRentAmount=@TotalRentAmount, DepositAmount=@DepositAmount, AdvanceAmount=@AdvanceAmount,
        RemainingAmount=@RemainingAmount, TotalAmount=@TotalAmount,
        BookingStatus=@BookingStatus, PaymentStatus=@PaymentStatus, Notes=@Notes,
        DeliverySession=@DeliverySession, ReturnSession=@ReturnSession
    WHERE BookingID=@BookingID;
    SELECT 1 AS Success, 'Booking Updated' AS Message, @BookingID AS ID;
END";
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, @Search VARCHAR(100) = NULL, @Status VARCHAR(50) = NULL,
    @BranchID INT = NULL, @FromDate DATE = NULL, @ToDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount, B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID,
           B.DeliverySession, B.ReturnSession
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@Status IS NULL OR @Status = '' OR B.BookingStatus = @Status)
      AND (@FilterUserID IS NULL OR @FilterUserID = 0 OR B.BookingCreatedBy = @FilterUserID)
      AND (@FromDate IS NULL OR CAST(B.DeliveryDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.DeliveryDate AS DATE) <= @ToDate)
      AND (@Search IS NULL OR @Search = '' OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%' OR EXISTS(SELECT 1 FROM tblBookingDetails BD WHERE BD.BookingID = B.BookingID AND BD.ProductCode LIKE '%'+@Search+'%'))
    ORDER BY B.DeliveryDate DESC, B.BookingNo;
END";
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingNo, C.FullName AS CustomerName, BD.ProductName, B.DeliveryDate,
           B.RemainingAmount AS PendingAmount, B.PaymentStatus, B.BookingStatus AS DeliveryStatus,
           B.DeliverySession, B.ReturnSession
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted=0 AND CAST(B.DeliveryDate AS DATE)=@ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID);
END";
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = @"
CREATE OR ALTER PROCEDURE SP_TodayReturnReport @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingNo, C.FullName AS CustomerName, BD.ProductName, B.ReturnDate,
           B.ExtraDays, B.ExtraChargeAmount, B.FinalRefundAmount, B.FinalProfitAmount,
           B.DeliverySession, B.ReturnSession
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted=0 AND CAST(B.ReturnDate AS DATE)=@ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID);
END";
                    cmd.ExecuteNonQuery();
                }

                _dbInitialized = true;
            }
            catch (Exception)
            {
                // Silently bypass
            }
        }
    }

    private static DateTime? CleanDate(DateTime? dt) =>
        dt.HasValue && dt.Value.Year >= 1753 && dt.Value.Year <= 9999 ? dt.Value : null;

    /// <summary>SQL OPENJSON WITH clause expects PascalCase keys matching C# property names.</summary>
    private static readonly JsonSerializerOptions SqlJsonOptions = new()
    {
        PropertyNamingPolicy = null,
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.Never
    };

    private class BookingNoRow
    {
        public string BookingNo { get; set; } = string.Empty;
    }
    public async Task<ApiResult> GetAllAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var reportDate = CleanDate(filter.ReportDate);
            var fromDate = CleanDate(filter.FromDate) ?? reportDate;
            var toDate = CleanDate(filter.ToDate) ?? reportDate;

            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("Search", filter.Search);
            p.Add("Status", filter.Status);
            p.Add("FromDate", fromDate);
            p.Add("ToDate", toDate);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QueryAsync<BookingListModel>("SP_GetAllBookings", p);
            result.Success = true;
            result.Message = "Bookings retrieved";
            result.Data = data;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetByIdAsync(BookingByIdModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("BookingID", model.BookingID);
            using var multi = await BaseDataProvider.QueryMultipleAsync("SP_GetBookingByID", p);
            var header = await multi.ReadFirstOrDefaultAsync<object>();
            var items = (await multi.ReadAsync<object>()).ToList();
            var payments = (await multi.ReadAsync<object>()).ToList();
            result.Success = header != null;
            result.Message = result.Success ? "Booking found" : "Not found";
            result.Data = new { header, items, payments };
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> CreateAsync(BookingCreateModel model)
    {
        var result = new ApiResult();
        try
        {
            var bookingNoRow = await BaseDataProvider.QuerySingleAsync<BookingNoRow>("SP_GetNextBookingNo");
            var bookingNo = !string.IsNullOrWhiteSpace(bookingNoRow?.BookingNo)
                ? bookingNoRow!.BookingNo
                : $"BK{DateTime.Now:yyyyMMddHHmmss}";

            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("BranchID", model.BranchID > 0 ? model.BranchID : (int?)null);
            p.Add("BookingNo", bookingNo);
            p.Add("CustomerID", model.CustomerID);
            p.Add("BookingCreatedBy", model.BookingCreatedBy);
            p.Add("BookingDate", model.BookingDate.Date);
            p.Add("StartDate", model.StartDate.Date);
            p.Add("EndDate", model.EndDate.Date);
            p.Add("DeliveryDate", model.DeliveryDate.Date);
            p.Add("ReturnDate", model.ReturnDate.Date);
            p.Add("RentDays", model.RentDays);
            p.Add("TotalRentAmount", model.TotalRentAmount);
            p.Add("DiscountAmount", model.DiscountAmount);
            p.Add("DepositAmount", model.DepositAmount);
            p.Add("AdvanceAmount", model.AdvanceAmount);
            p.Add("RemainingAmount", model.RemainingAmount);
            p.Add("TotalAmount", model.TotalAmount);
            p.Add("ExtraChargePerDay", model.ExtraChargePerDay);
            p.Add("ExtraDays", model.ExtraDays);
            p.Add("ExtraChargeAmount", model.ExtraChargeAmount);
            p.Add("BookingStatus", model.BookingStatus);
            p.Add("PaymentStatus", model.PaymentStatus);
            p.Add("DeliverySession", model.DeliverySession);
            p.Add("ReturnSession", model.ReturnSession);
            p.Add("Notes", model.Notes);
            p.Add("BookingDetailsJson", JsonSerializer.Serialize(model.Items, SqlJsonOptions));

            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_AddBooking", p);
            result.Success = response != null && response.Success == 1;
            result.Message = string.IsNullOrWhiteSpace(response?.Message)
                ? (result.Success ? "Booking saved" : "Booking save failed")
                : response!.Message;
            result.Data = response;
        }
        catch (Exception ex)
        {
            result.Success = false;
            result.Message = ex.Message;
        }
        return result;
    }

    public async Task<ApiResult> UpdateAsync(BookingUpdateModel model)
    {
        var result = new ApiResult();
        try
        {
            var deliveryDate = CleanDate(model.DeliveryDate) ?? DateTime.Today;
            var returnDate = CleanDate(model.ReturnDate) ?? deliveryDate.AddDays(1);

            var p = new DynamicParameters();
            p.Add("BookingID", model.BookingID);
            p.Add("DeliveryDate", deliveryDate.Date);
            p.Add("ReturnDate", returnDate.Date);
            p.Add("RentDays", model.RentDays);
            p.Add("TotalRentAmount", model.TotalRentAmount);
            p.Add("DepositAmount", model.DepositAmount);
            p.Add("AdvanceAmount", model.AdvanceAmount);
            p.Add("RemainingAmount", model.RemainingAmount);
            p.Add("TotalAmount", model.TotalAmount);
            p.Add("BookingStatus", model.BookingStatus);
            p.Add("PaymentStatus", model.PaymentStatus);
            p.Add("DeliverySession", model.DeliverySession);
            p.Add("ReturnSession", model.ReturnSession);
            p.Add("Notes", model.Notes);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_UpdateBooking", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Update failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> DeleteAsync(BookingByIdModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("BookingID", model.BookingID);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_DeleteBooking", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Delete failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> ProcessReturnAsync(ReturnProcessModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("BookingID", model.BookingID);
            p.Add("ActualReturnDate", model.ActualReturnDate.Date);
            p.Add("DamageDeductionAmount", model.DamageDeductionAmount);
            p.Add("ReturnNotes", model.ReturnNotes);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_ProcessReturn", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? (result.Success ? "Return processed" : "Return failed");
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> CheckAvailabilityAsync(AvailabilityRequestModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ProductCode", model.ProductCode);
            p.Add("DeliveryDate", model.DeliveryDate.Date);
            p.Add("ReturnDate", model.ReturnDate.Date);
            p.Add("ExcludeBookingID", model.ExcludeBookingID);
            var response = await BaseDataProvider.QuerySingleAsync<AvailabilityResponseModel>("SP_CheckProductAvailability", p);
            result.Success = response != null;
            result.Message = response?.Message ?? "Check failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetProductStatusByCodeAsync(string code, DateTime? deliveryDate = null, DateTime? returnDate = null)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ProductCode", code);
            p.Add("DeliveryDate", deliveryDate?.Date);
            p.Add("ReturnDate", returnDate?.Date);
            using var multi = await BaseDataProvider.QueryMultipleAsync("SP_GetProductStatusByCode", p);
            var product = await multi.ReadFirstOrDefaultAsync<dynamic>();
            var currentBooking = await multi.ReadFirstOrDefaultAsync<dynamic>();
            var bookings = (await multi.ReadAsync<dynamic>()).ToList();

            result.Success = true;
            result.Data = new
            {
                Product = product,
                IsAvailable = currentBooking == null,
                Status = currentBooking == null ? "Available" : "Not Available",
                CurrentBooking = currentBooking,
                AllBookings = bookings
            };
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetNextBookingNoAsync()
    {
        var result = new ApiResult();
        try
        {
            var data = await BaseDataProvider.QuerySingleAsync<dynamic>("SP_GetNextBookingNo");
            result.Success = true;
            result.Data = data;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> AddPaymentAsync(PaymentCreateModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("BookingID", model.BookingID);
            p.Add("PaymentType", model.PaymentType);
            p.Add("PaymentMode", model.PaymentMode);
            p.Add("PaymentAmount", model.PaymentAmount);
            p.Add("TransactionNo", model.TransactionNo);
            p.Add("Notes", model.Notes);
            p.Add("CreatedBy", model.CreatedBy);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_AddPayment", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Payment failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
