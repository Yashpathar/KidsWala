using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface ICompanyRepository
{
    Task<ApiResult> GetAllAsync();
    Task<ApiResult> InsertAsync(CompanyModel model);
    Task<ApiResult> UpdateAsync(CompanyModel model);
}
