-- Run after MultiTenant_Features.sql
-- Role rights: View/Create/Update/Delete + Add Role + multi-step login support

USE DB_A6B32D_LabelManagement;
GO

IF COL_LENGTH('tblRoleRights', 'IsView') IS NULL
BEGIN
    ALTER TABLE tblRoleRights ADD IsView BIT NOT NULL DEFAULT 0;
    ALTER TABLE tblRoleRights ADD IsCreate BIT NOT NULL DEFAULT 0;
    ALTER TABLE tblRoleRights ADD IsUpdate BIT NOT NULL DEFAULT 0;
    ALTER TABLE tblRoleRights ADD IsDelete BIT NOT NULL DEFAULT 0;
    UPDATE tblRoleRights
    SET IsView = CanAccess, IsCreate = CanAccess, IsUpdate = CanAccess, IsDelete = CanAccess
    WHERE CanAccess = 1;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertRole
    @RoleName VARCHAR(100),
    @Description NVARCHAR(MAX) = NULL
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tblRole WHERE RoleName = @RoleName AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Role name already exists' AS Message, 0 AS ID;
        RETURN;
    END
    INSERT INTO tblRole(RoleName, Description) VALUES (@RoleName, @Description);
    DECLARE @NewRoleID INT = SCOPE_IDENTITY();
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
    SELECT @NewRoleID, m.MenuKey, 0, 0, 0, 0, 0
    FROM (VALUES
        ('dashboard'),('category'),('size'),('color'),('product'),('company'),('roleRights'),
        ('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
    ) AS m(MenuKey);
    SELECT 1 AS Success, 'Role added' AS Message, @NewRoleID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetRoleRights @RoleID INT
AS
BEGIN
    SELECT MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete
    FROM tblRoleRights WHERE RoleID = @RoleID;
END
GO

CREATE OR ALTER PROCEDURE SP_SaveRoleRights @RoleID INT, @RightsJson NVARCHAR(MAX)
AS
BEGIN
    DELETE FROM tblRoleRights WHERE RoleID = @RoleID;
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
    SELECT @RoleID, MenuKey,
           CASE WHEN IsView = 1 OR IsCreate = 1 OR IsUpdate = 1 OR IsDelete = 1 THEN 1 ELSE 0 END,
           IsView, IsCreate, IsUpdate, IsDelete
    FROM OPENJSON(@RightsJson)
    WITH (
        MenuKey VARCHAR(100),
        IsView BIT,
        IsCreate BIT,
        IsUpdate BIT,
        IsDelete BIT
    );
    SELECT 1 AS Success, 'Rights saved' AS Message;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCompanyById @CompanyID INT
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, LogoImage, IsActive
    FROM tblCompany WHERE CompanyID = @CompanyID AND IsDeleted = 0;
END
GO
