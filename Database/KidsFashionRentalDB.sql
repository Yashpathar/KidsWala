/*==============================================================
 DATABASE : DB_A6B32D_LabelManagement (Kids Fashion Rental)
 Run on: SQL5053.site4now.net
==============================================================*/
-- USE master; CREATE DATABASE DB_A6B32D_LabelManagement;
USE DB_A6B32D_LabelManagement;
GO

IF OBJECT_ID('tblRole','U') IS NULL
BEGIN
CREATE TABLE tblRole
(
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName VARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);
INSERT INTO tblRole(RoleName,Description) VALUES
('Super Admin','Full Access'),('Admin','Booking Access'),('Accountant','Payment Access');
END
GO

IF OBJECT_ID('tblCompany','U') IS NULL
BEGIN
CREATE TABLE tblCompany
(
    CompanyID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyName VARCHAR(200) NOT NULL,
    CompanyCode VARCHAR(50),
    BusinessType VARCHAR(100),
    Address NVARCHAR(MAX),
    MobileNo VARCHAR(20),
    Email VARCHAR(200),
    GSTNo VARCHAR(100),
    LogoImage NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);
INSERT INTO tblCompany(CompanyName,CompanyCode,BusinessType,Address,MobileNo,Email,GSTNo) VALUES
('Kids Walla Nikol','KWN','Children Wear','Nikol Ahmedabad','9999991111','nikol@kidswalla.com','GSTKWN001'),
('Kids Walla Chandlodiya','KWC','Children Wear','Chandlodiya Ahmedabad','9999992222','chandlodiya@kidswalla.com','GSTKWC002');
END
GO

IF OBJECT_ID('tblUsers','U') IS NULL
BEGIN
CREATE TABLE tblUsers
(
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    RoleID INT,
    CompanyID INT NULL,
    FullName VARCHAR(200),
    UserName VARCHAR(100) UNIQUE,
    Email VARCHAR(200),
    MobileNo VARCHAR(20),
    PasswordHash NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    LastLoginDate DATETIME NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY(RoleID) REFERENCES tblRole(RoleID),
    FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
);
-- Password: admin123 (BCrypt hash placeholder - update via API)
INSERT INTO tblUsers(RoleID,CompanyID,FullName,UserName,Email,MobileNo,PasswordHash) VALUES
(1,1,'Super Admin','admin','admin@gmail.com','9999999999','$2a$11$K3VqJ8xY5mN0pL9rT2uW3eH4fG6jK8lM0nP1qR2sT3uV4wX5yZ6a'),
(2,1,'Booking Admin','bookingadmin','booking@gmail.com','8888888888','$2a$11$K3VqJ8xY5mN0pL9rT2uW3eH4fG6jK8lM0nP1qR2sT3uV4wX5yZ6a');
END
GO

IF OBJECT_ID('tblProducts','U') IS NULL
BEGIN
CREATE TABLE tblProducts
(
    ProductID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NULL,
    ProductCode VARCHAR(50) UNIQUE,
    ProductName VARCHAR(200),
    CategoryName VARCHAR(100),
    Size VARCHAR(50),
    Color VARCHAR(50),
    AgeGroup VARCHAR(50),
    RentAmount DECIMAL(18,2),
    DepositAmount DECIMAL(18,2),
    DiscountPercent DECIMAL(18,2) DEFAULT 0,
    StandardRentalDays INT DEFAULT 4,
    ExtraChargePerDay DECIMAL(18,2) DEFAULT 150,
    AvailableQuantity INT DEFAULT 1,
    Description NVARCHAR(MAX),
    ProductImage NVARCHAR(MAX),
    IsAvailable BIT DEFAULT 1,
    CurrentBookingID INT NULL,
    NextAvailableDate DATE NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
);
INSERT INTO tblProducts(CompanyID,ProductCode,ProductName,CategoryName,Size,Color,AgeGroup,RentAmount,DepositAmount,StandardRentalDays,ExtraChargePerDay,Description) VALUES
(1,'BL-02','Blazer Premium Blue','Blazer','32','Navy Blue','8-10 Years',500,1000,4,150,'Premium Blue Blazer'),
(1,'SW-01','Royal Sherwani','Sherwani','34','Cream Gold','10-12 Years',1200,2500,5,250,'Royal Wedding Sherwani'),
(1,'IW-01','Indo Western Gold','Indo Western','30','Gold','6-8 Years',800,1500,4,200,'Party Indo Western');
END
GO

