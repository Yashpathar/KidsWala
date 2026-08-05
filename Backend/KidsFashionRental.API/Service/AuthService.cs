using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class AuthService : IAuthService
{
    private readonly IAuthRepository _repo;
    public AuthService(IAuthRepository repo) => _repo = repo;
    public Task<ApiResult> GetCompaniesForLoginAsync() => _repo.GetCompaniesForLoginAsync();
    public Task<ApiResult> VerifyAsync(LoginModel model) => _repo.VerifyAsync(model);
    public Task<ApiResult> LoginAsync(LoginModel model) => _repo.LoginAsync(model);
    public Task<ApiResult> GetMenuRightsForRoleAsync(int roleId) => _repo.GetMenuRightsForRoleAsync(roleId);
}
