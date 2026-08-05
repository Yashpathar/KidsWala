/* Optional: align SP_UpdateProduct on server (API fix removes extra @CompanyID from C# call).
   Run only if you prefer CompanyID on update. Default migration SP is correct without CompanyID. */
USE DB_A6B32D_LabelManagement;
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