IF OBJECT_ID('tblCustomers','U') IS NULL
BEGIN
CREATE TABLE tblCustomers
(
    CustomerID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NULL,
    FullName VARCHAR(200),
    ContactNo1 VARCHAR(20),
    ContactNo2 VARCHAR(20),
    Address NVARCHAR(MAX),
    City VARCHAR(100),
    Notes NVARCHAR(MAX),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
);
INSERT INTO tblCustomers(CompanyID,FullName,ContactNo1,ContactNo2,Address,City,Notes) VALUES
(1,'Rahul Sharma','9876543210','9723456789','Bopal Road Ahmedabad','Ahmedabad','VIP Customer'),
(1,'Amit Patel','9999999990','8888888880','Satellite Ahmedabad','Ahmedabad','Regular Customer');
END
GO

IF OBJECT_ID('tblBookings','U') IS NULL
BEGIN
CREATE TABLE tblBookings
(
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NULL,
    BookingNo VARCHAR(50) UNIQUE,
    CustomerID INT,
    BookingCreatedBy INT,
    BookingDate DATE,
    StartDate DATE,
    EndDate DATE,
    DeliveryDate DATE,
    ReturnDate DATE,
    ActualReturnDate DATE NULL,
    RentDays INT DEFAULT 0,
    ExtraDays INT DEFAULT 0,
    ExtraChargePerDay DECIMAL(18,2) DEFAULT 0,
    ExtraChargeAmount DECIMAL(18,2) DEFAULT 0,
    DamageDeductionAmount DECIMAL(18,2) DEFAULT 0,
    TotalRentAmount DECIMAL(18,2) DEFAULT 0,
    DiscountAmount DECIMAL(18,2) DEFAULT 0,
    DepositAmount DECIMAL(18,2) DEFAULT 0,
    AdvanceAmount DECIMAL(18,2) DEFAULT 0,
    RemainingAmount DECIMAL(18,2) DEFAULT 0,
    FinalRefundAmount DECIMAL(18,2) DEFAULT 0,
    FinalProfitAmount DECIMAL(18,2) DEFAULT 0,
    TotalAmount DECIMAL(18,2) DEFAULT 0,
    BookingStatus VARCHAR(50) DEFAULT 'Booked',
    PaymentStatus VARCHAR(50) DEFAULT 'Pending',
    Notes NVARCHAR(MAX),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0,
    FOREIGN KEY(CustomerID) REFERENCES tblCustomers(CustomerID),
    FOREIGN KEY(BookingCreatedBy) REFERENCES tblUsers(UserID),
    FOREIGN KEY(CompanyID) REFERENCES tblCompany(CompanyID)
);
END
GO

IF OBJECT_ID('tblBookingDetails','U') IS NULL
BEGIN
CREATE TABLE tblBookingDetails
(
    BookingDetailID INT IDENTITY(1,1) PRIMARY KEY,
    BookingID INT,
    ProductID INT,
    ProductCode VARCHAR(50),
    ProductName VARCHAR(200),
    Size VARCHAR(50),
    Color VARCHAR(50),
    RentAmount DECIMAL(18,2),
    DepositAmount DECIMAL(18,2),
    DiscountPercent DECIMAL(18,2),
    FinalRentAmount DECIMAL(18,2),
    CreatedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY(BookingID) REFERENCES tblBookings(BookingID),
    FOREIGN KEY(ProductID) REFERENCES tblProducts(ProductID)
);
END
GO

