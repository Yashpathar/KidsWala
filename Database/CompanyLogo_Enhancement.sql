-- Script to ensure LogoImage is included in all Company and Login Stored Procedures
USE DB_A6B32D_LabelManagement;
GO

CREATE OR ALTER PROCEDURE SP_GetCompanyById @CompanyID INT
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, LogoImage, IsActive
    FROM tblCompany WHERE CompanyID = @CompanyID AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllCompanies
AS
BEGIN
    SELECT CompanyID, CompanyName, CompanyCode, BusinessType, Address, MobileNo, Email, GSTNo, LogoImage, IsActive
    FROM tblCompany WHERE IsDeleted = 0 ORDER BY CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCompaniesForLogin
AS
BEGIN
    SELECT C.CompanyID, C.CompanyName, C.CompanyCode, C.BusinessType, C.LogoImage
    FROM tblCompany C WHERE C.IsDeleted = 0 AND C.IsActive = 1 ORDER BY C.CompanyName;
END
GO

CREATE OR ALTER PROCEDURE SP_UserLoginByName @UserName VARCHAR(100), @Password VARCHAR(200) = NULL
AS
BEGIN
    SELECT U.UserID, U.RoleID, U.CompanyID, U.BranchID, U.FullName, U.UserName, U.Email, U.MobileNo, U.PasswordHash,
           R.RoleName, R.DataScope, C.CompanyName, C.LogoImage AS CompanyLogo, B.BranchName
    FROM tblUsers U
    INNER JOIN tblRole R ON U.RoleID = R.RoleID AND R.IsDeleted = 0
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    LEFT JOIN tblBranch B ON U.BranchID = B.BranchID
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0;
END
GO
