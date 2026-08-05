-- Single-step login: RoleID 1–4, standard users (password: 123)
-- Run after CompanyBranch_Structure.sql on DB_A6B32D_LabelManagement

USE DB_A6B32D_LabelManagement;
GO

/* ========== STANDARD ROLES (1–4) ========== */
SET IDENTITY_INSERT tblRole ON;
IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 1)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsDeleted) VALUES (1, 'SuperAdmin', 'Developer / full system', 'Platform', 0);
ELSE
    UPDATE tblRole SET RoleName = 'SuperAdmin', Description = 'Developer / full system', DataScope = 'Platform', IsDeleted = 0 WHERE RoleID = 1;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 2)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsDeleted) VALUES (2, 'Admin', 'Company owner', 'CompanyAll', 0);
ELSE
    UPDATE tblRole SET RoleName = 'Admin', Description = 'Company owner', DataScope = 'CompanyAll', IsDeleted = 0 WHERE RoleID = 2;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 3)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsDeleted) VALUES (3, 'BranchAdmin', 'Branch owner', 'BranchAll', 0);
ELSE
    UPDATE tblRole SET RoleName = 'BranchAdmin', Description = 'Branch owner', DataScope = 'BranchAll', IsDeleted = 0 WHERE RoleID = 3;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 4)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsDeleted) VALUES (4, 'Staff', 'Booking entry only', 'BranchOwnOnly', 0);
ELSE
    UPDATE tblRole SET RoleName = 'Staff', Description = 'Booking entry only', DataScope = 'BranchOwnOnly', IsDeleted = 0 WHERE RoleID = 4;
SET IDENTITY_INSERT tblRole OFF;
GO

/* Legacy role names → map to standard scopes */
UPDATE tblRole SET DataScope = 'Platform' WHERE RoleName IN ('Super Admin', 'SuperAdmin') AND RoleID <> 1;
UPDATE tblRole SET DataScope = 'CompanyAll' WHERE RoleName IN ('Company Admin') AND RoleID NOT IN (1,2);
UPDATE tblRole SET DataScope = 'BranchAll' WHERE RoleName IN ('Accountant') AND DataScope NOT IN ('Platform','CompanyAll','BranchOwnOnly');
UPDATE tblRole SET DataScope = 'BranchOwnOnly' WHERE RoleName IN ('Staff', 'Accountant') AND DataScope = 'OwnBookingsOnly';
GO

DECLARE @KW INT = (SELECT TOP 1 CompanyID FROM tblCompany WHERE CompanyCode = 'KW' AND IsDeleted = 0);
DECLARE @BN INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'KWN' AND IsDeleted = 0);
DECLARE @BC INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE BranchCode = 'KWC' AND IsDeleted = 0);

/* Super Admin — only one active account */
UPDATE tblUsers SET IsActive = 0 WHERE RoleID = 1 AND UserName NOT IN ('superadmin', 'admin');
IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin')
    UPDATE tblUsers SET UserName = 'superadmin', RoleID = 1, CompanyID = NULL, BranchID = NULL,
        FullName = 'Super Admin', PasswordHash = '123', IsActive = 1 WHERE UserName = 'admin';
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'superadmin')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
    VALUES (1, NULL, NULL, 'Super Admin', 'superadmin', 'super@kidswalla.com', '9999990001', '123', 1);
ELSE
    UPDATE tblUsers SET RoleID = 1, CompanyID = NULL, BranchID = NULL, PasswordHash = '123', IsActive = 1 WHERE UserName = 'superadmin';

IF @KW IS NOT NULL
BEGIN
    /* Company Admin */
    IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'kidswalla_admin')
        UPDATE tblUsers SET UserName = 'admin_kidswalla', RoleID = 2, CompanyID = @KW, BranchID = NULL,
            FullName = 'Kids Walla Admin', PasswordHash = '123', IsActive = 1 WHERE UserName = 'kidswalla_admin';
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin_kidswalla')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
        VALUES (2, @KW, NULL, 'Kids Walla Admin', 'admin_kidswalla', 'admin@kidswalla.com', '9999991100', '123', 1);
    ELSE
        UPDATE tblUsers SET RoleID = 2, CompanyID = @KW, BranchID = NULL, PasswordHash = '123', IsActive = 1 WHERE UserName = 'admin_kidswalla';

    /* Branch Admin — Nikol */
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'b1_nikol')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
        VALUES (3, @KW, @BN, 'Nikol Branch Admin', 'b1_nikol', 'b1@kidswalla.com', '9999991101', '123', 1);
    ELSE
        UPDATE tblUsers SET RoleID = 3, CompanyID = @KW, BranchID = @BN, PasswordHash = '123', IsActive = 1 WHERE UserName = 'b1_nikol';

    /* Staff — Nikol */
    IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant1')
        UPDATE tblUsers SET UserName = 'staff_nikol1', RoleID = 4, CompanyID = @KW, BranchID = @BN,
            PasswordHash = '123', IsActive = 1 WHERE UserName = 'accountant1';
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'staff_nikol1')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
        VALUES (4, @KW, @BN, 'Staff Nikol 1', 'staff_nikol1', 'staff1@kidswalla.com', '9999991102', '123', 1);

    IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'accountant2')
        UPDATE tblUsers SET UserName = 'staff_nikol2', RoleID = 4, CompanyID = @KW, BranchID = @BN,
            PasswordHash = '123', IsActive = 1 WHERE UserName = 'accountant2';

    /* Staff — Chandlodiya */
    IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'yash')
        UPDATE tblUsers SET RoleID = 4, CompanyID = @KW, BranchID = @BC, PasswordHash = '123', IsActive = 1 WHERE UserName = 'yash';
    IF EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'sagar')
        UPDATE tblUsers SET RoleID = 4, CompanyID = @KW, BranchID = @BC, PasswordHash = '123', IsActive = 1 WHERE UserName = 'sagar';

    /* Optional alias from spec */
    IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin_nikol')
        INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive)
        VALUES (3, @KW, @BN, 'Nikol Admin', 'admin_nikol', 'admin.nikol@kidswalla.com', '9999991105', '123', 1);
END
GO

CREATE OR ALTER PROCEDURE SP_UserLoginByName
    @UserName VARCHAR(100),
    @Password VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.RoleID, U.CompanyID, U.BranchID, U.FullName, U.UserName, U.Email, U.MobileNo, U.PasswordHash,
           R.RoleName, R.DataScope, C.CompanyName, B.BranchName
    FROM tblUsers U
    INNER JOIN tblRole R ON U.RoleID = R.RoleID AND R.IsDeleted = 0
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID AND C.IsDeleted = 0
    LEFT JOIN tblBranch B ON U.BranchID = B.BranchID AND B.IsDeleted = 0
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0
      AND (
            @Password IS NULL OR LTRIM(RTRIM(@Password)) = ''
            OR NULLIF(LTRIM(RTRIM(U.PasswordHash)), '') IS NULL
            OR U.PasswordHash = @Password
          );
END
GO

PRINT 'Login_SingleStep_Roles.sql completed. Test: superadmin/123, admin_kidswalla/123, b1_nikol/123, staff_nikol1/123';
GO
