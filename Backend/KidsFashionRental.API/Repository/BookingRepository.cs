using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;
using System.Text.Json;

namespace KidsFashionRental.API.Repository;

public class BookingRepository : IBookingRepository
{
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
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("Search", filter.Search);
            p.Add("Status", filter.Status);
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
            var p = new DynamicParameters();
            p.Add("BookingID", model.BookingID);
            p.Add("DeliveryDate", model.DeliveryDate.Date);
            p.Add("ReturnDate", model.ReturnDate.Date);
            p.Add("RentDays", model.RentDays);
            p.Add("TotalRentAmount", model.TotalRentAmount);
            p.Add("DepositAmount", model.DepositAmount);
            p.Add("AdvanceAmount", model.AdvanceAmount);
            p.Add("RemainingAmount", model.RemainingAmount);
            p.Add("TotalAmount", model.TotalAmount);
            p.Add("BookingStatus", model.BookingStatus);
            p.Add("PaymentStatus", model.PaymentStatus);
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
