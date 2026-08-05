-- Company + Branch hierarchy, login contexts, data isolation
-- Run after CompanyUserAccess.sql on DB_A6B32D_LabelManagement

USE DB_A6B32D_LabelManagement;
GO

/* ========== BRANCH TABLE ========== */
IF OBJECT_ID('tblBranch', 'U') IS NULL
BEGIN
    CREATE TABLE tblBranch (
        BranchID INT IDENTITY(1,1) PRIMARY KEY,
        CompanyID INT NOT NULL,
        BranchName VARCHAR(200) NOT NULL,
        BranchCode VARCHAR(50) NULL,
        Address NVARCHAR(500) NULL,
        MobileNo VARCHAR(20) NULL,
        Email VARCHAR(200) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        IsDeleted BIT NOT NULL DEFAULT 0,
        FOREIGN KEY (CompanyID) REFERENCES tblCompany(CompanyID)
    );
END
GO

/* ========== ADD BranchID COLUMNS ========== */
IF COL_LENGTH('tblUsers', 'BranchID') IS NULL ALTER TABLE tblUsers ADD BranchID INT NULL;
IF COL_LENGTH('tblBookings', 'BranchID') IS NULL ALTER TABLE tblBookings ADD BranchID INT NULL;
IF COL_LENGTH('tblCustomers', 'BranchID') IS NULL ALTER TABLE tblCustomers ADD BranchID INT NULL;
IF COL_LENGTH('tblProducts', 'BranchID') IS NULL ALTER TABLE tblProducts ADD BranchID INT NULL;
IF COL_LENGTH('tblPayments', 'BranchID') IS NULL ALTER TABLE tblPayments ADD BranchID INT NULL;
IF COL_LENGTH('tblNotifications', 'BranchID') IS NULL ALTER TABLE tblNotifications ADD BranchID INT NULL;
GO

/* ========== LOGIN HISTORY ========== */
IF OBJECT_ID('tblLoginHistory', 'U') IS NULL
BEGIN
    CREATE TABLE tblLoginHistory (
        LoginHistoryID INT IDENTITY(1,1) PRIMARY KEY,
        UserID INT NOT NULL,
        CompanyID INT NULL,
        BranchID INT NULL,
        RoleID INT NULL,
        LoginTime DATETIME NOT NULL DEFAULT GETDATE(),
        IPAddress VARCHAR(50) NULL,
        UserAgent NVARCHAR(500) NULL
    );
END
GO

/* ========== ROLES ========== */
UPDATE tblRole SET DataScope = 'Platform' WHERE RoleName = 'Super Admin';
UPDATE tblRole SET DataScope = 'CompanyAll' WHERE RoleName IN ('Admin', 'Company Admin');
UPDATE tblRole SET DataScope = 'BranchOwnOnly' WHERE RoleName IN ('Staff', 'Accountant')
    OR DataScope IN ('OwnBookingsOnly', 'BranchOwnOnly');
IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleName = 'Company Admin' AND IsDeleted = 0)
    INSERT INTO tblRole(RoleName, Description, DataScope) VALUES ('Company Admin', 'All branches in company', 'CompanyAll');
GO

/* ========== MIGRATE: old "company" rows -> parent company + branches ========== */
IF EXISTS (SELECT 1 FROM tblCompany WHERE CompanyCode IN ('KWN', 'KWC') AND IsDeleted = 0)
   AND NOT EXISTS (SELECT 1 FROM tblCompany WHERE CompanyCode = 'KW' AND IsDeleted = 0)
