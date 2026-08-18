/* Run this script in SQL Server Management Studio (SSMS) on database: DB_A6B32D_LabelManagement */

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_InsertProduct
    @CompanyID INT, 
    @BranchID INT = NULL, 
    @ProductCode VARCHAR(50), 
    @ProductName VARCHAR(200),
    @CategoryID INT, 
    @SizeID INT, 
    @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, 
    @RentAmount DECIMAL(18,2), 
    @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, 
    @StandardRentalDays INT=4, 
    @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, 
    @Description NVARCHAR(MAX)=NULL, 
    @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, 
    @TopCode VARCHAR(50)=NULL, 
    @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, 
    @BottomSize VARCHAR(50)=NULL, 
    @CreatedBy INT=NULL
AS 
BEGIN TRY
    DECLARE @CatName VARCHAR(100), @SizeName VARCHAR(50), @ColorName VARCHAR(50);
    SELECT @CatName = CategoryName FROM tblCategory WHERE CategoryID = @CategoryID;
    SELECT @SizeName = SizeName FROM tblSize WHERE SizeID = @SizeID;
    SELECT @ColorName = ColorName FROM tblColor WHERE ColorID = @ColorID;

    INSERT INTO tblProducts(CompanyID, BranchID, ProductCode, ProductName, CategoryID, CategoryName, SizeID, Size, ColorID, Color,
        AgeGroup, RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay,
        AvailableQuantity, Description, ProductImage, IsFullSet, TopCode, TopSize, BottomCode, BottomSize, CreatedBy)
    VALUES(@CompanyID, @BranchID, @ProductCode, @ProductName, @CategoryID, @CatName, @SizeID, @SizeName, @ColorID, @ColorName,
        @AgeGroup, @RentAmount, @DepositAmount, @DiscountPercent, @StandardRentalDays, @ExtraChargePerDay,
        @AvailableQuantity, @Description, @ProductImage, @IsFullSet, @TopCode, @TopSize, @BottomCode, @BottomSize, @CreatedBy);
    SELECT 1 AS Success, 'Product added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY 
BEGIN CATCH 
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; 
END CATCH
GO

CREATE OR ALTER PROCEDURE SP_UpdateProduct
    @ProductID INT, 
    @BranchID INT = NULL, 
    @ProductCode VARCHAR(50), 
    @ProductName VARCHAR(200),
    @CategoryID INT, 
    @SizeID INT, 
    @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, 
    @RentAmount DECIMAL(18,2), 
    @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, 
    @StandardRentalDays INT=4, 
    @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, 
    @Description NVARCHAR(MAX)=NULL, 
    @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, 
    @TopCode VARCHAR(50)=NULL, 
    @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, 
    @BottomSize VARCHAR(50)=NULL,
    @IsAvailable BIT=1, 
    @ModifiedBy INT=NULL
AS 
BEGIN TRY
    DECLARE @CatName VARCHAR(100), @SizeName VARCHAR(50), @ColorName VARCHAR(50);
    SELECT @CatName = CategoryName FROM tblCategory WHERE CategoryID = @CategoryID;
    SELECT @SizeName = SizeName FROM tblSize WHERE SizeID = @SizeID;
    SELECT @ColorName = ColorName FROM tblColor WHERE ColorID = @ColorID;

    UPDATE tblProducts SET
        BranchID=ISNULL(@BranchID, BranchID), ProductCode=@ProductCode, ProductName=@ProductName,
        CategoryID=@CategoryID, CategoryName=@CatName, SizeID=@SizeID, Size=@SizeName,
        ColorID=@ColorID, Color=@ColorName, AgeGroup=@AgeGroup,
        RentAmount=@RentAmount, DepositAmount=@DepositAmount, DiscountPercent=@DiscountPercent,
        StandardRentalDays=@StandardRentalDays, ExtraChargePerDay=@ExtraChargePerDay,
        AvailableQuantity=@AvailableQuantity, Description=@Description, ProductImage=@ProductImage,
        IsFullSet=@IsFullSet, TopCode=@TopCode, TopSize=@TopSize, BottomCode=@BottomCode, BottomSize=@BottomSize,
        IsAvailable=@IsAvailable, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy
    WHERE ProductID = @ProductID;
    SELECT 1 AS Success, 'Product updated' AS Message, @ProductID AS ID;
END TRY 
BEGIN CATCH 
    SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; 
END CATCH
GO
