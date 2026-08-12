-- Customer Branch-wise Stored Procedure Enhancements
-- Allows filtering, searching, and creating customers by BranchID

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_GetAllCustomers
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT C.CustomerID, C.CompanyID, C.BranchID, BR.BranchName, C.FullName, C.ContactNo1, C.ContactNo2,
           C.Address, C.City, C.Notes, C.CreatedDate
    FROM tblCustomers C
    LEFT JOIN tblBranch BR ON C.BranchID = BR.BranchID
    WHERE C.IsDeleted = 0 
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR C.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR C.BranchID = @BranchID)
    ORDER BY C.CustomerID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetCustomerByMobile
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @MobileNo VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT C.CustomerID, C.CompanyID, C.BranchID, BR.BranchName, C.FullName, C.ContactNo1, C.ContactNo2,
           C.Address, C.City, C.Notes, C.CreatedDate
    FROM tblCustomers C
    LEFT JOIN tblBranch BR ON C.BranchID = BR.BranchID
    WHERE C.IsDeleted = 0 
      AND (C.ContactNo1 = @MobileNo OR C.ContactNo2 = @MobileNo)
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR C.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR C.BranchID = @BranchID);
END
GO

CREATE OR ALTER PROCEDURE SP_InsertCustomer
    @CompanyID INT, 
    @BranchID INT = NULL,
    @FullName VARCHAR(200), 
    @ContactNo1 VARCHAR(20), 
    @ContactNo2 VARCHAR(20) = NULL,
    @Address NVARCHAR(MAX) = NULL, 
    @City VARCHAR(100) = NULL, 
    @Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO tblCustomers(CompanyID, BranchID, FullName, ContactNo1, ContactNo2, Address, City, Notes)
    VALUES(@CompanyID, @BranchID, @FullName, @ContactNo1, @ContactNo2, @Address, @City, @Notes);
    SELECT 1 AS Success, 'Customer Added Successfully' AS Message, SCOPE_IDENTITY() AS ID;
END
GO
