/*==============================================================================
  TRUNCATE / CLEAR ALL DATA TABLES
  - KEEPS: tblRole row 1 only (SuperAdmin / Platform)
  - KEEPS: tblRoleRights for RoleID = 1 only
  - KEEPS: Super Admin user only (RoleID = 1, UserName superadmin or admin)
  - REMOVES: Admin, BranchAdmin, Staff, Company Admin (roles 2–5+)
  - CLEARS: bookings, customers, products, masters, companies, branches,
            other users, login history, notifications

  WARNING: This deletes ALL business data. Run only on dev/test or after backup.
  Database: DB_A6B32D_LabelManagement
==============================================================================*/

USE DB_A6B32D_LabelManagement;
GO

SET NOCOUNT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    /* ---- 1) Transaction / child tables (no RoleRights) ---- */
    IF OBJECT_ID('tblBookingDetails', 'U') IS NOT NULL
        DELETE FROM tblBookingDetails;

    IF OBJECT_ID('tblPayments', 'U') IS NOT NULL
        DELETE FROM tblPayments;

    IF OBJECT_ID('tblBookings', 'U') IS NOT NULL
        DELETE FROM tblBookings;

    IF OBJECT_ID('tblNotifications', 'U') IS NOT NULL
        DELETE FROM tblNotifications;

    IF OBJECT_ID('tblLoginHistory', 'U') IS NOT NULL
        DELETE FROM tblLoginHistory;

    IF OBJECT_ID('tblCustomers', 'U') IS NOT NULL
        DELETE FROM tblCustomers;

    /* Products may FK to Category/Size/Color — clear products before masters */
    IF OBJECT_ID('tblProducts', 'U') IS NOT NULL
        DELETE FROM tblProducts;

    IF OBJECT_ID('tblCategory', 'U') IS NOT NULL
        DELETE FROM tblCategory;

    IF OBJECT_ID('tblSize', 'U') IS NOT NULL
        DELETE FROM tblSize;

    IF OBJECT_ID('tblColor', 'U') IS NOT NULL
        DELETE FROM tblColor;

    /* ---- 2) Users: delete ALL except Super Admin (must run before role delete) ---- */
    IF OBJECT_ID('tblUsers', 'U') IS NOT NULL
    BEGIN
        DELETE FROM tblUsers
        WHERE NOT (
            RoleID = 1
            AND UserName IN ('superadmin', 'admin')
        );

        /* Ensure one Super Admin exists */
        IF NOT EXISTS (
            SELECT 1 FROM tblUsers
            WHERE RoleID = 1 AND UserName IN ('superadmin', 'admin') AND IsDeleted = 0
        )
        BEGIN
            INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
            VALUES (1, NULL, NULL, 'Super Admin', 'superadmin', 'super@kidswalla.com', '9999990001', '123', 1);
        END
        ELSE
        BEGIN
            /* Normalize Super Admin (no company/branch) */
            UPDATE tblUsers
            SET CompanyID = NULL, BranchID = NULL, RoleID = 1, IsActive = 1, PasswordHash = '123'
            WHERE UserName IN ('superadmin', 'admin') AND RoleID = 1;
        END
    END

    /* ---- 3) Roles: keep only SuperAdmin (RoleID = 1) ---- */
    IF OBJECT_ID('tblRoleRights', 'U') IS NOT NULL
        DELETE FROM tblRoleRights WHERE RoleID <> 1;

    IF OBJECT_ID('tblRole', 'U') IS NOT NULL
    BEGIN
        DELETE FROM tblRole WHERE RoleID <> 1;

        IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 1)
        BEGIN
            SET IDENTITY_INSERT tblRole ON;
            INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsActive, IsDeleted)
            VALUES (1, 'SuperAdmin', 'Developer / full system', 'Platform', 1, 0);
            SET IDENTITY_INSERT tblRole OFF;
        END
        ELSE
        BEGIN
            UPDATE tblRole
            SET RoleName = 'SuperAdmin',
                Description = 'Developer / full system',
                DataScope = 'Platform',
                IsActive = 1,
                IsDeleted = 0
            WHERE RoleID = 1;
        END

        IF EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblRole'))
            DBCC CHECKIDENT ('tblRole', RESEED, 1);
    END

    /* ---- 4) Branches & companies ---- */
    IF OBJECT_ID('tblBranch', 'U') IS NOT NULL
        DELETE FROM tblBranch;

    IF OBJECT_ID('tblCompany', 'U') IS NOT NULL
        DELETE FROM tblCompany;

    /* ---- 5) Reset IDENTITY seeds (optional clean IDs) ---- */
    IF OBJECT_ID('tblBookingDetails', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblBookingDetails'))
        DBCC CHECKIDENT ('tblBookingDetails', RESEED, 0);

    IF OBJECT_ID('tblPayments', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblPayments'))
        DBCC CHECKIDENT ('tblPayments', RESEED, 0);

    IF OBJECT_ID('tblBookings', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblBookings'))
        DBCC CHECKIDENT ('tblBookings', RESEED, 0);

    IF OBJECT_ID('tblNotifications', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblNotifications'))
        DBCC CHECKIDENT ('tblNotifications', RESEED, 0);

    IF OBJECT_ID('tblLoginHistory', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblLoginHistory'))
        DBCC CHECKIDENT ('tblLoginHistory', RESEED, 0);

    IF OBJECT_ID('tblCustomers', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblCustomers'))
        DBCC CHECKIDENT ('tblCustomers', RESEED, 0);

    IF OBJECT_ID('tblProducts', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblProducts'))
        DBCC CHECKIDENT ('tblProducts', RESEED, 0);

    IF OBJECT_ID('tblCategory', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblCategory'))
        DBCC CHECKIDENT ('tblCategory', RESEED, 0);

    IF OBJECT_ID('tblSize', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblSize'))
        DBCC CHECKIDENT ('tblSize', RESEED, 0);

    IF OBJECT_ID('tblColor', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblColor'))
        DBCC CHECKIDENT ('tblColor', RESEED, 0);

    IF OBJECT_ID('tblBranch', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblBranch'))
        DBCC CHECKIDENT ('tblBranch', RESEED, 0);

    IF OBJECT_ID('tblCompany', 'U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.identity_columns WHERE object_id = OBJECT_ID('tblCompany'))
        DBCC CHECKIDENT ('tblCompany', RESEED, 0);

    COMMIT TRANSACTION;

    PRINT 'Done. Kept: SuperAdmin role (1), its role rights, Super Admin user.';
    PRINT 'Removed: roles 2–5 (Admin, BranchAdmin, Staff, Company Admin) and all business data.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO

/* ---- Verify ---- */
SELECT 'tblRole' AS Tbl, COUNT(*) AS Cnt FROM tblRole
UNION ALL SELECT 'tblRoleRights', COUNT(*) FROM tblRoleRights
UNION ALL SELECT 'tblUsers', COUNT(*) FROM tblUsers
UNION ALL SELECT 'tblCompany', COUNT(*) FROM tblCompany
UNION ALL SELECT 'tblBranch', COUNT(*) FROM tblBranch
UNION ALL SELECT 'tblBookings', COUNT(*) FROM tblBookings;
GO

SELECT * FROM tblRole;
GO

SELECT UserID, UserName, RoleID, CompanyID, BranchID FROM tblUsers;
GO
