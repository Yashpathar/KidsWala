using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class ColorRepository : IColorRepository
{
    public async Task<ApiResult> GetAllAsync(int? companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return await RepositoryHelper.QueryListAsync<ColorModel>("SP_GetAllColors", p);
    }

    public async Task<ApiResult> GetByIdAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ColorID", id);
            result.Data = await BaseDataProvider.QuerySingleAsync<ColorModel>("SP_GetColorByID", p);
            result.Success = result.Data != null;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertAsync(ColorModel model)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", model.CompanyID);
        p.Add("ColorName", model.ColorName);
        p.Add("ColorCode", model.ColorCode);
        p.Add("CreatedBy", model.CreatedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_InsertColor", p);
    }

    public async Task<ApiResult> UpdateAsync(ColorModel model)
    {
        var p = new DynamicParameters();
        p.Add("ColorID", model.ColorID);
        p.Add("ColorName", model.ColorName);
        p.Add("ColorCode", model.ColorCode);
        p.Add("IsActive", model.IsActive);
        p.Add("ModifiedBy", model.ModifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_UpdateColor", p);
    }

    public async Task<ApiResult> DeleteAsync(int id, int? modifiedBy)
    {
        var p = new DynamicParameters();
        p.Add("ColorID", id);
        p.Add("ModifiedBy", modifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_DeleteColor", p);
    }
}
