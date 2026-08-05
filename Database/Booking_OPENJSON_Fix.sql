/* Run if booking save fails with OPENJSON / product detail errors.
   API must send PascalCase JSON keys (ProductID, ProductCode, ...) — fixed in BookingRepository. */
USE DB_A6B32D_LabelManagement;
GO

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
            COALESCE(j.DepositAmount, j.depositAmount),
            COALESCE(j.DiscountPercent, j.discountPercent),
            COALESCE(j.FinalRentAmount, j.finalRentAmount)
        FROM OPENJSON(@BookingDetailsJson)
        WITH (
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
