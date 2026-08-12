-- Branch-wise Product Stored Procedure Enhancements
-- Allows filtering, creating, and updating products by BranchID

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_GetAllProducts 
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.BranchID, BR.BranchName, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage,
           P.IsAvailable, P.NextAvailableDate, P.CreatedDate,
           ISNULL(P.IsFullSet, 0) AS IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    LEFT JOIN tblBranch BR ON P.BranchID = BR.BranchID
    WHERE P.IsDeleted = 0 
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR P.BranchID = @BranchID)
    ORDER BY P.ProductID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductByID @ProductID INT
AS 
BEGIN 
    SET NOCOUNT ON;
    SELECT P.*, BR.BranchName, C.CategoryName, S.SizeName, CL.ColorName
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    LEFT JOIN tblBranch BR ON P.BranchID = BR.BranchID
    WHERE P.ProductID = @ProductID AND P.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductByCode 
    @ProductCode VARCHAR(50),
    @BranchID INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.BranchID, BR.BranchName, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage, P.IsAvailable, P.NextAvailableDate,
           ISNULL(P.IsFullSet, 0) AS IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    LEFT JOIN tblBranch BR ON P.BranchID = BR.BranchID
    WHERE P.ProductCode = @ProductCode AND P.IsDeleted = 0
      AND (@BranchID IS NULL OR @BranchID = 0 OR P.BranchID = @BranchID);
END
GO

CREATE OR ALTER PROCEDURE SP_InsertProduct
    @CompanyID INT, @BranchID INT = NULL, @ProductCode VARCHAR(50), @ProductName VARCHAR(200),
    @CategoryID INT, @SizeID INT, @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, @RentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, @StandardRentalDays INT=4, @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, @TopCode VARCHAR(50)=NULL, @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, @BottomSize VARCHAR(50)=NULL, @CreatedBy INT=NULL
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
    @ProductID INT, @BranchID INT = NULL, @ProductCode VARCHAR(50), @ProductName VARCHAR(200),
    @CategoryID INT, @SizeID INT, @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, @RentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, @StandardRentalDays INT=4, @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, @TopCode VARCHAR(50)=NULL, @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, @BottomSize VARCHAR(50)=NULL,
    @IsAvailable BIT=1, @ModifiedBy INT=NULL
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
