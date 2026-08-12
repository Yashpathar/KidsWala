using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class CompanyRepository : ICompanyRepository
{
    public Task<ApiResult> GetAllAsync() =>
        RepositoryHelper.QueryListAsync<CompanyModel>("SP_GetAllCompanies");

    public async Task<ApiResult> InsertAsync(CompanyModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyName", model.CompanyName);
            p.Add("CompanyCode", model.CompanyCode);
            p.Add("BusinessType", model.BusinessType);
            p.Add("Address", model.Address);
            p.Add("MobileNo", model.MobileNo);
            p.Add("Email", model.Email);
            p.Add("GSTNo", model.GSTNo);
            p.Add("LogoImage", model.LogoImage);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_InsertCompany", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> UpdateAsync(CompanyModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("CompanyName", model.CompanyName);
            p.Add("CompanyCode", model.CompanyCode);
            p.Add("BusinessType", model.BusinessType);
            p.Add("Address", model.Address);
            p.Add("MobileNo", model.MobileNo);
            p.Add("Email", model.Email);
            p.Add("GSTNo", model.GSTNo);
            p.Add("LogoImage", model.LogoImage);
            p.Add("IsActive", model.IsActive);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_UpdateCompany", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> DeleteAsync(int companyId)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", companyId);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_DeleteCompany", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Delete failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
