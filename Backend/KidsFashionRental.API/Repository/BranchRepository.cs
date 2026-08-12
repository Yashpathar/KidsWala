using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class BranchRepository : IBranchRepository
{
    public Task<ApiResult> GetAllAsync() =>
        RepositoryHelper.QueryListAsync<BranchModel>("SP_GetAllBranches");

    public Task<ApiResult> GetByCompanyAsync(int companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return RepositoryHelper.QueryListAsync<BranchModel>("SP_GetBranchesByCompany", p);
    }

    public async Task<ApiResult> InsertAsync(BranchModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("BranchName", model.BranchName);
            p.Add("BranchCode", model.BranchCode);
            p.Add("Address", model.Address);
            p.Add("MobileNo", model.MobileNo);
            p.Add("Email", model.Email);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_InsertBranch", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> UpdateAsync(BranchModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("BranchID", model.BranchID);
            p.Add("CompanyID", model.CompanyID);
            p.Add("BranchName", model.BranchName);
            p.Add("BranchCode", model.BranchCode);
            p.Add("Address", model.Address);
            p.Add("MobileNo", model.MobileNo);
            p.Add("Email", model.Email);
            p.Add("IsActive", model.IsActive);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_UpdateBranch", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> DeleteAsync(int branchId)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("BranchID", branchId);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_DeleteBranch", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Delete failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
