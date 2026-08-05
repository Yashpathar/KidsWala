using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface IMasterRepository
{
    Task<ApiResult> GetProductsAsync(int? companyId);
    Task<ApiResult> GetProductByCodeAsync(string productCode);
    Task<ApiResult> GetCustomersAsync(int? companyId);
    Task<ApiResult> InsertCustomerAsync(CustomerModel model);
    Task<ApiResult> GetCustomerByMobileAsync(string mobile, int? companyId);
    Task<ApiResult> GetRolesAsync();
    Task<ApiResult> GetRoleRightsAsync(int roleId);
    Task<ApiResult> SaveRoleRightsAsync(RoleRightsSaveModel model);
    Task<ApiResult> InsertRoleAsync(RoleInsertModel model);
}
