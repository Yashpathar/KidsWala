/*==============================================================================
  Fix FK error: RoleID 2,3,4 missing after Truncate_All_Keep_SuperAdmin.sql
  1) Creates roles Admin, BranchAdmin, Staff (keeps SuperAdmin = 1)
  2) Creates sample users for your company + branch
  Run on DB_A6B32D_LabelManagement AFTER company & branch exist in UI
==============================================================================*/

USE DB_A6B32D_LabelManagement;
GO

IF COL_LENGTH('tblRole', 'DataScope') IS NULL
    ALTER TABLE tblRole ADD DataScope VARCHAR(30) NOT NULL DEFAULT 'CompanyAll';
GO

/* ========== ROLES 1–4 (SuperAdmin already exists) ========== */
SET IDENTITY_INSERT tblRole ON;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 1)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsActive, IsDeleted)
    VALUES (1, 'SuperAdmin', 'Developer / full system', 'Platform', 1, 0);
ELSE
    UPDATE tblRole SET RoleName = 'SuperAdmin', DataScope = 'Platform', IsDeleted = 0, IsActive = 1 WHERE RoleID = 1;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 2)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsActive, IsDeleted)
    VALUES (2, 'Admin', 'Company owner', 'CompanyAll', 1, 0);
ELSE
    UPDATE tblRole SET RoleName = 'Admin', DataScope = 'CompanyAll', IsDeleted = 0, IsActive = 1 WHERE RoleID = 2;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 3)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsActive, IsDeleted)
    VALUES (3, 'BranchAdmin', 'Branch owner', 'BranchAll', 1, 0);
ELSE
    UPDATE tblRole SET RoleName = 'BranchAdmin', DataScope = 'BranchAll', IsDeleted = 0, IsActive = 1 WHERE RoleID = 3;

IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 4)
    INSERT INTO tblRole(RoleID, RoleName, Description, DataScope, IsActive, IsDeleted)
    VALUES (4, 'Staff', 'Booking entry only', 'BranchOwnOnly', 1, 0);
ELSE
    UPDATE tblRole SET RoleName = 'Staff', DataScope = 'BranchOwnOnly', IsDeleted = 0, IsActive = 1 WHERE RoleID = 4;

SET IDENTITY_INSERT tblRole OFF;
GO

/* Menu rights for roles 2–4 (if tblRoleRights exists) */
IF OBJECT_ID('tblRoleRights', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblRoleRights WHERE RoleID = 2)
        INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess)
        SELECT 2, m.MenuKey, 1 FROM (VALUES
            ('dashboard'),('category'),('size'),('color'),('product'),
            ('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn'),('reportBooking'),('reportPayment')
        ) AS m(MenuKey);

    IF NOT EXISTS (SELECT 1 FROM tblRoleRights WHERE RoleID = 3)
        INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess, IsView, IsCreate, IsUpdate, IsDelete)
        SELECT 3, m.MenuKey, 1, 1, 1, 1, 1 FROM (VALUES
            ('dashboard'),
            ('category'),('size'),('color'),('product'),
            ('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn')
        ) AS m(MenuKey);

    IF NOT EXISTS (SELECT 1 FROM tblRoleRights WHERE RoleID = 4)
        INSERT INTO tblRoleRights(RoleID, MenuKey, CanAccess)
        SELECT 4, m.MenuKey, 1 FROM (VALUES
            ('dashboard'),('bookingAdd'),('bookingList'),('reportDelivery'),('reportReturn')
        ) AS m(MenuKey);
END
GO

/* ========== USERS — change company/branch names if yours differ ========== */
DECLARE @CompanyID INT = (SELECT TOP 1 CompanyID FROM tblCompany WHERE IsDeleted = 0 ORDER BY CompanyID);
DECLARE @BranchID INT = (SELECT TOP 1 BranchID FROM tblBranch WHERE IsDeleted = 0 ORDER BY BranchID);

IF @CompanyID IS NULL
BEGIN
    RAISERROR('No company found. Add a company in Company Master first.', 16, 1);
    RETURN;
END

IF @BranchID IS NULL
BEGIN
    RAISERROR('No branch found. Add a branch in Branch Master first.', 16, 1);
    RETURN;
END

/* Company Admin */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin_kidswalla')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (2, @CompanyID, NULL, 'Company Admin', 'admin_kidswalla', 'admin@kidswalla.com', '9854789526', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 2, CompanyID = @CompanyID, BranchID = NULL, PasswordHash = '123', IsActive = 1, IsDeleted = 0
    WHERE UserName = 'admin_kidswalla';

/* Branch Admin */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'b1_kw')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (3, @CompanyID, @BranchID, 'Branch Admin', 'b1_kw', 'b1@gmail.com', '7894568597', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 3, CompanyID = @CompanyID, BranchID = @BranchID, PasswordHash = '123', IsActive = 1, IsDeleted = 0
    WHERE UserName = 'b1_kw';

/* Staff */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'staff_b1')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (4, @CompanyID, @BranchID, 'Branch Staff', 'staff_b1', 'staff@kidswalla.com', '9999990002', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 4, CompanyID = @CompanyID, BranchID = @BranchID, PasswordHash = '123', IsActive = 1, IsDeleted = 0
    WHERE UserName = 'staff_b1';

GO

/* Verify */
SELECT RoleID, RoleName, DataScope FROM tblRole WHERE IsDeleted = 0 ORDER BY RoleID;

SELECT U.UserName, R.RoleName, C.CompanyName, B.BranchName, U.IsActive
FROM tblUsers U
INNER JOIN tblRole R ON U.RoleID = R.RoleID
LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
LEFT JOIN tblBranch B ON U.BranchID = B.BranchID
WHERE U.IsDeleted = 0
ORDER BY U.RoleID, U.UserName;
GO

PRINT 'Done. Login: admin_kidswalla / b1_kw / staff_b1 — password: 123';
GO
