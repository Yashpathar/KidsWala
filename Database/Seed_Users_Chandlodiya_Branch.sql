/* Users for Kids Walla Chandlodiya — BranchID 2, CompanyID 1 */
USE DB_A6B32D_LabelManagement;
GO

DECLARE @CompanyID INT = 1;
DECLARE @BranchID INT = 2;

IF NOT EXISTS (SELECT 1 FROM tblBranch WHERE BranchID = @BranchID AND CompanyID = @CompanyID AND IsDeleted = 0)
BEGIN
    RAISERROR('BranchID 2 / CompanyID 1 not found. Check tblBranch.', 16, 1);
    RETURN;
END

/* Roles 2–4 must exist */
IF NOT EXISTS (SELECT 1 FROM tblRole WHERE RoleID = 4 AND IsDeleted = 0)
BEGIN
    RAISERROR('Run Seed_Roles_And_Users.sql first (roles 1–4).', 16, 1);
    RETURN;
END

/* Company Admin — whole company (no branch) */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin_kidswalla')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (2, @CompanyID, NULL, 'Kids Walla Admin', 'admin_kidswalla', 'admin@kidswalla.com', '9854789526', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 2, CompanyID = @CompanyID, BranchID = NULL, PasswordHash = '123', IsActive = 1
    WHERE UserName = 'admin_kidswalla';

/* Branch Admin — Chandlodiya (BranchID 2) */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'admin_chandlodiya')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (3, @CompanyID, @BranchID, 'Chandlodiya Branch Admin', 'admin_chandlodiya', 'chandlodiya@kidswalla.com', '9999992222', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 3, CompanyID = @CompanyID, BranchID = @BranchID, PasswordHash = '123', IsActive = 1
    WHERE UserName = 'admin_chandlodiya';

/* Staff — Chandlodiya */
IF NOT EXISTS (SELECT 1 FROM tblUsers WHERE UserName = 'staff_chandlodiya')
    INSERT INTO tblUsers(RoleID, CompanyID, BranchID, FullName, UserName, Email, MobileNo, PasswordHash, IsActive, IsDeleted)
    VALUES (4, @CompanyID, @BranchID, 'Chandlodiya Staff', 'staff_chandlodiya', 'staff.chand@kidswalla.com', '9999992202', '123', 1, 0);
ELSE
    UPDATE tblUsers SET RoleID = 4, CompanyID = @CompanyID, BranchID = @BranchID, PasswordHash = '123', IsActive = 1
    WHERE UserName = 'staff_chandlodiya';

GO

SELECT U.UserName AS [Login ID],
       '123' AS [Password],
       R.RoleName,
       U.CompanyID,
       U.BranchID,
       B.BranchName
FROM tblUsers U
INNER JOIN tblRole R ON U.RoleID = R.RoleID
LEFT JOIN tblBranch B ON U.BranchID = B.BranchID
WHERE U.IsDeleted = 0 AND (U.BranchID = 2 OR (U.CompanyID = 1 AND U.BranchID IS NULL))
ORDER BY R.RoleID;
GO