BEGIN
    DECLARE @Map TABLE (OldCompanyID INT, BranchName VARCHAR(200), BranchCode VARCHAR(50), Address NVARCHAR(500), Mobile VARCHAR(20), Email VARCHAR(200), GST VARCHAR(100));
    INSERT INTO @Map SELECT CompanyID, CompanyName, CompanyCode, Address, MobileNo, Email, GSTNo FROM tblCompany WHERE CompanyCode IN ('KWN', 'KWC');

    INSERT INTO tblCompany(CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo)
    VALUES ('Kids Walla', 'KW', 'Children Wear', 'Ahmedabad', '9999990000', 'info@kidswalla.com', 'GSTKW001');
    DECLARE @KidsWallaID INT = SCOPE_IDENTITY();

    INSERT INTO tblBranch(CompanyID, BranchName, BranchCode, Address, MobileNo, Email)
    SELECT @KidsWallaID, BranchName, BranchCode, Address, Mobile, Email FROM @Map;

  UPDATE B SET CompanyID = @KidsWallaID, BranchID = BR.BranchID
    FROM tblBookings B
    INNER JOIN @Map M ON B.CompanyID = M.OldCompanyID
    INNER JOIN tblBranch BR ON BR.CompanyID = @KidsWallaID AND BR.BranchCode = M.BranchCode;

    UPDATE C SET CompanyID = @KidsWallaID, BranchID = BR.BranchID
    FROM tblCustomers C
    INNER JOIN @Map M ON C.CompanyID = M.OldCompanyID
    INNER JOIN tblBranch BR ON BR.CompanyID = @KidsWallaID AND BR.BranchCode = M.BranchCode;

    UPDATE P SET CompanyID = @KidsWallaID, BranchID = BR.BranchID
    FROM tblProducts P
    INNER JOIN @Map M ON P.CompanyID = M.OldCompanyID
    INNER JOIN tblBranch BR ON BR.CompanyID = @KidsWallaID AND BR.BranchCode = M.BranchCode;

    UPDATE Pay SET CompanyID = @KidsWallaID, BranchID = BR.BranchID
    FROM tblPayments Pay
    INNER JOIN @Map M ON Pay.CompanyID = M.OldCompanyID
    INNER JOIN tblBranch BR ON BR.CompanyID = @KidsWallaID AND BR.BranchCode = M.BranchCode;

    UPDATE U SET CompanyID = @KidsWallaID, BranchID = BR.BranchID
    FROM tblUsers U
    INNER JOIN @Map M ON U.CompanyID = M.OldCompanyID
    INNER JOIN tblBranch BR ON BR.CompanyID = @KidsWallaID AND BR.BranchCode = M.BranchCode
    WHERE U.UserName NOT IN ('admin', 'nikol_admin', 'chand_admin');

    UPDATE tblUsers SET CompanyID = @KidsWallaID, BranchID = NULL, RoleID = (SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'CompanyAll')
    WHERE UserName = 'nikol_admin';

    UPDATE tblCompany SET IsDeleted = 1 WHERE CompanyID IN (SELECT OldCompanyID FROM @Map);
END
GO

/* Tulsi Rental House */
IF NOT EXISTS (SELECT 1 FROM tblCompany WHERE CompanyCode = 'TRH' AND IsDeleted = 0)
BEGIN
    INSERT INTO tblCompany(CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo)
    VALUES ('Tulsi Rental House', 'TRH', 'Rental', 'Gujarat', '9999993300', 'info@tulsirental.com', 'GSTTRH001');
    DECLARE @TulsiID INT = SCOPE_IDENTITY();
    INSERT INTO tblBranch(CompanyID, BranchName, BranchCode, Address, MobileNo, Email) VALUES
    (@TulsiID, 'Tulsi Rental House Amreli', 'TRH-AMR', 'Amreli', '9999993301', 'amreli@tulsirental.com'),
    (@TulsiID, 'Tulsi Rental House Surat', 'TRH-SRT', 'Surat', '9999993302', 'surat@tulsirental.com');
END
GO

/* USERS (password: 123456) */
UPDATE tblUsers SET CompanyID = NULL, BranchID = NULL, RoleID = 1 WHERE UserName = 'admin';

DECLARE @KW INT = (SELECT TOP 1 CompanyID FROM tblCompany WHERE CompanyCode = 'KW' AND IsDeleted = 0);
DECLARE @BN INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'KWN' AND IsDeleted = 0);
DECLARE @BC INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'KWC' AND IsDeleted = 0);
DECLARE @TRH INT = (SELECT TOP 1 CompanyID FROM tblCompany WHERE CompanyCode = 'TRH' AND IsDeleted = 0);
DECLARE @BA INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'TRH-AMR' AND IsDeleted = 0);
DECLARE @BS INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'TRH-SRT' AND IsDeleted = 0);
DECLARE @RCompany INT = (SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'CompanyAll');
DECLARE @RBranch INT = (SELECT TOP 1 RoleID FROM tblRole WHERE DataScope = 'BranchOwnOnly');

IF @KW IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'kidswalla_admin')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash)
        VALUES (@RCompany, @KW, NULL, 'Kids Walla Admin', 'kidswalla_admin', 'admin@kidswalla.com', '9999991100', '');
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant1')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash)
        VALUES (@RBranch, @KW, @BN, 'Accountant 1', 'accountant1', 'acc1@kidswalla.com', '9999991102', '');
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant2')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash)
        VALUES (@RBranch, @KW, @BN, 'Accountant 2', 'accountant2', 'acc2@kidswalla.com', '9999991103', '');
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'yash')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash)
        VALUES (@RBranch, @KW, @BC, 'Yash', 'yash', 'yash@kidswalla.com', '9999992202', '');
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'sagar')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash)
        VALUES (@RBranch, @KW, @BC, 'Sagar', 'sagar', 'sagar@kidswalla.com', '9999992203', '');
