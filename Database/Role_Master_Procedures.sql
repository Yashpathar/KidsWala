/*==============================================================================
   ROLE MASTER STORED PROCEDURES (GET, INSERT, UPDATE, DELETE)
   Database: DB_A6B32D_LabelManagement
==============================================================================*/

USE DB_A6B32D_LabelManagement;
GO

/* 1. GET ALL ROLES */
CREATE OR ALTER PROCEDURE SP_GetAllRoles
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RoleID, RoleName, Description, DataScope, IsActive, CreatedDate
    FROM tblRole
    WHERE IsDeleted = 0
    ORDER BY RoleID;
END
GO

/* 2. INSERT ROLE */
CREATE OR ALTER PROCEDURE SP_InsertRole
    @RoleName VARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @DataScope VARCHAR(30) = 'CompanyAll'
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM tblRole WHERE RoleName = @RoleName AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Role name already exists' AS Message, 0 AS ID;
        RETURN;
    END

    INSERT INTO tblRole(RoleName, Description, DataScope, IsActive, IsDeleted)
    VALUES (@RoleName, @Description, ISNULL(@DataScope, 'CompanyAll'), 1, 0);

    DECLARE @NewRoleID INT = SCOPE_IDENTITY();

    /* Seed default menu rights as 0 for new role */
    INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
    SELECT @NewRoleID, m.MenuKey, 0, 0, 0, 0, 0
    FROM (VALUES
        ('dashboard'),('category'),('size'),('color'),('product'),
        ('company'),('branch'),('user'),('role'),('roleRights'),
        ('bookingAdd'),('bookingList'),('availabilityCheck'),
        ('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
    ) AS m(MenuKey);

    SELECT 1 AS Success, 'Role created successfully' AS Message, @NewRoleID AS ID;
END
GO

/* 3. UPDATE ROLE */
CREATE OR ALTER PROCEDURE SP_UpdateRole
    @RoleID INT,
    @RoleName VARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @DataScope VARCHAR(30) = 'CompanyAll',
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM tblRole WHERE RoleName = @RoleName AND RoleID <> @RoleID AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Another role with this name already exists' AS Message, @RoleID AS ID;
        RETURN;
    END

    UPDATE tblRole
    SET RoleName = @RoleName,
        Description = @Description,
        DataScope = ISNULL(@DataScope, 'CompanyAll'),
        IsActive = ISNULL(@IsActive, 1)
    WHERE RoleID = @RoleID;

    SELECT 1 AS Success, 'Role updated successfully' AS Message, @RoleID AS ID;
END
GO

/* 4. DELETE ROLE */
CREATE OR ALTER PROCEDURE SP_DeleteRole
    @RoleID INT
AS
BEGIN
    SET NOCOUNT ON;
    /* System protected roles: SuperAdmin (1), Admin (2), BranchAdmin (3), Staff (4) */
    IF @RoleID IN (1, 2, 3, 4)
    BEGIN
        SELECT 0 AS Success, 'System core roles cannot be deleted' AS Message;
        RETURN;
    END

    /* Prevent delete if users are assigned to this role */
    IF EXISTS (SELECT 1 FROM tblUsers WHERE RoleID = @RoleID AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Cannot delete role: active users are assigned to this role' AS Message;
        RETURN;
    END

    UPDATE tblRole SET IsDeleted = 1 WHERE RoleID = @RoleID;
    DELETE FROM tblRoleRights WHERE RoleID = @RoleID;

    SELECT 1 AS Success, 'Role deleted successfully' AS Message;
END
GO

PRINT 'Role Master Stored Procedures Updated Successfully!';
GO
