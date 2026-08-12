-- User Master Stored Procedures for DB_A6B32D_LabelManagement

USE DB_A6B32D_LabelManagement;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE SP_GetAllUsers
    @CompanyID INT = NULL,
    @BranchID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.CompanyID, C.CompanyName, U.BranchID, BR.BranchName, U.RoleID, R.RoleName,
           U.Username, U.PasswordHash AS Password, U.FullName, U.Email, U.MobileNo, U.IsActive, U.CreatedDate
    FROM tblUsers U
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    LEFT JOIN tblBranch BR ON U.BranchID = BR.BranchID
    LEFT JOIN tblRole R ON U.RoleID = R.RoleID
    WHERE U.IsDeleted = 0
      AND (@CompanyID IS NULL OR @CompanyID = 0 OR U.CompanyID = @CompanyID)
      AND (@BranchID IS NULL OR @BranchID = 0 OR U.BranchID = @BranchID)
    ORDER BY U.UserID DESC;
END
GO

CREATE OR ALTER PROCEDURE SP_GetUserByID @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT U.UserID, U.CompanyID, C.CompanyName, U.BranchID, BR.BranchName, U.RoleID, R.RoleName,
           U.Username, U.PasswordHash AS Password, U.FullName, U.Email, U.MobileNo, U.IsActive, U.CreatedDate
    FROM tblUsers U
    LEFT JOIN tblCompany C ON U.CompanyID = C.CompanyID
    LEFT JOIN tblBranch BR ON U.BranchID = BR.BranchID
    LEFT JOIN tblRole R ON U.RoleID = R.RoleID
    WHERE U.UserID = @UserID AND U.IsDeleted = 0;
END
GO

CREATE OR ALTER PROCEDURE SP_InsertUser
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @RoleID INT,
    @Username VARCHAR(100),
    @PasswordHash VARCHAR(500),
    @FullName VARCHAR(200),
    @Email VARCHAR(200) = NULL,
    @MobileNo VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM tblUsers WHERE Username = @Username AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Username already exists' AS Message, 0 AS ID;
        RETURN;
    END

    INSERT INTO tblUsers(CompanyID, BranchID, RoleID, Username, PasswordHash, FullName, Email, MobileNo, IsActive, CreatedDate, IsDeleted)
    VALUES(@CompanyID, @BranchID, @RoleID, @Username, @PasswordHash, @FullName, @Email, @MobileNo, 1, GETDATE(), 0);

    SELECT 1 AS Success, 'User Created Successfully' AS Message, SCOPE_IDENTITY() AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_UpdateUser
    @UserID INT,
    @CompanyID INT = NULL,
    @BranchID INT = NULL,
    @RoleID INT,
    @Username VARCHAR(100),
    @PasswordHash VARCHAR(500) = NULL,
    @FullName VARCHAR(200),
    @Email VARCHAR(200) = NULL,
    @MobileNo VARCHAR(20) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM tblUsers WHERE Username = @Username AND UserID <> @UserID AND IsDeleted = 0)
    BEGIN
        SELECT 0 AS Success, 'Username already taken by another user' AS Message, 0 AS ID;
        RETURN;
    END

    IF @PasswordHash IS NOT NULL AND LEN(TRIM(@PasswordHash)) > 0
    BEGIN
        UPDATE tblUsers SET
            CompanyID = @CompanyID, BranchID = @BranchID, RoleID = @RoleID, Username = @Username,
            PasswordHash = @PasswordHash, FullName = @FullName, Email = @Email, MobileNo = @MobileNo,
            IsActive = @IsActive
        WHERE UserID = @UserID;
    END
    ELSE
    BEGIN
        UPDATE tblUsers SET
            CompanyID = @CompanyID, BranchID = @BranchID, RoleID = @RoleID, Username = @Username,
            FullName = @FullName, Email = @Email, MobileNo = @MobileNo, IsActive = @IsActive
        WHERE UserID = @UserID;
    END

    SELECT 1 AS Success, 'User Updated Successfully' AS Message, @UserID AS ID;
END
GO

CREATE OR ALTER PROCEDURE SP_DeleteUser @UserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblUsers SET IsDeleted = 1 WHERE UserID = @UserID;
    SELECT 1 AS Success, 'User Deleted Successfully' AS Message, @UserID AS ID;
END
GO
