-- Run on DB_A6B32D_LabelManagement (or your rental DB)
-- Early return, late extra charge, damage deduction from deposit

IF COL_LENGTH('tblBookings', 'DamageDeductionAmount') IS NULL
    ALTER TABLE tblBookings ADD DamageDeductionAmount DECIMAL(18,2) NOT NULL DEFAULT 0;
GO

CREATE OR ALTER PROCEDURE SP_ProcessReturn
    @BookingID INT,
    @ActualReturnDate DATE,
    @DamageDeductionAmount DECIMAL(18,2) = 0,
    @ReturnNotes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @ReturnDate DATE, @ExtraChargePerDay DECIMAL(18,2),
                @TotalRent DECIMAL(18,2), @Deposit DECIMAL(18,2),
                @ExtraDays INT = 0, @LateCharge DECIMAL(18,2) = 0,
                @Damage DECIMAL(18,2) = 0, @Refund DECIMAL(18,2), @Profit DECIMAL(18,2),
                @Status VARCHAR(50), @BookingStatus VARCHAR(50);

        SELECT @ReturnDate = ReturnDate,
               @ExtraChargePerDay = ISNULL(ExtraChargePerDay, 0),
               @TotalRent = TotalRentAmount,
               @Deposit = DepositAmount,
               @BookingStatus = BookingStatus
        FROM tblBookings
        WHERE BookingID = @BookingID AND IsDeleted = 0;

        IF @BookingStatus IS NULL
        BEGIN
            SELECT 0 AS Success, 'Booking not found' AS Message;
            ROLLBACK;
            RETURN;
        END

        IF @BookingStatus <> 'Delivered'
        BEGIN
            SELECT 0 AS Success, 'Only delivered bookings can be returned' AS Message;
            ROLLBACK;
            RETURN;
        END

        SET @Damage = CASE WHEN @DamageDeductionAmount < 0 THEN 0
                           WHEN @DamageDeductionAmount > @Deposit THEN @Deposit
                           ELSE @DamageDeductionAmount END;

        -- Late return: charge extra days after scheduled return date
        IF @ActualReturnDate > @ReturnDate
        BEGIN
            SET @ExtraDays = DATEDIFF(DAY, @ReturnDate, @ActualReturnDate);
            SET @LateCharge = @ExtraDays * @ExtraChargePerDay;
            SET @TotalRent = @TotalRent + @LateCharge;
            SET @Status = 'Late Returned';
        END
        ELSE
            SET @Status = 'Returned'; -- includes early return (before scheduled date)

        SET @Refund = @Deposit - @LateCharge - @Damage;
        IF @Refund < 0 SET @Refund = 0;
        SET @Profit = @TotalRent;

        UPDATE tblBookings SET
            ActualReturnDate = @ActualReturnDate,
            ExtraDays = @ExtraDays,
            ExtraChargeAmount = @LateCharge,
            DamageDeductionAmount = @Damage,
            TotalRentAmount = @TotalRent,
            FinalRefundAmount = @Refund,
            FinalProfitAmount = @Profit,
            BookingStatus = @Status,
            PaymentStatus = 'Completed',
            Notes = CASE
                WHEN @ReturnNotes IS NOT NULL AND LTRIM(RTRIM(@ReturnNotes)) <> ''
                THEN ISNULL(Notes + CHAR(10), '') + @ReturnNotes
                ELSE Notes
            END
        WHERE BookingID = @BookingID;

        UPDATE P SET IsAvailable = 1, CurrentBookingID = NULL, NextAvailableDate = GETDATE()
        FROM tblProducts P
        INNER JOIN tblBookingDetails BD ON P.ProductID = BD.ProductID
        WHERE BD.BookingID = @BookingID;

        COMMIT;
        SELECT 1 AS Success, 'Return Processed' AS Message,
               @ExtraDays AS ExtraDays,
               @LateCharge AS ExtraChargeAmount,
               @Damage AS DamageDeductionAmount,
               @Refund AS FinalRefundAmount,
               @Profit AS FinalProfitAmount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, @Search VARCHAR(100) = NULL, @Status VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount, B.DepositAmount, B.ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, B.DamageDeductionAmount,
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

CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, BD.ProductName,
           B.ReturnDate, B.DepositAmount, B.ExtraChargePerDay,
           B.ExtraDays, B.ExtraChargeAmount, B.DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.BookingStatus, B.ActualReturnDate
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted = 0
      AND CAST(B.ReturnDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
    ORDER BY B.BookingNo;
END
GO
