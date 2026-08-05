-- Run after CompanyBranch_Structure.sql
USE DB_A6B32D_LabelManagement;
GO

CREATE OR ALTER PROCEDURE SP_AddBooking
    @CompanyID INT, @BranchID INT = NULL, @BookingNo VARCHAR(50), @CustomerID INT, @BookingCreatedBy INT,
    @BookingDate DATE, @StartDate DATE, @EndDate DATE, @DeliveryDate DATE, @ReturnDate DATE,
    @RentDays INT, @TotalRentAmount DECIMAL(18,2), @DiscountAmount DECIMAL(18,2),
    @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2), @RemainingAmount DECIMAL(18,2),
    @TotalAmount DECIMAL(18,2), @ExtraChargePerDay DECIMAL(18,2),
    @ExtraDays INT = 0, @ExtraChargeAmount DECIMAL(18,2) = 0,
    @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX), @BookingDetailsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        INSERT INTO tblBookings(CompanyID, BranchID, BookingNo, CustomerID, BookingCreatedBy, BookingDate, StartDate, EndDate,
            DeliveryDate, ReturnDate, RentDays, TotalRentAmount, DiscountAmount, DepositAmount, AdvanceAmount,
            RemainingAmount, TotalAmount, ExtraChargePerDay, ExtraDays, ExtraChargeAmount, BookingStatus, PaymentStatus, Notes)
        VALUES(@CompanyID, @BranchID, @BookingNo, @CustomerID, @BookingCreatedBy, @BookingDate, @StartDate, @EndDate,
            @DeliveryDate, @ReturnDate, @RentDays, @TotalRentAmount, @DiscountAmount, @DepositAmount, @AdvanceAmount,
            @RemainingAmount, @TotalAmount, @ExtraChargePerDay, @ExtraDays, @ExtraChargeAmount, @BookingStatus, @PaymentStatus, @Notes);
        DECLARE @BookingID INT = SCOPE_IDENTITY();
        INSERT INTO tblBookingDetails(BookingID,ProductID,ProductCode,ProductName,Size,Color,RentAmount,DepositAmount,DiscountPercent,FinalRentAmount)
        SELECT @BookingID, COALESCE(j.ProductID, j.productID), COALESCE(j.ProductCode, j.productCode),
            COALESCE(j.ProductName, j.productName), COALESCE(j.Size, j.size), COALESCE(j.Color, j.color),
            COALESCE(j.RentAmount, j.rentAmount), COALESCE(j.DepositAmount, j.depositAmount, 0),
            COALESCE(j.DiscountPercent, j.discountPercent, 0), COALESCE(j.FinalRentAmount, j.finalRentAmount)
        FROM OPENJSON(@BookingDetailsJson) WITH (
            ProductID INT, ProductCode VARCHAR(50), ProductName VARCHAR(200), Size VARCHAR(50), Color VARCHAR(50),
            RentAmount DECIMAL(18,2), DepositAmount DECIMAL(18,2), DiscountPercent DECIMAL(18,2), FinalRentAmount DECIMAL(18,2)
        ) j;
        COMMIT TRANSACTION;
        SELECT 1 AS Success, 'Booking created' AS Message, @BookingID AS ID, @BookingNo AS BookingNo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT>0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID, '' AS BookingNo;
    END CATCH
END
GO
