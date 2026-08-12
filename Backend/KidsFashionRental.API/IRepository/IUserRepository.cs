using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface IUserRepository
{
    Task<ApiResult> GetAllAsync(int? companyId, int? branchId);
    Task<ApiResult> GetByIdAsync(int id);
    Task<ApiResult> InsertAsync(UserMasterModel model);
    Task<ApiResult> UpdateAsync(UserMasterModel model);
    Task<ApiResult> DeleteAsync(int id);
}
