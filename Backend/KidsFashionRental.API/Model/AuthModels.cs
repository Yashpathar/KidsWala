namespace KidsFashionRental.API.Model;

public class LoginModel
{
    public string UserName { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public int? CompanyID { get; set; }
    public int? BranchID { get; set; }
    public int? RoleID { get; set; }
}

public class UserModel
{
    public int UserID { get; set; }
    public int RoleID { get; set; }
    public int? CompanyID { get; set; }
    public int? BranchID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string MobileNo { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public string DataScope { get; set; } = string.Empty;
    public string? CompanyName { get; set; }
    public string? BranchName { get; set; }
    public string? CompanyLogo { get; set; }
}

public class LoginResponse
{
    public string Token { get; set; } = string.Empty;
    public UserModel User { get; set; } = new();
    public DateTime ExpiresAt { get; set; }
    public string DashboardRoute { get; set; } = "/dashboard";
    public List<RoleRightModel> MenuRights { get; set; } = [];
}

public class LoginStepResponse
{
    public bool RequiresSelection { get; set; } = true;
    public int UserID { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public bool IsSuperAdmin { get; set; }
    public List<CompanyModel> Companies { get; set; } = [];
    public List<RoleModel> Roles { get; set; } = [];
}
