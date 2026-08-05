using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class AuthRepository : IAuthRepository
{
    public Task<ApiResult> GetCompaniesForLoginAsync() =>
        RepositoryHelper.QueryListAsync<CompanyModel>("SP_GetCompaniesForLogin");

    public Task<ApiResult> VerifyAsync(LoginModel model) =>
        LoginAsync(model);

    public async Task<ApiResult> LoginAsync(LoginModel model)
    {
        var result = new ApiResult();
        try
        {
            if (string.IsNullOrWhiteSpace(model.UserName))
            {
                result.Message = "Please enter User ID";
                return result;
            }
            if (string.IsNullOrWhiteSpace(model.Password))
            {
                result.Message = "Please enter password";
                return result;
            }

            var user = await QueryUserAsync(model.UserName.Trim(), model.Password);
            if (user == null)
            {
                result.Message = "Invalid User ID or password";
                return result;
            }

            var scope = user.DataScope ?? DataScope.CompanyAll;
            var companyId = user.CompanyID ?? 0;
            var branchId = user.BranchID ?? 0;

            if (scope == DataScope.Platform)
            {
                companyId = 0;
                branchId = 0;
            }
            else if (scope == DataScope.CompanyAll)
            {
                if (companyId <= 0)
                {
                    result.Message = "User not assigned to a company";
                    return result;
                }
                branchId = 0;
            }
            else
            {
                if (companyId <= 0 || branchId <= 0)
                {
                    result.Message = "User not assigned to a branch";
                    return result;
                }
            }

            var companyName = "";
            var branchName = "";

            if (companyId > 0)
            {
                var company = await GetCompanyByIdAsync(companyId);
                if (company == null)
                {
                    result.Message = "Company not found";
                    return result;
                }
                companyName = company.CompanyName;
            }
            else if (scope == DataScope.Platform)
            {
                companyName = "All Companies";
            }

            if (branchId > 0)
            {
                var branch = await GetBranchByIdAsync(branchId);
                if (branch == null)
                {
                    result.Message = "Branch not found";
                    return result;
                }
                if (companyId > 0 && branch.CompanyID != companyId)
                {
                    result.Message = "Branch does not belong to company";
                    return result;
                }
                branchName = branch.BranchName;
            }
            else if (scope == DataScope.CompanyAll)
            {
                branchName = "All Branches";
            }

            await LogHistoryAsync(user.UserID, companyId, branchId, user.RoleID);

            var expiresAt = JwtTokenService.GetExpiryUtc();
            var token = JwtTokenService.GenerateToken(
                user.UserID, user.UserName, user.FullName, user.RoleName, user.RoleID,
                companyId, companyName, branchId, branchName, scope);

            user.PasswordHash = string.Empty;
            user.CompanyID = companyId > 0 ? companyId : null;
            user.BranchID = branchId > 0 ? branchId : null;
            user.CompanyName = companyName;
            user.BranchName = branchName;

            result.Success = true;
            result.Message = "Login successful";
            var menuRights = await GetMenuRightsForRoleInternalAsync(user.RoleID);

            result.Data = new LoginResponse
            {
                Token = token,
                User = user,
                ExpiresAt = expiresAt,
                DashboardRoute = GetDashboardRoute(user.RoleID, scope),
                MenuRights = menuRights
            };
        }
        catch (Exception ex)
        {
            result.Message = ex.Message;
        }
        return result;
    }

    private static string GetDashboardRoute(int roleId, string scope) =>
        scope switch
        {
            _ when string.Equals(scope, DataScope.Platform, StringComparison.OrdinalIgnoreCase) => "/dashboard",
            _ when roleId == 2 => "/dashboard",
            _ when roleId == 3 => "/dashboard",
            _ => "/dashboard"
        };

    private static async Task<UserModel?> QueryUserAsync(string userName, string password)
    {
        var p = new DynamicParameters();
        p.Add("UserName", userName);
        p.Add("Password", password);
        return await BaseDataProvider.QuerySingleAsync<UserModel>("SP_UserLoginByName", p);
    }

    private static async Task<CompanyModel?> GetCompanyByIdAsync(int companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return await BaseDataProvider.QuerySingleAsync<CompanyModel>("SP_GetCompanyById", p);
    }

    private static async Task<BranchModel?> GetBranchByIdAsync(int branchId)
    {
        var p = new DynamicParameters();
        p.Add("BranchID", branchId);
        return await BaseDataProvider.QuerySingleAsync<BranchModel>("SP_GetBranchById", p);
    }

    public async Task<ApiResult> GetMenuRightsForRoleAsync(int roleId)
    {
        var result = new ApiResult { Success = true };
        result.Data = await GetMenuRightsForRoleInternalAsync(roleId);
        return result;
    }

    private static async Task<List<RoleRightModel>> GetMenuRightsForRoleInternalAsync(int roleId)
    {
        var p = new DynamicParameters();
        p.Add("RoleID", roleId);
        var rows = await BaseDataProvider.QueryAsync<RoleRightModel>("SP_GetUserMenuRights", p);
        return rows ?? [];
    }

    private static async Task LogHistoryAsync(int userId, int companyId, int branchId, int roleId)
    {
        var p = new DynamicParameters();
        p.Add("UserID", userId);
        p.Add("CompanyID", companyId);
        p.Add("BranchID", branchId);
        p.Add("RoleID", roleId);
        await BaseDataProvider.ExecuteAsync("SP_InsertLoginHistory", p);
    }
}
