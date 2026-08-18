$dllPath = "d:\Rantel Cloth WEB\Backend\KidsFashionRental.API\bin\Debug\net8.0\Microsoft.Data.SqlClient.dll"
Write-Host "Loading assembly $dllPath..."
Add-Type -Path $dllPath

$connString = "Data Source=SQL5053.site4now.net;Initial Catalog=DB_A6B32D_LabelManagement;Persist Security Info=True;User ID=DB_A6B32D_LabelManagement_admin;Password=Atharv@123;TrustServerCertificate=True"
$query = @"
CREATE OR ALTER PROCEDURE SP_DeleteProduct
    @ProductID INT,
    @ModifiedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ProductCode VARCHAR(50);
        SELECT @ProductCode = ProductCode FROM tblProducts WHERE ProductID = @ProductID;

        IF EXISTS (
            SELECT 1 FROM tblBookingDetails BI
            WHERE BI.ProductID = @ProductID OR (BI.ProductCode IS NOT NULL AND BI.ProductCode = @ProductCode)
        )
        BEGIN
            SELECT 0 AS Success, 'Cannot delete product: It is associated with active or historical booking records.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblProducts
        SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @ModifiedBy
        WHERE ProductID = @ProductID;

        SELECT 1 AS Success, 'Product deleted successfully' AS Message, @ProductID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
"@

try {
    Write-Host "Connecting to SQL database..."
    $connection = New-Object Microsoft.Data.SqlClient.SqlConnection($connString)
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $command.ExecuteNonQuery()
    $connection.Close()
    Write-Host "SP_DeleteProduct stored procedure has been successfully updated on the database!"
} catch {
    Write-Error "Failed to update procedure: $_"
}
