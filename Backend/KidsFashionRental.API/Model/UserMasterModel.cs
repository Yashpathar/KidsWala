namespace KidsFashionRental.API.Model;

public class UserMasterModel
{
    public int UserID { get; set; }
    public int? CompanyID { get; set; }
    public string? CompanyName { get; set; }
    public int? BranchID { get; set; }
    public string? BranchName { get; set; }
    public int RoleID { get; set; }
    public string? RoleName { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? Password { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? MobileNo { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? CreatedDate { get; set; }
}
