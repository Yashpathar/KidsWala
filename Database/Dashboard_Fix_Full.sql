-- Comprehensive Stored Procedures Fix for Dashboard & Bookings
-- Fixes SP_GetAllBookings argument mismatch and updates Dashboard & Report SPs.

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. SP_GetAllBookings
CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, 
    @BranchID INT = NULL,
    @Search VARCHAR(100) = NULL, 
    @Status VARCHAR(50) = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;

    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount,
           CAST(ISNULL(B.DepositAmount, 0) AS DECIMAL(18,2)) AS DepositAmount,
           ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID, B.BranchID
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
      AND (@Status IS NULL OR @Status = '' OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR @Search = '' OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
      AND (@FromDate IS NULL OR CAST(B.BookingDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.BookingDate AS DATE) <= @ToDate)
    ORDER BY B.BookingID DESC;
END
GO

-- 2. SP_DashboardCounts
CREATE OR ALTER PROCEDURE SP_DashboardCounts
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    SELECT
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TotalBookings,

        (SELECT COUNT(*) FROM tblCompany WHERE IsDeleted=0) AS TotalCompanies,

        (SELECT COUNT(*) FROM tblBranch WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)) AS TotalBranches,

        (SELECT COUNT(*) FROM tblUsers WHERE IsDeleted=0 AND IsActive=1
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)) AS TotalUsers,

        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND CAST(DeliveryDate AS DATE)=@Today
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayDeliveries,

        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND CAST(ReturnDate AS DATE)=@Today
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayReturns,

        (SELECT ISNULL(SUM(RemainingAmount),0) FROM tblBookings WHERE IsDeleted=0 AND PaymentStatus IN ('Pending','Partial')
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS PendingPayments,

        (SELECT ISNULL(SUM(DepositAmount),0) FROM tblBookings WHERE IsDeleted=0 AND BookingStatus='Delivered'
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS PendingDeposit,

        (SELECT ISNULL(SUM(FinalRefundAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS RefundDepositAmount,

        (SELECT COUNT(*) FROM tblProducts WHERE IsDeleted=0 AND IsAvailable=1
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)) AS AvailableProducts,

        (SELECT COUNT(*) FROM tblBookings WHERE CAST(ReturnDate AS DATE) < @Today AND BookingStatus IN ('Delivered', 'Booked') AND IsDeleted=0
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS OverdueProducts,

        (SELECT ISNULL(SUM(P.PaymentAmount),0) FROM tblPayments P INNER JOIN tblBookings B ON P.BookingID=B.BookingID
            WHERE P.PaymentType NOT IN ('Deposit Refund')
            AND (@CompanyID IS NULL OR @CompanyID=0 OR P.CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR B.BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR B.BookingCreatedBy=@FilterUserID)) AS TotalIncome,

        (SELECT ISNULL(SUM(P.PaymentAmount),0) FROM tblPayments P INNER JOIN tblBookings B ON P.BookingID=B.BookingID
            WHERE P.PaymentType='Deposit Refund'
            AND (@CompanyID IS NULL OR @CompanyID=0 OR P.CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR B.BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR B.BookingCreatedBy=@FilterUserID)) AS TotalExpenses,

        (SELECT ISNULL(SUM(DamageDeductionAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TotalDamageCuts;
END
GO

-- 3. SP_TopProducts
CREATE OR ALTER PROCEDURE SP_TopProducts
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @TopN INT = 5,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@TopN) BD.ProductName, COUNT(*) AS Total
    FROM tblBookingDetails BD
    INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    GROUP BY BD.ProductName
    ORDER BY COUNT(*) DESC;
END
GO

-- 4. SP_MonthlyIncome
CREATE OR ALTER PROCEDURE SP_MonthlyIncome
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FORMAT(P.PaymentDate, 'MMM yyyy') AS MonthLabel, SUM(P.PaymentAmount) AS Income
    FROM tblPayments P
    INNER JOIN tblBookings B ON P.BookingID = B.BookingID
    WHERE P.PaymentType NOT IN ('Deposit Refund')
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    GROUP BY FORMAT(P.PaymentDate, 'MMM yyyy'), YEAR(P.PaymentDate), MONTH(P.PaymentDate)
    ORDER BY YEAR(P.PaymentDate), MONTH(P.PaymentDate);
END
GO

-- 5. SP_BookingStatusChart
CREATE OR ALTER PROCEDURE SP_BookingStatusChart
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT BookingStatus AS StatusName, COUNT(*) AS Total
    FROM tblBookings
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR BookingCreatedBy = @FilterUserID)
    GROUP BY BookingStatus;
END
GO

-- 6. SP_TodayDeliveryReport
CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;
    
    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        STUFF((
            SELECT ', ' + BD.ProductName
            FROM tblBookingDetails BD
            WHERE BD.BookingID = B.BookingID
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductName,
        B.DeliveryDate,
        B.BookingStatus AS DeliveryStatus,
        B.PaymentStatus,
        ISNULL(B.RemainingAmount, 0) AS PendingAmount,
        B.TotalAmount,
        B.AdvanceAmount,
        B.DepositAmount,
        B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@FromDate IS NULL OR CAST(B.DeliveryDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.DeliveryDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.DeliveryDate DESC, B.BookingNo;
END
GO

-- 7. SP_TodayReturnReport
CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;

    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        STUFF((
            SELECT ', ' + BD.ProductName
            FROM tblBookingDetails BD
            WHERE BD.BookingID = B.BookingID
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductName,
        B.ReturnDate,
        CAST(ISNULL(NULLIF(B.DepositAmount, 0), (SELECT SUM(ISNULL(BD.DepositAmount,0)) FROM tblBookingDetails BD WHERE BD.BookingID = B.BookingID)) AS DECIMAL(18,2)) AS DepositAmount,
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
    WHERE B.IsDeleted = 0
      AND (@FromDate IS NULL OR CAST(B.ReturnDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.ReturnDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.ReturnDate DESC, B.BookingNo;
END
GO

-- 8. SP_PaymentReport
CREATE OR ALTER PROCEDURE SP_PaymentReport 
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL, 
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;

    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT P.PaymentID, B.BookingNo, P.PaymentType, P.PaymentMode, P.PaymentAmount,
           P.PaymentDate, P.TransactionNo
    FROM tblPayments P
    INNER JOIN tblBookings B ON P.BookingID = B.BookingID
    WHERE (@FromDate IS NULL OR CAST(P.PaymentDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(P.PaymentDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY P.PaymentDate DESC;
END
GO
