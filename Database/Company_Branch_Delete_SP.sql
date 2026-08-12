-- Company and Branch Delete Stored Procedures

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_DeleteCompany
    @CompanyID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblCompany SET IsDeleted = 1 WHERE CompanyID = @CompanyID;
    UPDATE tblBranch SET IsDeleted = 1 WHERE CompanyID = @CompanyID;
    SELECT 1 AS Success, 'Company deleted successfully' AS Message, @CompanyID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_DeleteBranch
    @BranchID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblBranch SET IsDeleted = 1 WHERE BranchID = @BranchID;
    SELECT 1 AS Success, 'Branch deleted successfully' AS Message, @BranchID AS ID;
END
GO
