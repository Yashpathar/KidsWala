/*==============================================================
  CASCADE / DEPENDENCY DELETE PROTECTION STORED PROCEDURES
  Database: DB_A6B32D_LabelManagement (KidsFashionRentalDB)
 ==============================================================*/
USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

----------------------------------------------------------------
-- 1. SP_DeleteCategory (Checks tblProducts dependency)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteCategory
    @CategoryID INT,
    @ModifiedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM tblProducts P
            WHERE P.IsDeleted = 0 AND (
                P.CategoryID = @CategoryID OR
                P.CategoryName = (SELECT CategoryName FROM tblCategory WHERE CategoryID = @CategoryID)
            )
        )
        BEGIN
            SELECT 0 AS Success, 'Cannot delete category: It is currently assigned to 1 or more active products. Please reassign or remove products first.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblCategory
        SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @ModifiedBy
        WHERE CategoryID = @CategoryID;

        SELECT 1 AS Success, 'Category deleted successfully' AS Message, @CategoryID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 2. SP_DeleteSize (Checks tblProducts dependency)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteSize
    @SizeID INT,
    @ModifiedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM tblProducts P
            WHERE P.IsDeleted = 0 AND (
                P.SizeID = @SizeID OR
                P.Size = (SELECT SizeName FROM tblSize WHERE SizeID = @SizeID)
            )
        )
        BEGIN
            SELECT 0 AS Success, 'Cannot delete size: It is currently assigned to 1 or more active products. Please reassign or remove products first.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblSize
        SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @ModifiedBy
        WHERE SizeID = @SizeID;

        SELECT 1 AS Success, 'Size deleted successfully' AS Message, @SizeID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 3. SP_DeleteColor (Checks tblProducts dependency)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteColor
    @ColorID INT,
    @ModifiedBy INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (
            SELECT 1 FROM tblProducts P
            WHERE P.IsDeleted = 0 AND (
                P.ColorID = @ColorID OR
                P.Color = (SELECT ColorName FROM tblColor WHERE ColorID = @ColorID)
            )
        )
        BEGIN
            SELECT 0 AS Success, 'Cannot delete color: It is currently assigned to 1 or more active products. Please reassign or remove products first.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblColor
        SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @ModifiedBy
        WHERE ColorID = @ColorID;

        SELECT 1 AS Success, 'Color deleted successfully' AS Message, @ColorID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 4. SP_DeleteProduct (Checks tblBookingItems & tblBookings)
----------------------------------------------------------------
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
            SELECT 1 FROM tblBookingItems BI
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
GO

----------------------------------------------------------------
-- 5. SP_DeleteCompany (Checks Branch, Users, Products, Bookings)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteCompany
    @CompanyID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM tblBranch WHERE CompanyID = @CompanyID AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete company: Active branches are associated with this company. Delete or transfer branches first.' AS Message, 0 AS ID;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblUsers WHERE CompanyID = @CompanyID AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete company: Active user accounts are assigned to this company.' AS Message, 0 AS ID;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblProducts WHERE CompanyID = @CompanyID AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete company: Products are associated with this company.' AS Message, 0 AS ID;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblBookings WHERE CompanyID = @CompanyID AND BookingStatus <> 'Cancelled')
        BEGIN
            SELECT 0 AS Success, 'Cannot delete company: Active bookings exist for this company.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblCompany SET IsDeleted = 1 WHERE CompanyID = @CompanyID;
        UPDATE tblBranch SET IsDeleted = 1 WHERE CompanyID = @CompanyID;
        SELECT 1 AS Success, 'Company deleted successfully' AS Message, @CompanyID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 6. SP_DeleteBranch (Checks Users, Bookings)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteBranch
    @BranchID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM tblUsers WHERE BranchID = @BranchID AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete branch: Active users are assigned to this branch.' AS Message, 0 AS ID;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblBookings WHERE BranchID = @BranchID AND BookingStatus <> 'Cancelled')
        BEGIN
            SELECT 0 AS Success, 'Cannot delete branch: Active bookings exist under this branch.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblBranch SET IsDeleted = 1 WHERE BranchID = @BranchID;
        SELECT 1 AS Success, 'Branch deleted successfully' AS Message, @BranchID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 7. SP_DeleteUser (Checks SuperAdmin & Created Bookings)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM tblUsers WHERE UserID = @UserID AND (RoleID = 1 OR LOWER(Username) = 'admin') AND IsDeleted = 0)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete Super Admin user account.' AS Message, 0 AS ID;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM tblBookings WHERE BookingCreatedBy = @UserID)
        BEGIN
            SELECT 0 AS Success, 'Cannot delete user: Active or historical booking transactions were created by this user.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblUsers SET IsDeleted = 1 WHERE UserID = @UserID;
        SELECT 1 AS Success, 'User deleted successfully' AS Message, @UserID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

----------------------------------------------------------------
-- 8. SP_DeleteBooking (Checks Delivered/Active Rental status)
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE SP_DeleteBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM tblBookings WHERE BookingID = @BookingID AND BookingStatus IN ('Delivered', 'Picked Up', 'Dispatched'))
        BEGIN
            SELECT 0 AS Success, 'Cannot delete booking: The item is currently delivered or rented out. Process a return or cancel first.' AS Message, 0 AS ID;
            RETURN;
        END

        UPDATE tblBookings SET BookingStatus = 'Cancelled' WHERE BookingID = @BookingID;
        SELECT 1 AS Success, 'Booking cancelled successfully' AS Message, @BookingID AS ID;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message, 0 AS ID;
    END CATCH
END
GO

PRINT 'Dependency Delete Protection Stored Procedures Applied Successfully.';
GO
