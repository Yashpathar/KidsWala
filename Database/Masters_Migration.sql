/*==============================================================
 MASTERS MIGRATION — Category, Size, Color, Product (FK)
 Run on: DB_A6B32D_LabelManagement (or KidsFashionRentalDB)
==============================================================*/
USE DB_A6B32D_LabelManagement;
GO

/*---------- tblCategory ----------*/
IF OBJECT_ID('tblCategory','U') IS NULL
BEGIN
    CREATE TABLE tblCategory
    (
        CategoryID      INT IDENTITY(1,1) PRIMARY KEY,
        CompanyID       INT NULL,
        CategoryName    VARCHAR(100) NOT NULL,
        Description     NVARCHAR(500) NULL,
        IsActive        BIT DEFAULT 1,
        CreatedDate     DATETIME DEFAULT GETDATE(),
        CreatedBy       INT NULL,
        ModifiedDate    DATETIME NULL,
        ModifiedBy      INT NULL,
        IsDeleted       BIT DEFAULT 0,
        CONSTRAINT FK_Category_Company FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
    );
    CREATE UNIQUE INDEX UX_Category_Name ON tblCategory(CompanyID, CategoryName) WHERE IsDeleted = 0;

    INSERT INTO tblCategory(CompanyID, CategoryName, Description) VALUES
    (1,'Kurta','Traditional Kurta'),(1,'Koti Kurta','Koti style kurta'),(1,'Indo Western','Indo western wear'),
    (1,'Blazer','Kids blazer'),(1,'Jodhpuri','Jodhpuri suit'),(1,'Sherwani','Wedding sherwani'),(1,'Party Wear','Party outfits');
END
GO

/*---------- tblSize ----------*/
IF OBJECT_ID('tblSize','U') IS NULL
BEGIN
    CREATE TABLE tblSize
    (
        SizeID          INT IDENTITY(1,1) PRIMARY KEY,
        CompanyID       INT NULL,
        SizeName        VARCHAR(50) NOT NULL,
        SizeCode        VARCHAR(20) NULL,
        SortOrder       INT DEFAULT 0,
        IsActive        BIT DEFAULT 1,
        CreatedDate     DATETIME DEFAULT GETDATE(),
        CreatedBy       INT NULL,
        ModifiedDate    DATETIME NULL,
        ModifiedBy      INT NULL,
        IsDeleted       BIT DEFAULT 0,
        CONSTRAINT FK_Size_Company FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
    );
    INSERT INTO tblSize(CompanyID, SizeName, SizeCode, SortOrder) VALUES
    (1,'28','S',1),(1,'30','M',2),(1,'32','L',3),(1,'34','XL',4),(1,'36','XXL',5);
END
GO

/*---------- tblColor ----------*/
IF OBJECT_ID('tblColor','U') IS NULL
BEGIN
    CREATE TABLE tblColor
    (
        ColorID         INT IDENTITY(1,1) PRIMARY KEY,
        CompanyID       INT NULL,
        ColorName       VARCHAR(100) NOT NULL,
        ColorCode       VARCHAR(20) NULL,
        IsActive        BIT DEFAULT 1,
        CreatedDate     DATETIME DEFAULT GETDATE(),
        CreatedBy       INT NULL,
        ModifiedDate    DATETIME NULL,
        ModifiedBy      INT NULL,
        IsDeleted       BIT DEFAULT 0,
        CONSTRAINT FK_Color_Company FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
    );
    INSERT INTO tblColor(CompanyID, ColorName, ColorCode) VALUES
    (1,'Navy Blue','#1e3a5f'),(1,'Cream Gold','#f5e6c8'),(1,'Maroon','#800000'),
    (1,'Royal Blue','#4169e1'),(1,'White','#ffffff'),(1,'Black','#000000');
END
GO

/*---------- Alter tblProducts ----------*/
IF COL_LENGTH('tblProducts','CategoryID') IS NULL
    ALTER TABLE tblProducts ADD CategoryID INT NULL;
IF COL_LENGTH('tblProducts','SizeID') IS NULL
    ALTER TABLE tblProducts ADD SizeID INT NULL;
