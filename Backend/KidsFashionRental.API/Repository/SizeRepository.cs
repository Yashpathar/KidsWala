using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class SizeRepository : ISizeRepository
{
    public async Task<ApiResult> GetAllAsync(int? companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return await RepositoryHelper.QueryListAsync<SizeModel>("SP_GetAllSizes", p);
    }

    public async Task<ApiResult> GetByIdAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("SizeID", id);
            result.Data = await BaseDataProvider.QuerySingleAsync<SizeModel>("SP_GetSizeByID", p);
            result.Success = result.Data != null;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertAsync(SizeModel model)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", model.CompanyID);
        p.Add("SizeName", model.SizeName);
        p.Add("SizeCode", model.SizeCode);
        p.Add("SortOrder", model.SortOrder);
        p.Add("CreatedBy", model.CreatedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_InsertSize", p);
    }

    public async Task<ApiResult> UpdateAsync(SizeModel model)
    {
        var p = new DynamicParameters();
        p.Add("SizeID", model.SizeID);
        p.Add("SizeName", model.SizeName);
        p.Add("SizeCode", model.SizeCode);
        p.Add("SortOrder", model.SortOrder);
        p.Add("IsActive", model.IsActive);
        p.Add("ModifiedBy", model.ModifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_UpdateSize", p);
    }

    public async Task<ApiResult> DeleteAsync(int id, int? modifiedBy)
    {
        var p = new DynamicParameters();
        p.Add("SizeID", id);
        p.Add("ModifiedBy", modifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_DeleteSize", p);
    }
}
