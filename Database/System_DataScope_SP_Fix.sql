-- Comprehensive Database Stored Procedure DataScope Fix
-- Ensures Super Admin (@CompanyID = NULL or 0) and Platform/Company Scope work seamlessly for all tables

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Size Master
CREATE OR ALTER PROCEDURE SP_GetAllSizes
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT SizeID, CompanyID, SizeName, SizeCode, SortOrder, IsActive, CreatedDate
    FROM tblSize
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR CompanyID = @CompanyID)
    ORDER BY SortOrder, SizeName;
END
GO

-- 2. Category Master
CREATE OR ALTER PROCEDURE SP_GetAllCategories
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CategoryID, CompanyID, CategoryName, Description, IsActive, CreatedDate
    FROM tblCategory
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR CompanyID = @CompanyID)
    ORDER BY CategoryName;
END
GO

-- 3. Color Master
CREATE OR ALTER PROCEDURE SP_GetAllColors
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ColorID, CompanyID, ColorName, ColorCode, IsActive, CreatedDate
    FROM tblColor
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR CompanyID = @CompanyID)
    ORDER BY ColorName;
END
GO

-- 4. Branch Master
CREATE OR ALTER PROCEDURE SP_GetAllBranches
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BranchID, B.CompanyID, C.CompanyName, B.BranchName, B.BranchCode, B.Address, B.MobileNo, B.Email, B.IsActive, B.CreatedDate
    FROM tblBranch B
    LEFT JOIN tblCompany C ON B.CompanyID = C.CompanyID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
    ORDER BY B.BranchID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetBranchesByCompany
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BranchID, B.CompanyID, C.CompanyName, B.BranchName, B.BranchCode, B.Address, B.MobileNo, B.Email, B.IsActive, B.CreatedDate
    FROM tblBranch B
    LEFT JOIN tblCompany C ON B.CompanyID = C.CompanyID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
    ORDER BY B.BranchName;
END
GO

-- 5. Product Master
CREATE OR ALTER PROCEDURE SP_GetAllProducts
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, C.CompanyName, P.BranchID, BR.BranchName, P.ProductCode, P.ProductName,
           P.CategoryID, Cat.CategoryName, P.SizeID, S.SizeName, P.ColorID, Col.ColorName,
           P.RentAmount, P.DepositAmount, P.IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize,
           P.ProductImage, P.CreatedDate
    FROM tblProducts P
    LEFT JOIN tblCompany C ON P.CompanyID = C.CompanyID
    LEFT JOIN tblBranch BR ON P.BranchID = BR.BranchID
    LEFT JOIN tblCategory Cat ON P.CategoryID = Cat.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor Col ON P.ColorID = Col.ColorID
    WHERE P.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR P.BranchID = @BranchID)
    ORDER BY P.ProductID DESC;
END
GO

-- 6. Customer Master
CREATE OR ALTER PROCEDURE SP_GetAllCustomers
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT C.CustomerID, C.CompanyID, C.BranchID, BR.BranchName, C.FullName, C.ContactNo1, C.ContactNo2,
           C.Address, C.City, C.Notes, C.CreatedDate
    FROM tblCustomers C
    LEFT JOIN tblBranch BR ON C.BranchID = BR.BranchID
    WHERE C.IsDeleted = 0 
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR C.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR C.BranchID = @BranchID)
    ORDER BY C.CustomerID DESC;
END
GO

-- 7. User Master
CREATE OR ALTER PROCEDURE SP_GetAllUsers
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.CompanyID, C.CompanyName, U.BranchID, BR.BranchName, U.RoleID, R.RoleName,
           U.Username, U.PasswordHash AS Password, U.FullName, U.Email, U.MobileNo, U.IsActive, U.CreatedDate
    FROM tblUsers U
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    LEFT JOIN tblBranch BR ON U.BranchID = BR.BranchID
    LEFT JOIN tblRole R ON U.RoleID = R.RoleID
    WHERE U.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR U.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR U.BranchID = @BranchID)
    ORDER BY U.UserID DESC;
END
GO