IF OBJECT_ID('tblPayments','U') IS NULL
BEGIN
CREATE TABLE tblPayments
(
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NULL,
    BookingID INT,
    PaymentType VARCHAR(50),
    PaymentMode VARCHAR(50),
    PaymentAmount DECIMAL(18,2),
    TransactionNo VARCHAR(200),
    PaymentDate DATETIME DEFAULT GETDATE(),
    Notes NVARCHAR(MAX),
    CreatedBy INT NULL,
    FOREIGN KEY(BookingID) REFERENCES tblBookings(BookingID)
);
END
GO

IF OBJECT_ID('tblNotifications','U') IS NULL
BEGIN
CREATE TABLE tblNotifications
(
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    CompanyID INT NULL,
    Title VARCHAR(250),
    Message NVARCHAR(MAX),
    NotificationType VARCHAR(100),
    ReferenceID INT NULL,
    UserID INT NULL,
    IsRead BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsDeleted BIT DEFAULT 0
);
END
GO

/* LOGIN */
CREATE OR ALTER PROCEDURE SP_UserLogin
    @UserName VARCHAR(100),
    @Password VARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.RoleID, U.CompanyID, U.FullName, U.UserName, U.Email, U.MobileNo, U.PasswordHash,
           R.RoleName, C.CompanyName
    FROM tblUsers U
    INNER JOIN tblRole R ON U.RoleID = R.RoleID
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    WHERE U.UserName = @UserName AND U.IsActive = 1 AND U.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllProducts
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM tblProducts
    WHERE IsDeleted = 0 AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
    ORDER BY ProductID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductByCode
    @ProductCode VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 * FROM tblProducts WHERE ProductCode = @ProductCode AND IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllCustomers
    @CompanyID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM tblCustomers
    WHERE IsDeleted = 0 AND (@CompanyID IS NULL OR CompanyID = @CompanyID)
    ORDER BY CustomerID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertCustomer
    @CompanyID INT, @FullName VARCHAR(200), @ContactNo1 VARCHAR(20), @ContactNo2 VARCHAR(20),
    @Address NVARCHAR(MAX), @City VARCHAR(100), @Notes NVARCHAR(MAX), @CreatedBy INT = NULL
AS
BEGIN
    INSERT INTO tblCustomers(CompanyID,FullName,ContactNo1,ContactNo2,Address,City,Notes)
    VALUES(@CompanyID,@FullName,@ContactNo1,@ContactNo2,@Address,@City,@Notes);
    SELECT 1 AS Success, 'Customer Added' AS Message, SCOPE_IDENTITY() AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_CheckProductAvailability
    @ProductCode VARCHAR(50),
    @DeliveryDate DATE,
    @ReturnDate DATE,
    @ExcludeBookingID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM tblBookingDetails BD
        INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
        INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
        WHERE BD.ProductCode = @ProductCode
          AND B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND (@ExcludeBookingID IS NULL OR B.BookingID <> @ExcludeBookingID)
          AND NOT (@ReturnDate < B.DeliveryDate OR @DeliveryDate > B.ReturnDate)
    )
    BEGIN
        SELECT TOP 1
            0 AS Success,
            'Product Already Booked' AS Message,
            C.FullName AS CustomerName,
            B.DeliveryDate AS deliveryDate,
            B.ReturnDate AS returnDate,
            DATEADD(DAY,1,B.ReturnDate) AS nextAvailableDate
        FROM tblBookingDetails BD
        INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
        INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
        WHERE BD.ProductCode = @ProductCode
          AND B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND NOT (@ReturnDate < B.DeliveryDate OR @DeliveryDate > B.ReturnDate)
        ORDER BY B.ReturnDate DESC;
    END
    ELSE
        SELECT 1 AS Success, 'Product Available' AS Message,
               NULL AS CustomerName, NULL AS deliveryDate, NULL AS returnDate, @DeliveryDate AS nextAvailableDate;