END
GO

CREATE OR ALTER PROCEDURE SP_UserLoginByName @UserName VARCHAR(100), @Password VARCHAR(200) = NULL
AS
BEGIN
    SELECT U.UserID, U.RoleID, U.CompanyID, U.BranchID, U.FullName, U.UserName, U.Email, U.MobileNo, U.PasswordHash,
           R.RoleName, R.DataScope, C.CompanyName, B.BranchName
    FROM tblUsers U
    INNER JOIN tblRole R ON U.RoleID = R.RoleID AND R.IsDeleted = 0
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    LEFT JOIN tblBranch B ON U.BranchID = B.BranchID
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetLoginContexts @UserName VARCHAR(100)
AS
BEGIN
    DECLARE @Scope VARCHAR(30), @UserID INT, @CompanyID INT, @BranchID INT, @RoleID INT;
    DECLARE @FullName VARCHAR(200), @RoleName VARCHAR(100);

    SELECT @UserID = U.UserID, @CompanyID = U.CompanyID, @BranchID = U.BranchID, @RoleID = U.RoleID,
           @Scope = R.DataScope, @FullName = U.FullName, @RoleName = R.RoleName
    FROM tblUsers U INNER JOIN tblRole R ON U.RoleID = R.RoleID
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0;

    IF @UserID IS NULL RETURN;

    IF @Scope = 'Platform'
    BEGIN
        SELECT @UserID AS UserID, @FullName AS FullName, @UserName AS UserName, @RoleID AS RoleID, @RoleName AS RoleName, @Scope AS DataScope,
               C.CompanyID, C.CompanyName, B.BranchID, B.BranchName,
               CAST(C.CompanyName + ' / ' + B.BranchName AS VARCHAR(300)) AS ContextLabel
        FROM tblCompany C
        CROSS JOIN tblBranch B
        WHERE C.IsDeleted = 0 AND C.IsActive = 1 AND B.IsDeleted = 0 AND B.IsActive = 1 AND B.CompanyID = C.CompanyID
        UNION ALL
        SELECT @UserID, @FullName, @UserName, @RoleID, @RoleName, @Scope, 0, 'All Companies', 0, 'All Branches', 'Super Admin (Full Access)';
        RETURN;
    END

    IF @Scope = 'CompanyAll'
    BEGIN
        SELECT @UserID AS UserID, @FullName AS FullName, @UserName AS UserName, @RoleID AS RoleID, @RoleName AS RoleName, @Scope AS DataScope,
               @CompanyID AS CompanyID, C.CompanyName, 0 AS BranchID, 'All Branches' AS BranchName,
               C.CompanyName + ' (Company Admin)' AS ContextLabel
        FROM tblCompany C WHERE C.CompanyID = @CompanyID;
        RETURN;
    END

    SELECT @UserID AS UserID, @FullName AS FullName, @UserName AS UserName, @RoleID AS RoleID, @RoleName AS RoleName, @Scope AS DataScope,
           @CompanyID AS CompanyID, C.CompanyName, @BranchID AS BranchID, B.BranchName,
           B.BranchName + ' (' + @RoleName + ')' AS ContextLabel
    FROM tblCompany C
    LEFT JOIN tblBranch B ON B.BranchID = @BranchID
    WHERE C.CompanyID = @CompanyID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCompaniesForLogin
AS
BEGIN
    SELECT C.CompanyID, C.CompanyName, C.CompanyCode, C.BusinessType
    FROM tblCompany C WHERE C.IsDeleted = 0 AND C.IsActive = 1 ORDER BY C.CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllCompanies
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, IsActive
    FROM tblCompany WHERE IsDeleted = 0 ORDER BY CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetBranchesByCompany @CompanyID INT
AS
BEGIN
    SELECT BranchID, CompanyID, BranchName, BranchCode, Address, MobileNo, Email, IsActive
    FROM tblBranch WHERE CompanyID = @CompanyID AND IsDeleted = 0 ORDER BY BranchName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllBranches
