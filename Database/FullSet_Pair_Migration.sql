USE DB_A6B32D_LabelManagement;
GO

-- 1. Add Full Set / Pair columns to tblProducts if they don't exist
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblProducts') AND name = 'IsFullSet')
BEGIN
    ALTER TABLE tblProducts ADD IsFullSet BIT NOT NULL DEFAULT 0;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblProducts') AND name = 'TopCode')
BEGIN
    ALTER TABLE tblProducts ADD TopCode VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblProducts') AND name = 'TopSize')
BEGIN
    ALTER TABLE tblProducts ADD TopSize VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblProducts') AND name = 'BottomCode')
BEGIN
    ALTER TABLE tblProducts ADD BottomCode VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblProducts') AND name = 'BottomSize')
BEGIN
    ALTER TABLE tblProducts ADD BottomSize VARCHAR(50) NULL;
END
GO

-- 2. Add Full Set / Pair columns to tblBookingDetails if they don't exist
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblBookingDetails') AND name = 'IsFullSet')
BEGIN
    ALTER TABLE tblBookingDetails ADD IsFullSet BIT NOT NULL DEFAULT 0;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblBookingDetails') AND name = 'TopCode')
BEGIN
    ALTER TABLE tblBookingDetails ADD TopCode VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblBookingDetails') AND name = 'TopSize')
BEGIN
    ALTER TABLE tblBookingDetails ADD TopSize VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblBookingDetails') AND name = 'BottomCode')
BEGIN
    ALTER TABLE tblBookingDetails ADD BottomCode VARCHAR(50) NULL;
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('tblBookingDetails') AND name = 'BottomSize')
BEGIN
    ALTER TABLE tblBookingDetails ADD BottomSize VARCHAR(50) NULL;
END
GO

-- 3. Product SPs Update
CREATE OR ALTER PROCEDURE SP_GetAllProducts @CompanyID INT = NULL
AS BEGIN SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage,
           P.IsAvailable, P.NextAvailableDate, P.CreatedDate,
           ISNULL(P.IsFullSet, 0) AS IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize
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
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage, P.IsAvailable, P.NextAvailableDate,
           ISNULL(P.IsFullSet, 0) AS IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize
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
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, @TopCode VARCHAR(50)=NULL, @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, @BottomSize VARCHAR(50)=NULL, @CreatedBy INT=NULL
AS BEGIN TRY
    DECLARE @CatName VARCHAR(100), @SizeName VARCHAR(50), @ColorName VARCHAR(50);
    SELECT @CatName = CategoryName FROM tblCategory WHERE CategoryID = @CategoryID;
    SELECT @SizeName = SizeName FROM tblSize WHERE SizeID = @SizeID;
    SELECT @ColorName = ColorName FROM tblColor WHERE ColorID = @ColorID;

    INSERT INTO tblProducts(CompanyID, ProductCode, ProductName, CategoryID, CategoryName, SizeID, Size, ColorID, Color,
        AgeGroup, RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay,
        AvailableQuantity, Description, ProductImage, IsFullSet, TopCode, TopSize, BottomCode, BottomSize, CreatedBy)
    VALUES(@CompanyID, @ProductCode, @ProductName, @CategoryID, @CatName, @SizeID, @SizeName, @ColorID, @ColorName,
        @AgeGroup, @RentAmount, @DepositAmount, @DiscountPercent, @StandardRentalDays, @ExtraChargePerDay,
        @AvailableQuantity, @Description, @ProductImage, @IsFullSet, @TopCode, @TopSize, @BottomCode, @BottomSize, @CreatedBy);
    SELECT 1 AS Success, 'Product added' AS Message, SCOPE_IDENTITY() AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH
GO

CREATE OR ALTER PROCEDURE SP_UpdateProduct
    @ProductID INT, @ProductCode VARCHAR(50), @ProductName VARCHAR(200),
    @CategoryID INT, @SizeID INT, @ColorID INT,
    @AgeGroup VARCHAR(50)=NULL, @RentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2),
    @DiscountPercent DECIMAL(18,2)=0, @StandardRentalDays INT=4, @ExtraChargePerDay DECIMAL(18,2)=150,
    @AvailableQuantity INT=1, @Description NVARCHAR(MAX)=NULL, @ProductImage NVARCHAR(MAX)=NULL,
    @IsFullSet BIT=0, @TopCode VARCHAR(50)=NULL, @TopSize VARCHAR(50)=NULL,
    @BottomCode VARCHAR(50)=NULL, @BottomSize VARCHAR(50)=NULL,
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
        IsFullSet=@IsFullSet, TopCode=@TopCode, TopSize=@TopSize, BottomCode=@BottomCode, BottomSize=@BottomSize,
        IsAvailable=@IsAvailable, ModifiedDate=GETDATE(), ModifiedBy=@ModifiedBy
    WHERE ProductID = @ProductID;
    SELECT 1 AS Success, 'Product updated' AS Message, @ProductID AS ID;
END TRY BEGIN CATCH SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; END CATCH
GO

