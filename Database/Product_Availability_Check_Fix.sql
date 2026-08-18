-- Stored Procedure Fix for Product Availability & Overlap Check
USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_CheckProductAvailability
    @ProductCode VARCHAR(50),
    @DeliveryDate DATE,
    @ReturnDate DATE,
    @ExcludeBookingID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CleanCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(@ProductCode, '')));

    -- Check if product or its pair top/bottom code is booked in overlapping date range
    IF EXISTS (
        SELECT 1 FROM tblBookingDetails BD
        INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
        INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
        WHERE (
            LOWER(BD.ProductCode) = LOWER(@CleanCode)
            OR LOWER(ISNULL(BD.TopCode,'')) = LOWER(@CleanCode)
            OR LOWER(ISNULL(BD.BottomCode,'')) = LOWER(@CleanCode)
          )
          AND B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND (@ExcludeBookingID IS NULL OR B.BookingID <> @ExcludeBookingID)
          -- Date overlap logic: DeliveryDate <= B.ReturnDate AND ReturnDate >= B.DeliveryDate
          AND (@DeliveryDate <= B.ReturnDate AND @ReturnDate >= B.DeliveryDate)
    )
    BEGIN
        SELECT TOP 1
            0 AS Success,
            'Product Already Booked (' + ISNULL(B.BookingNo, '') + ')' AS Message,
            B.BookingNo AS BookingNo,
            C.FullName AS CustomerName,
            B.BookingDate AS BookingDate,
            B.DeliveryDate AS DeliveryDate,
            B.ReturnDate AS ReturnDate,
            DATEADD(DAY,1,B.ReturnDate) AS NextAvailableDate
        FROM tblBookingDetails BD
        INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
        INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
        WHERE (
            LOWER(BD.ProductCode) = LOWER(@CleanCode)
            OR LOWER(ISNULL(BD.TopCode,'')) = LOWER(@CleanCode)
            OR LOWER(ISNULL(BD.BottomCode,'')) = LOWER(@CleanCode)
          )
          AND B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND (@ExcludeBookingID IS NULL OR B.BookingID <> @ExcludeBookingID)
          AND (@DeliveryDate <= B.ReturnDate AND @ReturnDate >= B.DeliveryDate)
        ORDER BY B.ReturnDate DESC;
    END
    ELSE
    BEGIN
        SELECT 1 AS Success,
               'Product Available' AS Message,
               NULL AS BookingNo,
               NULL AS CustomerName,
               NULL AS BookingDate,
               NULL AS DeliveryDate,
               NULL AS ReturnDate,
               @DeliveryDate AS NextAvailableDate;
    END
END
GO

CREATE OR ALTER PROCEDURE SP_GetProductStatusByCode
    @ProductCode VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CleanCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(@ProductCode, '')));
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    -- Find matching product details
    SELECT TOP 1
        P.ProductID,
        P.ProductCode,
        P.ProductName,
        P.RentAmount,
        P.DepositAmount,
        P.ProductImage,
        P.IsFullSet,
        P.TopCode,
        P.TopSize,
        P.BottomCode,
        P.BottomSize,
        P.Description
    FROM tblProducts P
    WHERE LOWER(P.ProductCode) = LOWER(@CleanCode)
       OR LOWER(ISNULL(P.TopCode, '')) = LOWER(@CleanCode)
       OR LOWER(ISNULL(P.BottomCode, '')) = LOWER(@CleanCode)
       OR LOWER(P.ProductCode) LIKE LOWER(@CleanCode) + '%';

    -- Find active / upcoming bookings for this product code
    SELECT
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        C.ContactNo1 AS CustomerPhone,
        B.BookingDate,
        B.DeliveryDate,
        B.ReturnDate,
        B.BookingStatus,
        CASE
            WHEN @Today BETWEEN B.DeliveryDate AND B.ReturnDate THEN 'Currently Booked'
            WHEN B.DeliveryDate > @Today THEN 'Upcoming Booking'
            ELSE B.BookingStatus
        END AS AvailabilityStatus
    FROM tblBookingDetails BD
    INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE (
        LOWER(BD.ProductCode) = LOWER(@CleanCode)
        OR LOWER(ISNULL(BD.TopCode,'')) = LOWER(@CleanCode)
        OR LOWER(ISNULL(BD.BottomCode,'')) = LOWER(@CleanCode)
        OR LOWER(BD.ProductCode) LIKE LOWER(@CleanCode) + '%'
      )
      AND B.IsDeleted = 0
      AND B.BookingStatus IN ('Booked', 'Delivered', 'Late Returned')
    ORDER BY B.DeliveryDate DESC;
END
GO
