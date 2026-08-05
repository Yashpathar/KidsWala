USE DB_A6B32D_LabelManagement;
GO

-- Seed 5 Test Full-Set Products with Blazer & Pant configurations

IF NOT EXISTS (SELECT 1 FROM tblProducts WHERE ProductCode = 'BL-101')
BEGIN
    INSERT INTO tblProducts (
        CompanyID, ProductCode, ProductName, CategoryName, Size, Color, AgeGroup,
        RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay, AvailableQuantity,
        Description, IsAvailable, IsFullSet, TopCode, TopSize, BottomCode, BottomSize
    ) VALUES (
        1, 'BL-101', 'Classic Black Blazer Suit Set', 'Blazer', '12', 'Black', '6-8 Years',
        1000.00, 1500.00, 0, 4, 150.00, 1,
        'Premium 2-piece Black Blazer Suit with formal pant.', 1, 1, 'BL-101-T', '12', 'BL-101-P', '12'
    );
END

IF NOT EXISTS (SELECT 1 FROM tblProducts WHERE ProductCode = 'SH-201')
BEGIN
    INSERT INTO tblProducts (
        CompanyID, ProductCode, ProductName, CategoryName, Size, Color, AgeGroup,
        RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay, AvailableQuantity,
        Description, IsAvailable, IsFullSet, TopCode, TopSize, BottomCode, BottomSize
    ) VALUES (
        1, 'SH-201', 'Royal Sherwani Cream & Gold', 'Sherwani', '14', 'Cream Gold', '8-10 Years',
        1500.00, 2000.00, 0, 4, 200.00, 1,
        'Designer Wedding Sherwani with matching Pajama.', 1, 1, 'SH-201-T', '14', 'SH-201-P', '14'
    );
END

IF NOT EXISTS (SELECT 1 FROM tblProducts WHERE ProductCode = 'IW-301')
BEGIN
    INSERT INTO tblProducts (
        CompanyID, ProductCode, ProductName, CategoryName, Size, Color, AgeGroup,
        RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay, AvailableQuantity,
        Description, IsAvailable, IsFullSet, TopCode, TopSize, BottomCode, BottomSize
    ) VALUES (
        1, 'IW-301', 'Indo Western Gold Party Set', 'Indo Western', '10', 'Gold', '4-6 Years',
        1200.00, 1800.00, 0, 4, 150.00, 1,
        'Indo Western designer set with gold embroidery top and pant.', 1, 1, 'IW-301-T', '10', 'IW-301-P', '10'
    );
END

IF NOT EXISTS (SELECT 1 FROM tblProducts WHERE ProductCode = 'KT-401')
BEGIN
    INSERT INTO tblProducts (
        CompanyID, ProductCode, ProductName, CategoryName, Size, Color, AgeGroup,
        RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay, AvailableQuantity,
        Description, IsAvailable, IsFullSet, TopCode, TopSize, BottomCode, BottomSize
    ) VALUES (
        1, 'KT-401', 'Silk Kurta Pajama Maroon', 'Kurta', '16', 'Maroon', '10-12 Years',
        800.00, 1200.00, 0, 4, 100.00, 1,
        'Silk Festival Kurta Pajama pair.', 1, 1, 'KT-401-T', '16', 'KT-401-P', '16'
    );
END

IF NOT EXISTS (SELECT 1 FROM tblProducts WHERE ProductCode = 'SU-501')
BEGIN
    INSERT INTO tblProducts (
        CompanyID, ProductCode, ProductName, CategoryName, Size, Color, AgeGroup,
        RentAmount, DepositAmount, DiscountPercent, StandardRentalDays, ExtraChargePerDay, AvailableQuantity,
        Description, IsAvailable, IsFullSet, TopCode, TopSize, BottomCode, BottomSize
    ) VALUES (
        1, 'SU-501', 'Navy Tuxedo Suit Set', 'Blazer', '12', 'Navy Blue', '6-8 Years',
        1400.00, 2000.00, 0, 4, 200.00, 1,
        'Navy Blue Tuxedo Suit with Jacket size 12 and Pant size 14.', 1, 1, 'SU-501-T', '12', 'SU-501-P', '14'
    );
END
GO
