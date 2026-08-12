using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface IProductService
{
    Task<ApiResult> GetAllAsync(int? companyId, int? branchId = null);
    Task<ApiResult> GetByIdAsync(int id);
    Task<ApiResult> GetByCodeAsync(string productCode);
    Task<ApiResult> InsertAsync(ProductMasterModel model);
    Task<ApiResult> UpdateAsync(ProductMasterModel model);
    Task<ApiResult> DeleteAsync(int id, int? userId);
}
