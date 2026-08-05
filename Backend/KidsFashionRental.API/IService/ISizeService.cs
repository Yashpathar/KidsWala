using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface ISizeService
{
    Task<ApiResult> GetAllAsync(int? companyId);
    Task<ApiResult> GetByIdAsync(int id);
    Task<ApiResult> InsertAsync(SizeModel model);
    Task<ApiResult> UpdateAsync(SizeModel model);
    Task<ApiResult> DeleteAsync(int id, int? userId);
}