AS
BEGIN
    SELECT B.BranchID, B.CompanyID, C.CompanyName, B.BranchName, B.BranchCode, B.Address, B.MobileNo, B.Email, B.IsActive
    FROM tblBranch B
    INNER JOIN tblCompany C ON B.CompanyID = C.CompanyID
    WHERE B.IsDeleted = 0 AND C.IsDeleted = 0
    ORDER BY C.CompanyName, B.BranchName;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertBranch
    @CompanyID INT, @BranchName VARCHAR(200), @BranchCode VARCHAR(50),
    @Address NVARCHAR(500), @MobileNo VARCHAR(20), @Email VARCHAR(200)
AS
BEGIN
    INSERT INTO tblBranch(CompanyID, BranchName, BranchCode, Address, MobileNo, Email)
    VALUES(@CompanyID, @BranchName, @BranchCode, @Address, @MobileNo, @Email);
    SELECT 1 AS Success, 'Branch added' AS Message, SCOPE_IDENTITY() AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_UpdateBranch
    @BranchID INT, @CompanyID INT, @BranchName VARCHAR(200), @BranchCode VARCHAR(50),
    @Address NVARCHAR(500), @MobileNo VARCHAR(20), @Email VARCHAR(200), @IsActive BIT = 1
AS
BEGIN
    UPDATE tblBranch SET CompanyID=@CompanyID, BranchName=@BranchName, BranchCode=@BranchCode,
        Address=@Address, MobileNo=@MobileNo, Email=@Email, IsActive=@IsActive
    WHERE BranchID=@BranchID;
    SELECT 1 AS Success, 'Branch updated' AS Message, @BranchID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCompanyById @CompanyID INT
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, IsActive
    FROM tblCompany WHERE CompanyID = @CompanyID AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetBranchById @BranchID INT
AS
BEGIN
    SELECT BranchID, CompanyID, BranchName, BranchCode, Address, MobileNo, Email, IsActive
    FROM tblBranch WHERE BranchID = @BranchID AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertLoginHistory
    @UserID INT, @CompanyID INT, @BranchID INT, @RoleID INT, @IPAddress VARCHAR(50) = NULL, @UserAgent NVARCHAR(500) = NULL
AS
BEGIN
    INSERT INTO tblLoginHistory(UserID, CompanyID, BranchID, RoleID, IPAddress, UserAgent)
    VALUES(@UserID, NULLIF(@CompanyID,0), NULLIF(@BranchID,0), @RoleID, @IPAddress, @UserAgent);
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, @BranchID INT = NULL, @Search VARCHAR(100) = NULL, @Status VARCHAR(50) = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount, B.DepositAmount, B.AdvanceAmount, B.RemainingAmount,
           B.BookingStatus, B.PaymentStatus, B.CompanyID, B.BranchID, B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
      AND (@Status IS NULL OR @Status = '' OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR @Search = '' OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
    ORDER BY B.BookingID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_DashboardCounts
    @CompanyID INT = NULL, @BranchID INT = NULL, @FilterUserID INT = NULL
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
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)) AS TotalUsers,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND DeliveryDate=@Today
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayDeliveries,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND ReturnDate=@Today
            AND (@CompanyID IS NULL OR @CompanyID=0 OR CompanyID=@CompanyID)
            AND (@BranchID IS NULL OR @BranchID=0 OR BranchID=@BranchID)
            AND (@FilterUserID IS NULL OR BookingCreatedBy=@FilterUserID)) AS TodayReturns,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND PaymentStatus IN ('Pending','Partial')
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
        (SELECT COUNT(*) FROM tblBookings WHERE ReturnDate < @Today AND IsDeleted=0
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

CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport
    @CompanyID INT = NULL, @BranchID INT = NULL, @ReportDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.DeliveryDate, B.BookingStatus,
           B.TotalAmount, B.AdvanceAmount, B.RemainingAmount, B.BookingCreatedBy
    FROM tblBookings B INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0 AND CAST(B.DeliveryDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR @CompanyID=0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID=0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.BookingNo;
END
GO

CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, @BranchID INT = NULL, @ReportDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, P.ProductName, B.ReturnDate,
           B.DepositAmount, B.ExtraChargePerDay, B.ExtraDays, B.ExtraChargeAmount,
           B.DamageDeductionAmount, B.FinalRefundAmount, B.FinalProfitAmount, B.BookingStatus, B.ActualReturnDate, B.BookingCreatedBy
    FROM tblBookings B INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    OUTER APPLY (SELECT TOP 1 ProductName FROM tblBookingDetails BD WHERE BD.BookingID = B.BookingID) P
    WHERE B.IsDeleted = 0 AND CAST(B.ReturnDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR @CompanyID=0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID=0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.BookingNo;
END
GO
