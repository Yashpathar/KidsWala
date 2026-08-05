using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface IAuthService
{
    Task<ApiResult> GetCompaniesForLoginAsync();
    Task<ApiResult> VerifyAsync(LoginModel model);
    Task<ApiResult> LoginAsync(LoginModel model);
    Task<ApiResult> GetMenuRightsForRoleAsync(int roleId);
}