END
GO

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

        INSERT INTO tblBookingDetails(BookingID,ProductID,ProductCode,ProductName,Size,Color,RentAmount,DepositAmount,DiscountPercent,FinalRentAmount)
        SELECT @BookingID, ProductID, ProductCode, ProductName, Size, Color, RentAmount, DepositAmount, DiscountPercent, FinalRentAmount
        FROM OPENJSON(@BookingDetailsJson)
        WITH (
            ProductID INT, ProductCode VARCHAR(50), ProductName VARCHAR(200), Size VARCHAR(50), Color VARCHAR(50),
            RentAmount DECIMAL(18,2), DepositAmount DECIMAL(18,2), DiscountPercent DECIMAL(18,2), FinalRentAmount DECIMAL(18,2)
        );

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

CREATE OR ALTER PROCEDURE SP_UpdateBooking
    @BookingID INT, @DeliveryDate DATE, @ReturnDate DATE, @RentDays INT,
    @TotalRentAmount DECIMAL(18,2), @DepositAmount DECIMAL(18,2), @AdvanceAmount DECIMAL(18,2),
    @RemainingAmount DECIMAL(18,2), @TotalAmount DECIMAL(18,2), @BookingStatus VARCHAR(50),
    @PaymentStatus VARCHAR(50), @Notes NVARCHAR(MAX)
