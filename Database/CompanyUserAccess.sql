-- Company-wise users, data scope, login & filtered reports
-- Run after Login_RoleRights_Enhancement.sql

USE DB_A6B32D_LabelManagement;
GO

IF COL_LENGTH('tblRole', 'DataScope') IS NULL
    ALTER TABLE tblRole ADD DataScope VARCHAR(30) NOT NULL DEFAULT 'CompanyAll';
GO

UPDATE tblRole SET DataScope = 'Platform' WHERE RoleName = 'Super Admin';
UPDATE tblRole SET DataScope = 'CompanyAll' WHERE RoleName = 'Admin';
UPDATE tblRole SET DataScope = 'OwnBookingsOnly' WHERE RoleName IN ('Accountant', 'Staff');
IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleName = 'Staff' AND IsDeleted = 0)
    INSERT INTO tblRole(RoleName, Description, DataScope) VALUES ('Staff', 'Own bookings only', 'OwnBookingsOnly');
GO

/* Users: Super Admin (no company) + per-company staff */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'nikol_admin')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES (2, 1, 'Nikol Admin', 'nikol_admin', 'nikol.admin@kidswalla.com', '9999991101', '');
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant1')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES ((SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'OwnBookingsOnly'), 1, 'Accountant 1', 'accountant1', 'acc1@kidswalla.com', '9999991102', '');
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant2')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES ((SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'OwnBookingsOnly'), 1, 'Accountant 2', 'accountant2', 'acc2@kidswalla.com', '9999991103', '');
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'chand_admin')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES (2, 2, 'Chandlodiya Admin', 'chand_admin', 'chand.admin@kidswalla.com', '9999992201', '');
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'yash')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES ((SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'OwnBookingsOnly'), 2, 'Yash', 'yash', 'yash@kidswalla.com', '9999992202', '');
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'sagar')
    INSERT INTO tblUsers(RoleID, CompanyID, FullName, UserName, Email, MobileNo, PasswordHash)
    VALUES ((SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'OwnBookingsOnly'), 2, 'Sagar', 'sagar', 'sagar@kidswalla.com', '9999992203', '');
GO

UPDATE tblUsers SET CompanyID = NULL, RoleID = 1 WHERE UserName = 'admin';
GO

CREATE OR ALTER PROCEDURE SP_UserLogin
    @UserName VARCHAR(100),
    @Password VARCHAR(200) = NULL,
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.RoleID, U.CompanyID, U.FullName, U.UserName, U.Email, U.MobileNo, U.PasswordHash,
           R.RoleName, R.DataScope, C.CompanyName
    FROM tblUsers U
    INNER JOIN tblRole R ON U.RoleID = R.RoleID AND R.IsDeleted = 0
    LEFT JOIN tblCompany C ON C.CompanyID = @CompanyID
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0
      AND (
            @CompanyID IS NULL
            OR R.DataScope = 'Platform'
            OR U.CompanyID = @CompanyID
          );
END
GO