IF COL_LENGTH('tblProducts','ColorID') IS NULL
    ALTER TABLE tblProducts ADD ColorID INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Products_Category')
    ALTER TABLE tblProducts ADD CONSTRAINT FK_Products_Category FOREIGN KEY(CategoryID) REFERENCES tblCategory(CategoryID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Products_Size')
    ALTER TABLE tblProducts ADD CONSTRAINT FK_Products_Size FOREIGN KEY(SizeID) REFERENCES tblSize(SizeID);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Products_Color')
    ALTER TABLE tblProducts ADD CONSTRAINT FK_Products_Color FOREIGN KEY(ColorID) REFERENCES tblColor(ColorID);
GO

-- Sync existing text fields to master IDs
UPDATE P SET CategoryID = C.CategoryID
FROM tblProducts P INNER JOIN tblCategory C ON P.CategoryName = C.CategoryName AND C.IsDeleted = 0
WHERE P.CategoryID IS NULL AND P.CategoryName IS NOT NULL;

UPDATE P SET SizeID = S.SizeID
FROM tblProducts P INNER JOIN tblSize S ON P.Size = S.SizeName AND S.IsDeleted = 0
WHERE P.SizeID IS NULL AND P.Size IS NOT NULL;

UPDATE P SET ColorID = CL.ColorID
FROM tblProducts P INNER JOIN tblColor CL ON P.Color = CL.ColorName AND CL.IsDeleted = 0
WHERE P.ColorID IS NULL AND P.Color IS NOT NULL;
GO

/***************************************************************
 CATEGORY SPs
***************************************************************/
CREATE OR ALTER PROCEDURE SP_GetAllCategories @CompanyID INT = NULL
AS BEGIN SET NOCOUNT ON;
    SELECT CategoryID, CompanyID, CategoryName, Description, IsActive, CreatedDate
    FROM tblCategory WHERE IsDeleted = 0 AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
    ORDER BY CategoryName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCategoryByID @CategoryID INT
AS BEGIN SET NOCOUNT ON;
    SELECT * FROM tblCategory WHERE CategoryID = @CategoryID AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertCategory
    @CompanyID INT, @CategoryName VARCHAR(100), @Description NVARCHAR(500)=NULL, @CreatedBy INT=NULL
AS BEGIN TRY
    INSERT INTO tblCategory(CompanyID, CategoryName, Description, CreatedBy)
    VALUES(@CompanyID, @CategoryName, @Description, @CreatedBy);
    SELECT 1 AS Success, 'Category added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_UpdateCategory
    @CategoryID INT, @CategoryName VARCHAR(100), @Description NVARCHAR(500)=NULL, @IsActive BIT=1, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblCategory SET CategoryName=@CategoryName, Description=@Description, IsActive=@IsActive,
        ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE CategoryID=@CategoryID;
    SELECT 1 AS Success, 'Category updated' AS Message, @CategoryID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_DeleteCategory @CategoryID INT, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblCategory SET IsDeleted=1, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE CategoryID=@CategoryID;
    SELECT 1 AS Success, 'Category deleted' AS Message, @CategoryID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

/***************************************************************
 SIZE SPs
***************************************************************/
CREATE OR ALTER PROCEDURE SP_GetAllSizes @CompanyID INT = NULL
AS BEGIN SET NOCOUNT ON;
    SELECT SizeID, CompanyID, SizeName, SizeCode, SortOrder, IsActive, CreatedDate
    FROM tblSize WHERE IsDeleted = 0 AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
    ORDER BY SortOrder, SizeName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetSizeByID @SizeID INT
AS BEGIN SELECT * FROM tblSize WHERE SizeID=@SizeID AND IsDeleted=0; END
GO

CREATE OR ALTER PROCEDURE SP_InsertSize
    @CompanyID INT, @SizeName VARCHAR(50), @SizeCode VARCHAR(20)=NULL, @SortOrder INT=0, @CreatedBy INT=NULL
AS BEGIN TRY
    INSERT INTO tblSize(CompanyID, SizeName, SizeCode, SortOrder, CreatedBy)
    VALUES(@CompanyID, @SizeName, @SizeCode, @SortOrder, @CreatedBy);
    SELECT 1 AS Success, 'Size added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_UpdateSize
    @SizeID INT, @SizeName VARCHAR(50), @SizeCode VARCHAR(20)=NULL, @SortOrder INT=0, @IsActive BIT=1, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblSize SET SizeName=@SizeName, SizeCode=@SizeCode, SortOrder=@SortOrder, IsActive=@IsActive,
        ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE SizeID=@SizeID;
    SELECT 1 AS Success, 'Size updated' AS Message, @SizeID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_DeleteSize @SizeID INT, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblSize SET IsDeleted=1, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE SizeID=@SizeID;
    SELECT 1 AS Success, 'Size deleted' AS Message, @SizeID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

/***************************************************************
 COLOR SPs
***************************************************************/
CREATE OR ALTER PROCEDURE SP_GetAllColors @CompanyID INT = NULL
AS BEGIN SET NOCOUNT ON;
    SELECT ColorID, CompanyID, ColorName, ColorCode, IsActive, CreatedDate
    FROM tblColor WHERE IsDeleted = 0 AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
    ORDER BY ColorName;
END
GO

CREATE OR ALTER PROCEDURE SP_GetColorByID @ColorID INT
AS BEGIN SELECT * FROM tblColor WHERE ColorID=@ColorID AND IsDeleted=0; END
GO

CREATE OR ALTER PROCEDURE SP_InsertColor
    @CompanyID INT, @ColorName VARCHAR(100), @ColorCode VARCHAR(20)=NULL, @CreatedBy INT=NULL
AS BEGIN TRY
    INSERT INTO tblColor(CompanyID, ColorName, ColorCode, CreatedBy)
    VALUES(@CompanyID, @ColorName, @ColorCode, @CreatedBy);
    SELECT 1 AS Success, 'Color added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_UpdateColor
    @ColorID INT, @ColorName VARCHAR(100), @ColorCode VARCHAR(20)=NULL, @IsActive BIT=1, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblColor SET ColorName=@ColorName, ColorCode=@ColorCode, IsActive=@IsActive,
        ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE ColorID=@ColorID;
    SELECT 1 AS Success, 'Color updated' AS Message, @ColorID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_DeleteColor @ColorID INT, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblColor SET IsDeleted=1, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE ColorID=@ColorID;
    SELECT 1 AS Success, 'Color deleted' AS Message, @ColorID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

/***************************************************************
 PRODUCT SPs (full CRUD with joins)
***************************************************************/
CREATE OR ALTER PROCEDURE SP_GetAllProducts @CompanyID INT = NULL
AS BEGIN SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage,
           P.IsAvailable, P.NextAvailableDate, P.CreatedDate
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    WHERE P.IsDeleted = 0 AND (@CompanyID IS NULL OR P.CompanyID = @CompanyID)
    ORDER BY P.ProductID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductByID @ProductID INT
AS BEGIN SET NOCOUNT ON;
    SELECT P.*, C.CategoryName, S.SizeName, CL.ColorName
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    WHERE P.ProductID = @ProductID AND P.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductByCode @ProductCode VARCHAR(50)
AS BEGIN SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage, P.IsAvailable, P.NextAvailableDate
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    WHERE P.ProductCode = @ProductCode AND P.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertProduct
    @CompanyID INT, @ProductCode VARCHAR(50), @ProductName VARCHAR(200),
    @CategoryID INT, @SizeID INT, @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, @RentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, @StandardRentalDays INT=4, @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL, @CreatedBy INT=NULL
AS BEGIN TRY
    DECLARE @CatName VARCHAR(100), @SizeName VARCHAR(50), @ColorName VARCHAR(50);
    SELECT @CatName = CategoryName FROM tblCategory WHERE CategoryID = @CategoryID;
    SELECT @SizeName = SizeName FROM tblSize WHERE SizeID = @SizeID;
    SELECT @ColorName = ColorName FROM tblColor WHERE ColorID = @ColorID;

    INSERT INTO tblProducts(CompanyID, ProductCode, ProductName, CategoryID, CategoryName, SizeID, Size, ColorID, Color,
        AgeGroup, RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay,
        AvailableQuantity, Description, ProductImage, CreatedBy)
    VALUES(@CompanyID, @ProductCode, @ProductName, @CategoryID, @CatName, @SizeID, @SizeName, @ColorID, @ColorName,
        @AgeGroup, @RentAmount, @DepositAmount, @DiscountPercent, @StandardRentalDays, @ExtraChargePerDay,
        @AvailableQuantity, @Description, @ProductImage, @CreatedBy);
    SELECT 1 AS Success, 'Product added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_UpdateProduct
    @ProductID INT, @ProductCode VARCHAR(50), @ProductName VARCHAR(200),
    @CategoryID INT, @SizeID INT, @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, @RentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, @StandardRentalDays INT=4, @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL,
    @IsAvailable BIT=1, @ModifiedBy INT=NULL
AS BEGIN TRY
    DECLARE @CatName VARCHAR(100), @SizeName VARCHAR(50), @ColorName VARCHAR(50);
    SELECT @CatName = CategoryName FROM tblCategory WHERE CategoryID = @CategoryID;
    SELECT @SizeName = SizeName FROM tblSize WHERE SizeID = @SizeID;
    SELECT @ColorName = ColorName FROM tblColor WHERE ColorID = @ColorID;

    UPDATE tblProducts SET
        ProductCode=@ProductCode, ProductName=@ProductName,
        CategoryID=@CategoryID, CategoryName=@CatName, SizeID=@SizeID, Size=@SizeName,
        ColorID=@ColorID, Color=@ColorName, AgeGroup=@AgeGroup,
        RentAmount=@RentAmount, DepositAmount=@DepositAmount, DiscountPercent=@DiscountPercent,
        StandardRentalDays=@StandardRentalDays, ExtraChargePerDay=@ExtraChargePerDay,
        AvailableQuantity=@AvailableQuantity, Description=@Description, ProductImage=@ProductImage,
        IsAvailable=@IsAvailable, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy
    WHERE ProductID = @ProductID;
    SELECT 1 AS Success, 'Product updated' AS Message, @ProductID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

CREATE OR ALTER PROCEDURE SP_DeleteProduct @ProductID INT, @ModifiedBy INT=NULL
AS BEGIN TRY
    UPDATE tblProducts SET IsDeleted=1, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy WHERE ProductID=@ProductID;
    SELECT 1 AS Success, 'Product deleted' AS Message, @ProductID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH END
GO

PRINT 'Masters migration completed.';
GO
