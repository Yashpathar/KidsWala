-- Dashboard: Pending Deposit, Refund Deposit, Expenses, Top Products

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
        (SELECT ISNULL(SUM(
            CASE
                WHEN BookingStatus IN ('Returned','Late Returned') AND CAST(ISNULL(ActualReturnDate, ReturnDate) AS DATE)=@Today
                    THEN FinalRefundAmount
                WHEN BookingStatus='Delivered' AND CAST(ReturnDate AS DATE)=@Today
                    THEN DepositAmount
                ELSE 0
            END),0) FROM tblBookings WHERE IsDeleted=0 AND (@CompanyID IS NULL OR CompanyID=@CompanyID)) AS RefundDepositAmount,
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
    SELECT TOP 5 B.BookingID, B.BookingNo, C.FullName AS CustomerName, BD.ProductName,
           ISNULL(P.CategoryName, '') AS CategoryName, B.ReturnDate,
           CAST(ISNULL(NULLIF(B.DepositAmount, 0), BD.DepositAmount) AS DECIMAL(18,2)) AS DepositAmount,
           B.BookingStatus
    FROM tblBookings B
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    INNER JOIN tblBookingDetails BD ON B.BookingID = BD.BookingID
    LEFT JOIN tblProducts P ON BD.ProductID = P.ProductID
    WHERE B.IsDeleted=0 AND CAST(B.ReturnDate AS DATE)=@ReportDate
      AND (@CompanyID IS NULL OR B.CompanyID=@CompanyID)
    ORDER BY B.BookingID DESC;
END
GO
