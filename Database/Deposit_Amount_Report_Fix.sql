-- Fix deposit showing ₹0 on Today Return Report & booking list
-- Run on your SQL Server database

-- 1) Backfill booking header deposit from line items
UPDATE B
SET B.DepositAmount = D.SumDeposit
FROM tblBookings B
INNER JOIN (
    SELECT BookingID, SUM(ISNULL(DepositAmount, 0)) AS SumDeposit
    FROM tblBookingDetails
    GROUP BY BookingID
) D ON B.BookingID = D.BookingID
WHERE (B.DepositAmount IS NULL OR B.DepositAmount = 0)
  AND D.SumDeposit > 0;
GO

-- 2) Today return report — deposit from header OR line item
CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        BD.ProductName,
        B.ReturnDate,
        CAST(ISNULL(NULLIF(B.DepositAmount, 0), BD.DepositAmount) AS DECIMAL(18,2)) AS DepositAmount,
        ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
        B.ExtraDays,
        B.ExtraChargeAmount,
        ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
        B.FinalRefundAmount,
        B.FinalProfitAmount,
        B.BookingStatus,
        B.ActualReturnDate
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted = 0
      AND CAST(B.ReturnDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
    ORDER BY B.BookingNo;
END
GO

-- 3) Booking list includes deposit
CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, @Search VARCHAR(100) = NULL, @Status VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount,
           CAST(ISNULL(B.DepositAmount, 0) AS DECIMAL(18,2)) AS DepositAmount,
           ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@Status IS NULL OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
    ORDER BY B.BookingID DESC;
END
GO

-- 4) On new booking: sync deposit from items if header was 0
CREATE OR ALTER PROCEDURE SP_AddBooking
    @CompanyID INT, @BookingNo VARCHAR(50), @CustomerID INT, @BookingCreatedBy INT,
    @BookingDate DATE, @StartDate DATE, @EndDate DATE, @DeliveryDate DATE, @ReturnDate DATE,
    @RentDays INT, @TotalRentAmount DECIMAL(18,2), @DiscountAmount DECIMAL(18,2),
    @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2), @RemainingAmount DECIMAL(18,2),
    @TotalAmount DECIMAL(18,2), @ExtraChargePerDay DECIMAL(18,2), @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX), @BookingDetailsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO tblBookings(CompanyID,BookingNo,CustomerID,BookingCreatedBy,BookingDate,StartDate,EndDate,
            DeliveryDate,ReturnDate,RentDays,TotalRentAmount,DiscountAmount,DepositAmount,AdvanceAmount,
            RemainingAmount,TotalAmount,ExtraChargePerDay,BookingStatus,PaymentStatus,Notes)
        VALUES(@CompanyID,@BookingNo,@CustomerID,@BookingCreatedBy,@BookingDate,@StartDate,@EndDate,
            @DeliveryDate,@ReturnDate,@RentDays,@TotalRentAmount,@DiscountAmount,@DepositAmount,@AdvanceAmount,
            @RemainingAmount,@TotalAmount,@ExtraChargePerDay,@BookingStatus,@PaymentStatus,@Notes);

        DECLARE @BookingID INT = SCOPE_IDENTITY();

        INSERT INTO tblBookingDetails(BookingID,ProductID,ProductCode,ProductName,Size,Color,RentAmount,DepositAmount,DiscountPercent,FinalRentAmount)
        SELECT @BookingID,
            COALESCE(j.ProductID, j.productID),
            COALESCE(j.ProductCode, j.productCode),
            COALESCE(j.ProductName, j.productName),
            COALESCE(j.Size, j.size),
            COALESCE(j.Color, j.color),
            COALESCE(j.RentAmount, j.rentAmount),
            COALESCE(j.DepositAmount, j.depositAmount, 0),
            COALESCE(j.DiscountPercent, j.discountPercent, 0),
            COALESCE(j.FinalRentAmount, j.finalRentAmount)
        FROM OPENJSON(@BookingDetailsJson) WITH (
            ProductID INT '$.ProductID', productID INT '$.productID',
            ProductCode VARCHAR(50) '$.ProductCode', productCode VARCHAR(50) '$.productCode',
            ProductName VARCHAR(200) '$.ProductName', productName VARCHAR(200) '$.productName',
            Size VARCHAR(50) '$.Size', size VARCHAR(50) '$.size',
            Color VARCHAR(50) '$.Color', color VARCHAR(50) '$.color',
            RentAmount DECIMAL(18,2) '$.RentAmount', rentAmount DECIMAL(18,2) '$.rentAmount',
            DepositAmount DECIMAL(18,2) '$.DepositAmount', depositAmount DECIMAL(18,2) '$.depositAmount',
            DiscountPercent DECIMAL(18,2) '$.DiscountPercent', discountPercent DECIMAL(18,2) '$.discountPercent',
            FinalRentAmount DECIMAL(18,2) '$.FinalRentAmount', finalRentAmount DECIMAL(18,2) '$.finalRentAmount'
        ) j;

        IF ISNULL(@DepositAmount, 0) = 0
        BEGIN
            UPDATE tblBookings
            SET DepositAmount = (
                SELECT SUM(ISNULL(DepositAmount, 0)) FROM tblBookingDetails WHERE BookingID = @BookingID
            )
            WHERE BookingID = @BookingID;
        END

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
END
GO
