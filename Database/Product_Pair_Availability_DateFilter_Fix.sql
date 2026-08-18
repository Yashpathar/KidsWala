-- Exact Product Code Matching (Eliminating Empty String False Positives)
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
    IF @CleanCode = ''
    BEGIN
        SELECT 1 AS Success, 'No code provided' AS Message, NULL AS BookingNo, NULL AS CustomerName, NULL AS BookingDate, NULL AS DeliveryDate, NULL AS ReturnDate, @DeliveryDate AS NextAvailableDate;
        RETURN;
    END

    -- Resolve Main Product Code, TopCode, and BottomCode if sub-code passed
    DECLARE @MainProductCode VARCHAR(50) = NULL;
    DECLARE @TopCode VARCHAR(50) = NULL;
    DECLARE @BottomCode VARCHAR(50) = NULL;

    SELECT TOP 1
        @MainProductCode = NULLIF(LTRIM(RTRIM(P.ProductCode)), ''),
        @TopCode = NULLIF(LTRIM(RTRIM(P.TopCode)), ''),
        @BottomCode = NULLIF(LTRIM(RTRIM(P.BottomCode)), '')
    FROM tblProducts P
    WHERE (NULLIF(LTRIM(RTRIM(P.ProductCode)), '') IS NOT NULL AND LOWER(P.ProductCode) = LOWER(@CleanCode))
       OR (NULLIF(LTRIM(RTRIM(P.TopCode)), '') IS NOT NULL AND LOWER(P.TopCode) = LOWER(@CleanCode))
       OR (NULLIF(LTRIM(RTRIM(P.BottomCode)), '') IS NOT NULL AND LOWER(P.BottomCode) = LOWER(@CleanCode));

    IF @MainProductCode IS NULL SET @MainProductCode = @CleanCode;

    -- Check if product or its pair top/bottom code is booked in overlapping date range
    IF EXISTS (
        SELECT 1 FROM tblBookingDetails BD
        INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
        INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
        WHERE B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND (@ExcludeBookingID IS NULL OR B.BookingID <> @ExcludeBookingID)
          AND (@DeliveryDate <= B.ReturnDate AND @ReturnDate >= B.DeliveryDate)
          AND (
            (NULLIF(LTRIM(RTRIM(BD.ProductCode)), '') IS NOT NULL AND (
                LOWER(BD.ProductCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@BottomCode))
            ))
            OR
            (NULLIF(LTRIM(RTRIM(BD.TopCode)), '') IS NOT NULL AND (
                LOWER(BD.TopCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@BottomCode))
            ))
            OR
            (NULLIF(LTRIM(RTRIM(BD.BottomCode)), '') IS NOT NULL AND (
                LOWER(BD.BottomCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@BottomCode))
            ))
          )
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
        WHERE B.IsDeleted = 0
          AND B.BookingStatus IN ('Booked','Delivered','Late Returned')
          AND (@ExcludeBookingID IS NULL OR B.BookingID <> @ExcludeBookingID)
          AND (@DeliveryDate <= B.ReturnDate AND @ReturnDate >= B.DeliveryDate)
          AND (
            (NULLIF(LTRIM(RTRIM(BD.ProductCode)), '') IS NOT NULL AND (
                LOWER(BD.ProductCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@BottomCode))
            ))
            OR
            (NULLIF(LTRIM(RTRIM(BD.TopCode)), '') IS NOT NULL AND (
                LOWER(BD.TopCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@BottomCode))
            ))
            OR
            (NULLIF(LTRIM(RTRIM(BD.BottomCode)), '') IS NOT NULL AND (
                LOWER(BD.BottomCode) = LOWER(@MainProductCode)
                OR (@TopCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@TopCode))
                OR (@BottomCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@BottomCode))
            ))
          )
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
    @ProductCode VARCHAR(50),
    @DeliveryDate DATE = NULL,
    @ReturnDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CleanCode VARCHAR(50) = LTRIM(RTRIM(ISNULL(@ProductCode, '')));
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    IF @DeliveryDate IS NULL SET @DeliveryDate = @Today;
    IF @ReturnDate IS NULL SET @ReturnDate = DATEADD(DAY, 4, @DeliveryDate);

    DECLARE @MainProductCode VARCHAR(50) = NULL;
    DECLARE @TopCode VARCHAR(50) = NULL;
    DECLARE @BottomCode VARCHAR(50) = NULL;

    SELECT TOP 1
        @MainProductCode = NULLIF(LTRIM(RTRIM(P.ProductCode)), ''),
        @TopCode = NULLIF(LTRIM(RTRIM(P.TopCode)), ''),
        @BottomCode = NULLIF(LTRIM(RTRIM(P.BottomCode)), '')
    FROM tblProducts P
    WHERE (NULLIF(LTRIM(RTRIM(P.ProductCode)), '') IS NOT NULL AND LOWER(P.ProductCode) = LOWER(@CleanCode))
       OR (NULLIF(LTRIM(RTRIM(P.TopCode)), '') IS NOT NULL AND LOWER(P.TopCode) = LOWER(@CleanCode))
       OR (NULLIF(LTRIM(RTRIM(P.BottomCode)), '') IS NOT NULL AND LOWER(P.BottomCode) = LOWER(@CleanCode));

    IF @MainProductCode IS NULL SET @MainProductCode = @CleanCode;

    -- 1. Product Details
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
    WHERE LOWER(P.ProductCode) = LOWER(@MainProductCode);

    -- 2. Check Overlapping Booking for the selected Date Range
    SELECT TOP 1
        B.BookingID,
        B.BookingNo,
        C.FullName AS CustomerName,
        C.ContactNo1 AS CustomerPhone,
        B.BookingDate,
        B.DeliveryDate,
        B.ReturnDate,
        B.BookingStatus
    FROM tblBookingDetails BD
    INNER JOIN tblBookings B ON BD.BookingID = B.BookingID
    INNER JOIN tblCustomers C ON B.CustomerID = C.CustomerID
    WHERE B.IsDeleted = 0
      AND B.BookingStatus IN ('Booked', 'Delivered', 'Late Returned')
      AND (@DeliveryDate <= B.ReturnDate AND @ReturnDate >= B.DeliveryDate)
      AND (
        (NULLIF(LTRIM(RTRIM(BD.ProductCode)), '') IS NOT NULL AND (
            LOWER(BD.ProductCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@BottomCode))
        ))
        OR
        (NULLIF(LTRIM(RTRIM(BD.TopCode)), '') IS NOT NULL AND (
            LOWER(BD.TopCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@BottomCode))
        ))
        OR
        (NULLIF(LTRIM(RTRIM(BD.BottomCode)), '') IS NOT NULL AND (
            LOWER(BD.BottomCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@BottomCode))
        ))
      )
    ORDER BY B.ReturnDate DESC;

    -- 3. All Active / Upcoming Bookings Schedule
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
    WHERE B.IsDeleted = 0
      AND B.BookingStatus IN ('Booked', 'Delivered', 'Late Returned')
      AND (
        (NULLIF(LTRIM(RTRIM(BD.ProductCode)), '') IS NOT NULL AND (
            LOWER(BD.ProductCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.ProductCode) = LOWER(@BottomCode))
        ))
        OR
        (NULLIF(LTRIM(RTRIM(BD.TopCode)), '') IS NOT NULL AND (
            LOWER(BD.TopCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.TopCode) = LOWER(@BottomCode))
        ))
        OR
        (NULLIF(LTRIM(RTRIM(BD.BottomCode)), '') IS NOT NULL AND (
            LOWER(BD.BottomCode) = LOWER(@MainProductCode)
            OR (@TopCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@TopCode))
            OR (@BottomCode IS NOT NULL AND LOWER(BD.BottomCode) = LOWER(@BottomCode))
        ))
      )
    ORDER BY B.DeliveryDate DESC;
END
GO
