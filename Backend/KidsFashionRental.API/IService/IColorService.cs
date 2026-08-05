using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface IColorService
{
    Task<ApiResult> GetAllAsync(int? companyId);
    Task<ApiResult> GetByIdAsync(int id);
    Task<ApiResult> InsertAsync(ColorModel model);
    Task<ApiResult> UpdateAsync(ColorModel model);
    Task<ApiResult> DeleteAsync(int id, int? userId);
}