AS
BEGIN
    UPDATE tblBookings SET
        DeliveryDate=@DeliveryDate, ReturnDate=@ReturnDate, RentDays=@RentDays,
        TotalRentAmount=@TotalRentAmount, DepositAmount=@DepositAmount, AdvanceAmount=@AdvanceAmount,
        RemainingAmount=@RemainingAmount, TotalAmount=@TotalAmount,
        BookingStatus=@BookingStatus, PaymentStatus=@PaymentStatus, Notes=@Notes
    WHERE BookingID=@BookingID;
    SELECT 1 AS Success, 'Booking Updated' AS Message, @BookingID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_ProcessReturn
    @BookingID INT, @ActualReturnDate DATE,
    @DamageDeductionAmount DECIMAL(18,2) = 0, @ReturnNotes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @ReturnDate DATE, @ExtraChargePerDay DECIMAL(18,2),
                @TotalRent DECIMAL(18,2), @Deposit DECIMAL(18,2), @ExtraDays INT = 0,
                @LateCharge DECIMAL(18,2) = 0, @Damage DECIMAL(18,2) = 0,
                @Refund DECIMAL(18,2), @Profit DECIMAL(18,2), @Status VARCHAR(50), @BookingStatus VARCHAR(50);

        SELECT @ReturnDate=ReturnDate, @ExtraChargePerDay=ISNULL(ExtraChargePerDay,0),
               @TotalRent=TotalRentAmount, @Deposit=DepositAmount, @BookingStatus=BookingStatus
        FROM tblBookings WHERE BookingID=@BookingID AND IsDeleted=0;

        IF @BookingStatus IS NULL BEGIN SELECT 0 AS Success, 'Booking not found' AS Message; ROLLBACK; RETURN; END
        IF @BookingStatus <> 'Delivered' BEGIN SELECT 0 AS Success, 'Only delivered bookings can be returned' AS Message; ROLLBACK; RETURN; END

        SET @Damage = CASE WHEN @DamageDeductionAmount<0 THEN 0 WHEN @DamageDeductionAmount>@Deposit THEN @Deposit ELSE @DamageDeductionAmount END;

        IF @ActualReturnDate > @ReturnDate
        BEGIN
            SET @ExtraDays = DATEDIFF(DAY, @ReturnDate, @ActualReturnDate);
            SET @LateCharge = @ExtraDays * @ExtraChargePerDay;
            SET @TotalRent = @TotalRent + @LateCharge;
            SET @Status = 'Late Returned';
        END
        ELSE SET @Status = 'Returned';

        SET @Refund = @Deposit - @LateCharge - @Damage;
        IF @Refund < 0 SET @Refund = 0;
        SET @Profit = @TotalRent;

        UPDATE tblBookings SET
            ActualReturnDate=@ActualReturnDate, ExtraDays=@ExtraDays, ExtraChargeAmount=@LateCharge,
            DamageDeductionAmount=@Damage, TotalRentAmount=@TotalRent, FinalRefundAmount=@Refund,
            FinalProfitAmount=@Profit, BookingStatus=@Status, PaymentStatus='Completed',
            Notes = CASE WHEN @ReturnNotes IS NOT NULL AND LTRIM(RTRIM(@ReturnNotes))<>'' THEN ISNULL(Notes+CHAR(10),'')+@ReturnNotes ELSE Notes END
        WHERE BookingID=@BookingID;

        UPDATE P SET IsAvailable=1, CurrentBookingID=NULL, NextAvailableDate=GETDATE()
        FROM tblProducts P
        INNER JOIN tblBookingDetails BD ON P.ProductID=BD.ProductID
        WHERE BD.BookingID=@BookingID;

        COMMIT;
        SELECT 1 AS Success, 'Return Processed' AS Message, @ExtraDays AS ExtraDays,
               @LateCharge AS ExtraChargeAmount, @Damage AS DamageDeductionAmount,
               @Refund AS FinalRefundAmount, @Profit AS FinalProfitAmount;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, @Search VARCHAR(100) = NULL, @Status VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount, B.DepositAmount, B.ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, B.DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR B.CompanyID = @CompanyID)
      AND (@Status IS NULL OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
    ORDER BY B.BookingID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetBookingByID @BookingID INT
AS
BEGIN
    SELECT B.*, C.FullName AS CustomerName, C.ContactNo1, C.ContactNo2, C.Address, C.City,
           U.FullName AS CreatedByName
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    LEFT JOIN tblUsers U ON B.BookingCreatedBy = U.UserID
    WHERE B.BookingID = @BookingID;

    SELECT BD.*, P.ProductImage, P.StandardRentalDays
    FROM tblBookingDetails BD
    LEFT JOIN tblProducts P ON BD.ProductID = P.ProductID
    WHERE BD.BookingID = @BookingID;

    SELECT * FROM tblPayments WHERE BookingID = @BookingID;
END
GO

CREATE OR ALTER PROCEDURE SP_DeleteBooking @BookingID INT
AS
BEGIN
    UPDATE tblBookings SET IsDeleted = 1 WHERE BookingID = @BookingID;
    SELECT 1 AS Success, 'Booking Deleted' AS Message, @BookingID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_DashboardCounts @CompanyID INT = NULL
AS
BEGIN
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);
    SELECT
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TotalBookings,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND CAST(DeliveryDate AS DATE)=@Today
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TodayDeliveries,
        (SELECT COUNT(*) FROM tblBookings WHERE IsDeleted=0 AND CAST(ReturnDate AS DATE)=@Today
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TodayReturns,
        (SELECT ISNULL(SUM(RemainingAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND PaymentStatus IN ('Pending','Partial') AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS PendingPayments,
        (SELECT ISNULL(SUM(DepositAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND BookingStatus='Delivered' AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS PendingDeposit,
        (SELECT ISNULL(SUM(CASE WHEN BookingStatus IN ('Returned','Late Returned') AND CAST(ISNULL(ActualReturnDate, ReturnDate) AS DATE)=@Today THEN FinalRefundAmount
            WHEN BookingStatus='Delivered' AND CAST(ReturnDate AS DATE)=@Today THEN DepositAmount ELSE 0 END),0)
         FROM tblBookings WHERE IsDeleted=0 AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS RefundDepositAmount,
        (SELECT COUNT(*) FROM tblProducts WHERE IsAvailable=1 AND IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS AvailableProducts,
        (SELECT COUNT(*) FROM tblBookings WHERE BookingStatus IN ('Delivered','Late Returned')
            AND ReturnDate < @Today AND IsDeleted=0 AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS OverdueProducts,
        (SELECT ISNULL(SUM(PaymentAmount),0) FROM tblPayments
            WHERE PaymentType NOT IN ('Deposit Refund') AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TotalIncome,
        (SELECT ISNULL(SUM(PaymentAmount),0) FROM tblPayments
            WHERE PaymentType='Deposit Refund' AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TotalExpenses,
        (SELECT ISNULL(SUM(DamageDeductionAmount),0) FROM tblBookings WHERE IsDeleted=0
            AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS TotalDamageCuts;
END
GO

CREATE OR ALTER PROCEDURE SP_TopProducts @CompanyID INT = NULL, @TopN INT = 5
AS
BEGIN
    SELECT TOP (@TopN) BD.ProductName, COUNT(*) AS Total
    FROM tblBookingDetails BD
    INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
    WHERE B.IsDeleted=0 AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID)
    GROUP BY BD.ProductName
    ORDER BY COUNT(*) DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_MonthlyIncome @CompanyID INT = NULL
AS
BEGIN
    SELECT FORMAT(PaymentDate,'yyyy-MM') AS MonthLabel, SUM(PaymentAmount) AS Income
    FROM tblPayments
    WHERE (@CompanyID IS NULL OR CompanyID=@CompanyID)
    GROUP BY FORMAT(PaymentDate,'yyyy-MM')
    ORDER BY MonthLabel;
END
GO

CREATE OR ALTER PROCEDURE SP_BookingStatusChart @CompanyID INT = NULL
AS
BEGIN
    SELECT BookingStatus AS StatusName, COUNT(*) AS Total
    FROM tblBookings WHERE IsDeleted=0 AND (@CompanyID IS NULL OR CompanyID=@CompanyID)
    GROUP BY BookingStatus;
END
GO

CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT TOP 5 B.BookingNo, C.FullName AS CustomerName, BD.ProductName, B.DeliveryDate,
           B.RemainingAmount AS PendingAmount, B.PaymentStatus, B.BookingStatus AS DeliveryStatus
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted=0 AND CAST(B.DeliveryDate AS DATE)=@ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID)
    ORDER BY B.BookingID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_TodayReturnReport @CompanyID INT = NULL, @ReportDate DATE = NULL
AS
BEGIN
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));
    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, BD.ProductName, B.ReturnDate,
           CAST(ISNULL(NULLIF(B.DepositAmount, 0), BD.DepositAmount) AS DECIMAL(18,2)) AS DepositAmount,
           ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
           B.ExtraDays, B.ExtraChargeAmount, ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.BookingStatus, B.ActualReturnDate
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    WHERE B.IsDeleted=0 AND CAST(B.ReturnDate AS DATE)=@ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID);
END
GO

CREATE OR ALTER PROCEDURE SP_AddPayment
    @CompanyID INT, @BookingID INT, @PaymentType VARCHAR(50), @PaymentMode VARCHAR(50),
    @PaymentAmount DECIMAL(18,2), @TransactionNo VARCHAR(200), @Notes NVARCHAR(MAX), @CreatedBy INT
AS
BEGIN
    INSERT INTO tblPayments(CompanyID,BookingID,PaymentType,PaymentMode,PaymentAmount,TransactionNo,Notes,CreatedBy)
    VALUES(@CompanyID,@BookingID,@PaymentType,@PaymentMode,@PaymentAmount,@TransactionNo,@Notes,@CreatedBy);
    SELECT 1 AS Success, 'Payment Added' AS Message, SCOPE_IDENTITY() AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_GetNextBookingNo
AS
BEGIN
    DECLARE @Next INT = ISNULL((SELECT MAX(CAST(REPLACE(BookingNo,'BK','') AS INT)) FROM tblBookings WHERE BookingNo LIKE 'BK%'),1000) + 1;
    SELECT 'BK' + CAST(@Next AS VARCHAR(20)) AS BookingNo;
END
GO

PRINT 'Database script completed successfully.';
GO
