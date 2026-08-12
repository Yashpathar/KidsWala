using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class UserService : IUserService
{
    private readonly IUserRepository _repo;
    public UserService(IUserRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(int? companyId, int? branchId) => _repo.GetAllAsync(companyId, branchId);
    public Task<ApiResult> GetByIdAsync(int id) => id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid User ID")) : _repo.GetByIdAsync(id);

    public async Task<ApiResult> InsertAsync(UserMasterModel model)
    {
        if (string.IsNullOrWhiteSpace(model.Username)) return ApiResult.Fail("Username is required");
        if (string.IsNullOrWhiteSpace(model.Password)) return ApiResult.Fail("Password is required");
        if (string.IsNullOrWhiteSpace(model.FullName)) return ApiResult.Fail("Full Name is required");
        if (model.RoleID <= 0) return ApiResult.Fail("Role is required");
        return await _repo.InsertAsync(model);
    }

    public async Task<ApiResult> UpdateAsync(UserMasterModel model)
    {
        if (model.UserID <= 0) return ApiResult.Fail("Invalid User ID");
        if (string.IsNullOrWhiteSpace(model.Username)) return ApiResult.Fail("Username is required");
        if (string.IsNullOrWhiteSpace(model.FullName)) return ApiResult.Fail("Full Name is required");
        if (model.RoleID <= 0) return ApiResult.Fail("Role is required");
        return await _repo.UpdateAsync(model);
    }

    public Task<ApiResult> DeleteAsync(int id) => id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid User ID")) : _repo.DeleteAsync(id);
}