-- 4. Update SP_AddBooking
CREATE OR ALTER PROCEDURE SP_AddBooking
    @CompanyID INT, @BookingNo VARCHAR(50), @CustomerID INT, @BookingCreatedBy INT,
    @BookingDate DATE, @StartDate DATE, @EndDate DATE, @DeliveryDate DATE, @ReturnDate DATE,
    @RentDays INT, @TotalRentAmount DECIMAL(18,2), @DiscountAmount DECIMAL(18,2),
    @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2), @RemainingAmount DECIMAL(18,2),
    @TotalAmount DECIMAL(18,2), @ExtraChargePerDay DECIMAL(18,2), @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX), @BookingDetailsJson NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO tblBookings(CompanyID,BookingNo,CustomerID,BookingCreatedBy,BookingDate,StartDate,EndDate,
            DeliveryDate,ReturnDate,RentDays,TotalRentAmount,DiscountAmount,DepositAmount,AdvanceAmount,
            RemainingAmount,TotalAmount,ExtraChargePerDay,BookingStatus,PaymentStatus,Notes)
        VALUES(@CompanyID,@BookingNo,@CustomerID,@BookingCreatedBy,@BookingDate,@StartDate,@EndDate,
            @DeliveryDate,@ReturnDate,@RentDays,@TotalRentAmount,@DiscountAmount,@DepositAmount,@AdvanceAmount,
            @RemainingAmount,@TotalAmount,@ExtraChargePerDay,@BookingStatus,@PaymentStatus,@Notes);

        DECLARE @BookingID INT = SCOPE_IDENTITY();

        INSERT INTO tblBookingDetails(
            BookingID, ProductID, ProductCode, ProductName, Size, Color,
            RentAmount, DepositAmount, DiscountPercent, FinalRentAmount,
            IsFullSet, TopCode, TopSize, BottomCode, BottomSize
        )
        SELECT @BookingID,
            COALESCE(j.ProductID, j.productID),
            COALESCE(j.ProductCode, j.productCode),
            COALESCE(j.ProductName, j.productName),
            COALESCE(j.Size, j.size),
            COALESCE(j.Color, j.color),
            COALESCE(j.RentAmount, j.rentAmount),
            COALESCE(j.DepositAmount, j.depositAmount),
            COALESCE(j.DiscountPercent, j.discountPercent),
            COALESCE(j.FinalRentAmount, j.finalRentAmount),
            ISNULL(COALESCE(j.IsFullSet, j.isFullSet), 0),
            COALESCE(j.TopCode, j.topCode),
            COALESCE(j.TopSize, j.topSize),
            COALESCE(j.BottomCode, j.bottomCode),
            COALESCE(j.BottomSize, j.bottomSize)
        FROM OPENJSON(@BookingDetailsJson)
        WITH (
            ProductID INT '$.ProductID', productID INT '$.productID',
            ProductCode VARCHAR(50) '$.ProductCode', productCode VARCHAR(50) '$.productCode',
            ProductName VARCHAR(200) '$.ProductName', productName VARCHAR(200) '$.productName',
            Size VARCHAR(50) '$.Size', size VARCHAR(50) '$.size',
            Color VARCHAR(50) '$.Color', color VARCHAR(50) '$.color',
            RentAmount DECIMAL(18,2) '$.RentAmount', rentAmount DECIMAL(18,2) '$.rentAmount',
            DepositAmount DECIMAL(18,2) '$.DepositAmount', depositAmount DECIMAL(18,2) '$.depositAmount',
            DiscountPercent DECIMAL(18,2) '$.DiscountPercent', discountPercent DECIMAL(18,2) '$.discountPercent',
            FinalRentAmount DECIMAL(18,2) '$.FinalRentAmount', finalRentAmount DECIMAL(18,2) '$.finalRentAmount',
            IsFullSet BIT '$.IsFullSet', isFullSet BIT '$.isFullSet',
            TopCode VARCHAR(50) '$.TopCode', topCode VARCHAR(50) '$.topCode',
            TopSize VARCHAR(50) '$.TopSize', topSize VARCHAR(50) '$.topSize',
            BottomCode VARCHAR(50) '$.BottomCode', bottomCode VARCHAR(50) '$.bottomCode',
            BottomSize VARCHAR(50) '$.BottomSize', bottomSize VARCHAR(50) '$.bottomSize'
        ) j;

        UPDATE P SET IsAvailable = 0, CurrentBookingID = @BookingID, NextAvailableDate = DATEADD(DAY,1,@ReturnDate)
        FROM tblProducts P
        INNER JOIN tblBookingDetails BD ON P.ProductID = BD.ProductID
        WHERE BD.BookingID = @BookingID;

        INSERT INTO tblNotifications(CompanyID,Title,Message,NotificationType,ReferenceID,UserID)
        VALUES(@CompanyID,'New Booking','Booking '+@BookingNo+' created','Booking',@BookingID,@BookingCreatedBy);

        COMMIT;
        SELECT 1 AS Success, 'Booking Added Successfully' AS Message, @BookingID AS ID, @BookingNo AS BookingNo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID, '' AS BookingNo;
    END CATCH
END
GO
