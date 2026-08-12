-- Date Filter Enhancement for All Reports (Delivery, Return, Payments, Bookings)
-- Sets ANSI_NULLS and QUOTED_IDENTIFIER ON for XML .value() support

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;
    
    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        STUFF((
            SELECT ', ' + BD.ProductName
            FROM tblBookingDetails BD
            WHERE BD.BookingID = B.BookingID
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductName,
        B.DeliveryDate,
        B.BookingStatus AS DeliveryStatus,
        B.PaymentStatus,
        ISNULL(B.RemainingAmount, 0) AS PendingAmount,
        B.TotalAmount,
        B.AdvanceAmount,
        B.DepositAmount,
        B.BookingCreatedBy
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@FromDate IS NULL OR CAST(B.DeliveryDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.DeliveryDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.DeliveryDate DESC, B.BookingNo;
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_TodayReturnReport
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;

    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        STUFF((
            SELECT ', ' + BD.ProductName
            FROM tblBookingDetails BD
            WHERE BD.BookingID = B.BookingID
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS ProductName,
        B.ReturnDate,
        CAST(ISNULL(NULLIF(B.DepositAmount, 0), (SELECT SUM(ISNULL(BD.DepositAmount,0)) FROM tblBookingDetails BD WHERE BD.BookingID = B.BookingID)) AS DECIMAL(18,2)) AS DepositAmount,
        ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
        B.ExtraDays,
        B.ExtraChargeAmount,
        ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
        B.FinalRefundAmount,
        B.FinalProfitAmount,
        B.BookingStatus,
        B.ActualReturnDate
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@FromDate IS NULL OR CAST(B.ReturnDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.ReturnDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.ReturnDate DESC, B.BookingNo;
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_PaymentReport 
    @CompanyID INT = NULL, 
    @BranchID INT = NULL, 
    @ReportDate DATE = NULL, 
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL, 
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;
    IF @ReportDate IS NOT NULL AND @ReportDate < '1753-01-01' SET @ReportDate = NULL;

    IF @FromDate IS NULL AND @ToDate IS NULL AND @ReportDate IS NOT NULL
    BEGIN
        SET @FromDate = @ReportDate;
        SET @ToDate = @ReportDate;
    END

    SELECT P.PaymentID, B.BookingNo, P.PaymentType, P.PaymentMode, P.PaymentAmount,
           P.PaymentDate, P.TransactionNo
    FROM tblPayments P
    INNER JOIN tblBookings B ON P.BookingID = B.BookingID
    WHERE (@FromDate IS NULL OR CAST(P.PaymentDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(P.PaymentDate AS DATE) <= @ToDate)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY P.PaymentDate DESC;
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_GetAllBookings
    @CompanyID INT = NULL, 
    @BranchID INT = NULL,
    @Search VARCHAR(100) = NULL, 
    @Status VARCHAR(50) = NULL,
    @FilterUserID INT = NULL,
    @FromDate DATE = NULL,
    @ToDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NOT NULL AND @FromDate < '1753-01-01' SET @FromDate = NULL;
    IF @ToDate IS NOT NULL AND @ToDate < '1753-01-01' SET @ToDate = NULL;

    SELECT B.BookingID, B.BookingNo, C.FullName AS CustomerName, B.BookingDate, B.DeliveryDate, B.ReturnDate,
           B.TotalAmount, B.TotalRentAmount,
           CAST(ISNULL(B.DepositAmount, 0) AS DECIMAL(18,2)) AS DepositAmount,
           ISNULL(B.ExtraChargePerDay, 150) AS ExtraChargePerDay,
           B.AdvanceAmount, B.RemainingAmount, B.BookingStatus, B.PaymentStatus,
           B.ExtraDays, B.ExtraChargeAmount, ISNULL(B.DamageDeductionAmount, 0) AS DamageDeductionAmount,
           B.FinalRefundAmount, B.FinalProfitAmount, B.CompanyID
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
      AND (@Status IS NULL OR @Status = '' OR B.BookingStatus = @Status)
      AND (@Search IS NULL OR @Search = '' OR B.BookingNo LIKE '%'+@Search+'%' OR C.FullName LIKE '%'+@Search+'%')
      AND (@FromDate IS NULL OR CAST(B.BookingDate AS DATE) >= @FromDate)
      AND (@ToDate IS NULL OR CAST(B.BookingDate AS DATE) <= @ToDate)
    ORDER BY B.BookingID DESC;
END
GO
