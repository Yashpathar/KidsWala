-- Fix Today Delivery Report: Product, Pending, Payment, Status columns
USE DB_A6B32D_LabelManagement;
GO

CREATE OR ALTER PROCEDURE SP_TodayDeliveryReport
    @CompanyID INT = NULL, @BranchID INT = NULL, @ReportDate DATE = NULL, @FilterUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @ReportDate = ISNULL(@ReportDate, CAST(GETDATE() AS DATE));

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
      AND CAST(B.DeliveryDate AS DATE) = @ReportDate
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR B.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR B.BranchID = @BranchID)
      AND (@FilterUserID IS NULL OR B.BookingCreatedBy = @FilterUserID)
    ORDER BY B.BookingNo;
END
GO
