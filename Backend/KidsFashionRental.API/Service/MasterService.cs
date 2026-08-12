using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class MasterService : IMasterService
{
    private readonly IMasterRepository _repo;
    public MasterService(IMasterRepository repo) => _repo = repo;

    public Task<ApiResult> GetProductsAsync(int? companyId) => _repo.GetProductsAsync(companyId);
    public Task<ApiResult> GetProductByCodeAsync(string productCode) => _repo.GetProductByCodeAsync(productCode);
    public Task<ApiResult> GetCustomersAsync(int? companyId, int? branchId = null) => _repo.GetCustomersAsync(companyId, branchId);
    public Task<ApiResult> InsertCustomerAsync(CustomerModel model) => _repo.InsertCustomerAsync(model);
    public Task<ApiResult> GetCustomerByMobileAsync(string mobile, int? companyId, int? branchId = null) => _repo.GetCustomerByMobileAsync(mobile, companyId, branchId);
    public Task<ApiResult> GetRolesAsync() => _repo.GetRolesAsync();
    public Task<ApiResult> GetRoleRightsAsync(int roleId) => _repo.GetRoleRightsAsync(roleId);
    public Task<ApiResult> SaveRoleRightsAsync(RoleRightsSaveModel model) => _repo.SaveRoleRightsAsync(model);
    public Task<ApiResult> InsertRoleAsync(RoleInsertModel model) => _repo.InsertRoleAsync(model);
}
