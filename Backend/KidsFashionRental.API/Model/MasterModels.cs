namespace KidsFashionRental.API.Model;

public class MasterIdModel
{
    public int ID { get; set; }
}

public class CategoryModel
{
    public int CategoryID { get; set; }
    public int? CompanyID { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public int? CreatedBy { get; set; }
    public int? ModifiedBy { get; set; }
}

public class SizeModel
{
    public int SizeID { get; set; }
    public int? CompanyID { get; set; }
    public string SizeName { get; set; } = string.Empty;
    public string? SizeCode { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public int? CreatedBy { get; set; }
    public int? ModifiedBy { get; set; }
}

public class ColorModel
{
    public int ColorID { get; set; }
    public int? CompanyID { get; set; }
    public string ColorName { get; set; } = string.Empty;
    public string? ColorCode { get; set; }
    public bool IsActive { get; set; } = true;
    public int? CreatedBy { get; set; }
    public int? ModifiedBy { get; set; }
}

public class ProductMasterModel
{
    public int ProductID { get; set; }
    public int CompanyID { get; set; }
    public string ProductCode { get; set; } = string.Empty;
    public string ProductName { get; set; } = string.Empty;
    public int CategoryID { get; set; }
    public string? CategoryName { get; set; }
    public int SizeID { get; set; }
    public string? Size { get; set; }
    public int ColorID { get; set; }
    public string? Color { get; set; }
    public string? AgeGroup { get; set; }
    public decimal RentAmount { get; set; }
    public decimal DepositAmount { get; set; }
    public decimal DiscountPercent { get; set; }
    public int StandardRentalDays { get; set; } = 4;
    public decimal ExtraChargePerDay { get; set; } = 150;
    public int AvailableQuantity { get; set; } = 1;
    public string? Description { get; set; }
    public string? ProductImage { get; set; }
    public bool IsAvailable { get; set; } = true;
    public bool IsFullSet { get; set; } = false;
    public string? TopCode { get; set; }
    public string? TopSize { get; set; }
    public string? BottomCode { get; set; }
    public string? BottomSize { get; set; }
    public int? CreatedBy { get; set; }
    public int? ModifiedBy { get; set; }
}
