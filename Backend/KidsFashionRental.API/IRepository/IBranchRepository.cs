using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface IBranchRepository
{
    Task<ApiResult> GetAllAsync();
    Task<ApiResult> GetByCompanyAsync(int companyId);
    Task<ApiResult> InsertAsync(BranchModel model);
    Task<ApiResult> UpdateAsync(BranchModel model);
}
