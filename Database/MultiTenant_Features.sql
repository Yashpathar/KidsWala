-- Company-wise data, customer by mobile, notifications, role rights

IF OBJECT_ID('tblRoleRights','U') IS NULL
BEGIN
    CREATE TABLE tblRoleRights (
        RoleRightID INT IDENTITY(1,1) PRIMARY KEY,
        RoleID INT NOT NULL,
        MenuKey VARCHAR(100) NOT NULL,
        CanAccess BIT NOT NULL DEFAULT 0,
        FOREIGN KEY(RoleID) REFERENCES tblRole(RoleID)
    );
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess)
    SELECT 1, m.MenuKey, 1 FROM (VALUES
        ('dashboard'),('category'),('size'),('color'),('product'),('company'),('roleRights'),
        ('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
    ) v(MenuKey) m;
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess)
    SELECT 2, m.MenuKey, 1 FROM (VALUES
        ('dashboard'),('category'),('size'),('color'),('product'),
        ('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
    ) v(MenuKey) m;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllRoles
AS
BEGIN
    SELECT RoleID, RoleName, Description FROM tblRole WHERE IsDeleted = 0 ORDER BY RoleID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCustomerByMobile
    @CompanyID INT = NULL, @MobileNo VARCHAR(20)
AS
BEGIN
    SELECT TOP 1 CustomerID, CompanyID, FullName, ContactNo1, ContactNo2, Address, City, Notes
    FROM tblCustomers
    WHERE IsDeleted = 0
      AND (ContactNo1 = @MobileNo OR ContactNo2 = @MobileNo)
      AND (@CompanyID IS NULL OR CompanyID = @CompanyID);
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllCompanies
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, IsActive
    FROM tblCompany WHERE IsDeleted = 0 ORDER BY CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertCompany
    @CompanyName VARCHAR(200), @CompanyCode VARCHAR(50), @BusinessType VARCHAR(100),
    @Address NVARCHAR(500), @MobileNo VARCHAR(20), @Email VARCHAR(200), @GSTNo VARCHAR(50)
AS
BEGIN
    INSERT INTO tblCompany(CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo)
    VALUES(@CompanyName, @CompanyCode, @BusinessType, @Address, @MobileNo, @Email, @GSTNo);
    SELECT 1 AS Success, 'Company added' AS Message, SCOPE_IDENTITY() AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_UpdateCompany
    @CompanyID INT, @CompanyName VARCHAR(200), @CompanyCode VARCHAR(50), @BusinessType VARCHAR(100),
    @Address NVARCHAR(500), @MobileNo VARCHAR(20), @Email VARCHAR(200), @GSTNo VARCHAR(50), @IsActive BIT = 1
AS
BEGIN
    UPDATE tblCompany SET
        CompanyName=@CompanyName, CompanyCode=@CompanyCode, BusinessType=@BusinessType,
        Address=@Address, MobileNo=@MobileNo, Email=@Email, GSTNo=@GSTNo, IsActive=@IsActive
    WHERE CompanyID=@CompanyID;
    SELECT 1 AS Success, 'Company updated' AS Message, @CompanyID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetRoleRights @RoleID INT
AS
BEGIN
    SELECT MenuKey, CanAccess FROM tblRoleRights WHERE RoleID = @RoleID;
END
GO

CREATE OR ALTER PROCEDURE SP_SaveRoleRights @RoleID INT, @RightsJson NVARCHAR(MAX)
AS
BEGIN
    DELETE FROM tblRoleRights WHERE RoleID = @RoleID;
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess)
    SELECT @RoleID, MenuKey, CanAccess
    FROM OPENJSON(@RightsJson)
    WITH (MenuKey VARCHAR(100), CanAccess BIT);
    SELECT 1 AS Success, 'Rights saved' AS Message;
END
GO

CREATE OR ALTER PROCEDURE SP_GetNotifications
    @CompanyID INT = NULL, @UserID INT = NULL, @TopN INT = 20
AS
BEGIN
    SELECT TOP (@TopN) NotificationID, Title, Message, NotificationType, ReferenceID, IsRead, CreatedDate
    FROM tblNotifications
    WHERE (@CompanyID IS NULL OR CompanyID = @CompanyID)
      AND (@UserID IS NULL OR UserID IS NULL OR UserID = @UserID)
    ORDER BY CreatedDate DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_MarkNotificationRead @NotificationID INT
AS
BEGIN
    UPDATE tblNotifications SET IsRead = 1 WHERE NotificationID = @NotificationID;
    SELECT 1 AS Success, 'Marked read' AS Message;
END
GO

CREATE OR ALTER PROCEDURE SP_PaymentReport @CompanyID INT = NULL, @FromDate DATE = NULL, @ToDate DATE = NULL
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
    ORDER BY P.PaymentDate DESC;
END
GO
