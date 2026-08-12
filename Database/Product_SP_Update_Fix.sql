/* SP_GetAllProducts & SP_UpdateProduct Fix Script
   Run in SQL Server Management Studio (SSMS) on DB_A6B32D_LabelManagement */

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_GetAllProducts 
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS 
BEGIN 
    SET NOCOUNT ON;
    SELECT P.ProductID, P.CompanyID, P.BranchID, BR.BranchName, P.ProductCode, P.ProductName,
           P.CategoryID, C.CategoryName, P.SizeID, S.SizeName AS Size, P.ColorID, CL.ColorName AS Color,
           P.AgeGroup, P.RentAmount, P.DepositAmount, P.DiscountPercent, P.StandardRentalDays,
           P.ExtraChargePerDay, P.AvailableQuantity, P.Description, P.ProductImage,
           P.IsAvailable, P.NextAvailableDate, P.CreatedDate,
           ISNULL(P.IsFullSet, 0) AS IsFullSet, P.TopCode, P.TopSize, P.BottomCode, P.BottomSize
    FROM tblProducts P
    LEFT JOIN tblCategory C ON P.CategoryID = C.CategoryID
    LEFT JOIN tblSize S ON P.SizeID = S.SizeID
    LEFT JOIN tblColor CL ON P.ColorID = CL.ColorID
    LEFT JOIN tblBranch BR ON P.BranchID = BR.BranchID
    WHERE P.IsDeleted = 0 
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR P.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR P.BranchID = @BranchID)
    ORDER BY P.ProductID DESC;
END
GO