CREATE OR ALTER PROCEDURE SP_GetCompaniesForLogin
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, IsActive
    FROM tblCompany WHERE IsDeleted = 0 AND IsActive = 1 ORDER BY CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL,
    @Search VARCHAR(100) = NULL,
    @Status VARCHAR(50) = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount, B.DepositAmount, B.ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, B.DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID, B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
      AND (@Status IS NULL OR @Status = '' OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR @Search = '' OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
    ORDER BY B.BookingID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_DashboardCounts
    @CompanyID INT = NULL,
    @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    SELECT
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TotalBookings,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND DeliveryDate=@Today
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayDeliveries,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND ReturnDate=@Today
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayReturns,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0
            AND PaymentStatus IN ('Pending','Partial')
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS PendingPayments,
        (SELECT ISNULL(SUM(DepositAmount),0) FROM tblBookings WHERE IsDeleted=0 AND BookingStatus='Delivered'
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS PendingDeposit,
        (SELECT ISNULL(SUM(FinalRefundAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS RefundDepositAmount,
        (SELECT COUNT(*) FROM tblProducts WHERE IsDeleted=0 AND IsAvailable=1
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS AvailableProducts,
        (SELECT COUNT(*) FROM tblBookings WHERE ReturnDate < @Today AND IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS OverdueProducts,
        (SELECT ISNULL(SUM(P.PaymentAmount),0) FROM tblPayments P
            INNER JOIN tblBookings B ON P.BookingID = B.BookingID
            WHERE P.PaymentType NOT IN ('Deposit Refund')
            AND (@CompanyID IS NULL OR P.CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR B.BookingCreatedBy=@FilterUserID)) AS TotalIncome,
        (SELECT ISNULL(SUM(P.PaymentAmount),0) FROM tblPayments P
            INNER JOIN tblBookings B ON P.BookingID = B.BookingID
            WHERE P.PaymentType='Deposit Refund'
            AND (@CompanyID IS NULL OR P.CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR B.BookingCreatedBy=@FilterUserID)) AS TotalExpenses,
        (SELECT ISNULL(SUM(DamageDeductionAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TotalDamageCuts;
END
GO

CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport
    @CompanyID INT = NULL, @ReportDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.DeliveryDate, B.BookingStatus,
           B.TotalAmount, B.AdvanceAmount, B.RemainingAmount, B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0 AND CAST(B.DeliveryDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.BookingNo;
END
GO

CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, @ReportDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName,
           P.ProductName, B.ReturnDate, B.DepositAmount, B.ExtraChargePerDay,
           B.ExtraDays, B.ExtraChargeAmount, B.DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.BookingStatus, B.ActualReturnDate, B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    OUTER APPLY (SELECT TOP 1 ProductName FROM tblBookingDetails BD WHERE BD.BookingID = B.BookingID) P
    WHERE B.IsDeleted = 0 AND CAST(B.ReturnDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.BookingNo;
END
GO

CREATE OR ALTER PROCEDURE SP_TopProducts
    @CompanyID INT = NULL, @TopN INT = 5, @FilterUserID INT = NULL
AS
BEGIN
    SELECT TOP (@TopN) BD.ProductName, COUNT(*) AS RentCount
    FROM tblBookingDetails BD
    INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    GROUP BY BD.ProductName
    ORDER BY COUNT(*) DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_MonthlyIncome
    @CompanyID INT = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SELECT FORMAT(P.PaymentDate, 'MMM yyyy') AS MonthLabel, SUM(P.PaymentAmount) AS Income
    FROM tblPayments P
    INNER JOIN tblBookings B ON P.BookingID = B.BookingID
    WHERE P.PaymentType NOT IN ('Deposit Refund')
      AND (@CompanyID IS NULL OR P.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    GROUP BY FORMAT(P.PaymentDate, 'MMM yyyy'), YEAR(P.PaymentDate), MONTH(P.PaymentDate)
    ORDER BY YEAR(P.PaymentDate), MONTH(P.PaymentDate);
END
GO

CREATE OR ALTER PROCEDURE SP_BookingStatusChart
    @CompanyID INT = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SELECT BookingStatus AS StatusName, COUNT(*) AS Total
    FROM tblBookings
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR BookingCreatedBy = @FilterUserID)
    GROUP BY BookingStatus;
END
GO

CREATE OR ALTER PROCEDURE SP_PaymentReport
    @CompanyID INT = NULL, @FromDate DATE = NULL, @ToDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET @FromDate = ISNULL(@FromDate, DATEADD(MONTH, -1, GETDATE()));
    SET @ToDate = ISNULL(@ToDate, GETDATE());
    SELECT P.PaymentID, B.BookingNo, P.PaymentType, P.PaymentMode, P.PaymentAmount,
           P.PaymentDate, P.TransactionNo
    FROM tblPayments P
    INNER JOIN tblBookings B ON P.BookingID = B.BookingID
    WHERE CAST(P.PaymentDate AS DATE) BETWEEN @FromDate AND @ToDate
      AND (@CompanyID IS NULL OR P.CompanyID = @CompanyID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY P.PaymentDate DESC;
END
GO
