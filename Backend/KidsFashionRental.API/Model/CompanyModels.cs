namespace KidsFashionRental.API.Model;

public class RoleModel
{
    public int RoleID { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string DataScope { get; set; } = "CompanyAll";
    public bool IsActive { get; set; } = true;
}

public class BranchModel
{
    public int BranchID { get; set; }
    public int CompanyID { get; set; }
    public string? CompanyName { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public string? BranchCode { get; set; }
    public string? Address { get; set; }
    public string? MobileNo { get; set; }
    public string? Email { get; set; }
    public bool IsActive { get; set; } = true;
}

public class LoginContextModel
{
    public int UserID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public int RoleID { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string DataScope { get; set; } = string.Empty;
    public int CompanyID { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public int BranchID { get; set; }
    public string BranchName { get; set; } = string.Empty;
    public string ContextLabel { get; set; } = string.Empty;
}

public class CompanyModel
{
    public int CompanyID { get; set; }
    public string CompanyName { get; set; } = string.Empty;
    public string? CompanyCode { get; set; }
    public string? BusinessType { get; set; }
    public string? Address { get; set; }
    public string? MobileNo { get; set; }
    public string? Email { get; set; }
    public string? GSTNo { get; set; }
    public string? LogoImage { get; set; }
    public bool IsActive { get; set; } = true;
}

public class RoleRightModel
{
    public string MenuKey { get; set; } = string.Empty;
    public bool CanAccess { get; set; }
    public bool IsView { get; set; }
    public bool IsCreate { get; set; }
    public bool IsUpdate { get; set; }
    public bool IsDelete { get; set; }
}

public class RoleInsertModel
{
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? DataScope { get; set; } = "CompanyAll";
}

public class RoleUpdateModel
{
    public int RoleID { get; set; }
    public string RoleName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? DataScope { get; set; } = "CompanyAll";
    public bool IsActive { get; set; } = true;
}

public class RoleRightsSaveModel
{
    public int RoleID { get; set; }
    public List<RoleRightModel> Rights { get; set; } = new List<RoleRightModel>();
}

public class NotificationModel
{
    public int NotificationID { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string NotificationType { get; set; } = string.Empty;
    public int? ReferenceID { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedDate { get; set; }
}
