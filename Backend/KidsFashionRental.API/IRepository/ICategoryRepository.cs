using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface ICategoryRepository
{
    Task<ApiResult> GetAllAsync(int? companyId);
    Task<ApiResult> GetByIdAsync(int id);
    Task<ApiResult> InsertAsync(CategoryModel model);
    Task<ApiResult> UpdateAsync(CategoryModel model);
    Task<ApiResult> DeleteAsync(int id, int? modifiedBy);
}
