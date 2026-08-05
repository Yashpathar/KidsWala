/* Role rights: fix JSON save + BranchAdmin defaults + branch menu */
USE DB_A6B32D_LabelManagement;
GO

IF OBJECT_ID('tblRoleRights', 'U') IS NULL
BEGIN
    RAISERROR('tblRoleRights not found. Run MultiTenant / Company scripts first.', 16, 1);
    RETURN;
END
GO

CREATE OR ALTER PROCEDURE SP_GetUserMenuRights @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete
    FROM tblRoleRights
    WHERE RoleID = @RoleID;
END
GO

CREATE OR ALTER PROCEDURE SP_SaveRoleRights @RoleID INT, @RightsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM tblRoleRights WHERE RoleID = @RoleID;

    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
    SELECT @RoleID,
           j.MenuKey,
           CASE WHEN j.IsView = 1 OR j.IsCreate = 1 OR j.IsUpdate = 1 OR j.IsDelete = 1 THEN 1 ELSE 0 END,
           ISNULL(j.IsView, 0),
           ISNULL(j.IsCreate, 0),
           ISNULL(j.IsUpdate, 0),
           ISNULL(j.IsDelete, 0)
    FROM OPENJSON(@RightsJson)
    WITH (
        MenuKey VARCHAR(100) '$.menuKey',
        IsView BIT '$.isView',
        IsCreate BIT '$.isCreate',
        IsUpdate BIT '$.isUpdate',
        IsDelete BIT '$.isDelete'
    ) j
    WHERE j.MenuKey IS NOT NULL AND LTRIM(RTRIM(j.MenuKey)) <> '';

    SELECT 1 AS Success, 'Rights saved' AS Message;
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
        ('dashboard'),('category'),('size'),('color'),('product'),
        ('company'),('branch'),('roleRights'),
        ('bookingAdd'),('bookingList'),
        ('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
    ) AS m(MenuKey);
    SELECT 1 AS Success, 'Role added' AS Message, @NewRoleID AS ID;
END
GO

/* Ensure every standard role has all menu rows (missing keys inserted as denied) */
DECLARE @Menus TABLE (MenuKey VARCHAR(100));
INSERT INTO @Menus VALUES
('dashboard'),('category'),('size'),('color'),('product'),
('company'),('branch'),('roleRights'),
('bookingAdd'),('bookingList'),
('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment');

INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
SELECT R.RoleID, M.MenuKey, 0, 0, 0, 0, 0
FROM tblRole R
CROSS JOIN @Menus M
WHERE R.IsDeleted = 0
  AND NOT EXISTS (SELECT 1 FROM tblRoleRights RR WHERE RR.RoleID = R.RoleID AND RR.MenuKey = M.MenuKey);
GO

/* Recommended: BranchAdmin (3) — branch operations, no platform */
DELETE FROM tblRoleRights WHERE RoleID = 3;
INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
SELECT 3, m.MenuKey, 1, 1, 1, 1, 1 FROM (VALUES
    ('dashboard'),
    ('category'),('size'),('color'),('product'),
    ('bookingAdd'),('bookingList'),
    ('reportDelivery'),('reportReturn')
) AS m(MenuKey);
GO

/* Company Admin (2) — company scope, no platform-only */
DELETE FROM tblRoleRights WHERE RoleID = 2;
INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
SELECT 2, m.MenuKey, 1, 1, 1, 1, 1 FROM (VALUES
    ('dashboard'),
    ('category'),('size'),('color'),('product'),
    ('branch'),
    ('bookingAdd'),('bookingList'),
    ('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
) AS m(MenuKey);
GO

/* SuperAdmin (1) — all menus */
DELETE FROM tblRoleRights WHERE RoleID = 1;
INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
SELECT 1, m.MenuKey, 1, 1, 1, 1, 1 FROM (VALUES
    ('dashboard'),
    ('category'),('size'),('color'),('product'),
    ('company'),('branch'),('roleRights'),
    ('bookingAdd'),('bookingList'),
    ('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
) AS m(MenuKey);
GO

PRINT 'RoleRights_Wiring_Fix.sql done. Re-login after running.';
GO
