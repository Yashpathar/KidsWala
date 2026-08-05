-- Better mobile match for customer auto-fill on booking
USE DB_A6B32D_LabelManagement;
GO

CREATE OR ALTER PROCEDURE SP_GetCustomerByMobile
    @CompanyID INT = NULL,
    @MobileNo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @M VARCHAR(20) = RIGHT(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(@MobileNo, ''))), ' ', ''), '-', ''), '+', ''), '(', ''), ')', ''),
        10);

    IF LEN(@M) < 10
    BEGIN
        SELECT CAST(NULL AS INT) AS CustomerID WHERE 1 = 0;
        RETURN;
    END

    SELECT TOP 1 CustomerID, CompanyID, FullName, ContactNo1, ContactNo2, Address, City, Notes
    FROM tblCustomers
    WHERE IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR CompanyID = @CompanyID)
      AND (
            RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ContactNo1, ''), ' ', ''), '-', ''), '+', ''), '(', ''), ')', ''), 10) = @M
         OR RIGHT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(ContactNo2, ''), ' ', ''), '-', ''), '+', ''), '(', ''), ')', ''), 10) = @M
      )
    ORDER BY CustomerID DESC;
END
GO
