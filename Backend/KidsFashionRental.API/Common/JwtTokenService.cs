using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace KidsFashionRental.API.Common;

public static class JwtTokenService
{
    public const int SessionHours = 24;

    public static string GenerateToken(int userId, string userName, string fullName, string roleName, int roleId,
        int companyId, string? companyName, int branchId, string? branchName, string dataScope)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Name, userName),
            new("FullName", fullName),
            new(ClaimTypes.Role, roleName),
            new("RoleID", roleId.ToString()),
            new("CompanyID", companyId.ToString()),
            new("CompanyName", companyName ?? string.Empty),
            new("BranchID", branchId.ToString()),
            new("BranchName", branchName ?? string.Empty),
            new("DataScope", dataScope)
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(AppConfiguration.JwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: AppConfiguration.JwtIssuer,
            audience: AppConfiguration.JwtAudience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(SessionHours),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public static DateTime GetExpiryUtc() => DateTime.UtcNow.AddHours(SessionHours);
}
