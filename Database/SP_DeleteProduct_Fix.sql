/*==============================================================
  CREATE SP_DeleteProduct Stored Procedure
  Database: DB_A6B32D_LabelManagement
 ==============================================================*/
USE DB_A6B32D_LabelManagement;
GO

CREATE OR ALTER PROCEDURE SP_DeleteProduct 
    @ProductID INT, 
    @ModifiedBy INT = NULL
AS 
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE tblProducts 
        SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @ModifiedBy 
        WHERE ProductID = @ProductID;

        SELECT 1 AS Success, 'Product deleted' AS Message, @ProductID AS ID;
    END TRY 
    BEGIN CATCH 
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID; 
    END CATCH
END
GO
