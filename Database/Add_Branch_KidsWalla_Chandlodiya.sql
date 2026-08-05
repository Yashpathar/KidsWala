/* Add branch: Kids Walla Chandlodiya under company Kids Walla */
USE DB_A6B32D_LabelManagement;
GO

DECLARE @CompanyID INT = (
    SELECT TOP 1 CompanyID
    FROM tblCompany
    WHERE IsDeleted = 0
      AND (CompanyCode = 'KW' OR CompanyName LIKE 'Kids Walla%')
    ORDER BY CASE WHEN CompanyCode = 'KW' THEN 0 ELSE 1 END, CompanyID
);

IF @CompanyID IS NULL
BEGIN
    RAISERROR('Company "Kids Walla" not found. Add company in Company Master first (code KW).', 16, 1);
    RETURN;
END

IF NOT EXISTS (
    SELECT 1 FROM tblBranch
    WHERE IsDeleted = 0 AND CompanyID = @CompanyID
      AND (BranchCode = 'KWC' OR BranchName = 'Kids Walla Chandlodiya')
)
BEGIN
    INSERT INTO tblBranch(CompanyID, BranchName, BranchCode, Address, MobileNo, Email, IsActive, IsDeleted)
    VALUES (
        @CompanyID,
        'Kids Walla Chandlodiya',
        'KWC',
        'Chandlodiya, Ahmedabad',
        '9999992222',
        'chandlodiya@kidswalla.com',
        1,
        0
    );
    PRINT 'Branch added: Kids Walla Chandlodiya';
END
ELSE
BEGIN
    UPDATE tblBranch
    SET BranchName = 'Kids Walla Chandlodiya',
        CompanyID = @CompanyID,
        IsActive = 1,
        IsDeleted = 0
    WHERE CompanyID = @CompanyID
      AND (BranchCode = 'KWC' OR BranchName = 'Kids Walla Chandlodiya');

    PRINT 'Branch already exists — updated name/details.';
END
GO

SELECT B.BranchID, C.CompanyName, B.BranchName, B.BranchCode, B.MobileNo, B.Email, B.IsActive
FROM tblBranch B
INNER JOIN tblCompany C ON B.CompanyID = C.CompanyID
WHERE B.IsDeleted = 0 AND B.BranchName = 'Kids Walla Chandlodiya';
GO
