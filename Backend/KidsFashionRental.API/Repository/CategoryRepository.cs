using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class CategoryRepository : ICategoryRepository
{
    public async Task<ApiResult> GetAllAsync(int? companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return await RepositoryHelper.QueryListAsync<CategoryModel>("SP_GetAllCategories", p);
    }

    public async Task<ApiResult> GetByIdAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CategoryID", id);
            var data = await BaseDataProvider.QuerySingleAsync<CategoryModel>("SP_GetCategoryByID", p);
            result.Success = data != null;
            result.Data = data;
            result.Message = result.Success ? "Found" : "Not found";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertAsync(CategoryModel model)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", model.CompanyID);
        p.Add("CategoryName", model.CategoryName);
        p.Add("Description", model.Description);
        p.Add("CreatedBy", model.CreatedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_InsertCategory", p);
    }

    public async Task<ApiResult> UpdateAsync(CategoryModel model)
    {
        var p = new DynamicParameters();
        p.Add("CategoryID", model.CategoryID);
        p.Add("CategoryName", model.CategoryName);
        p.Add("Description", model.Description);
        p.Add("IsActive", model.IsActive);
        p.Add("ModifiedBy", model.ModifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_UpdateCategory", p);
    }

    public async Task<ApiResult> DeleteAsync(int id, int? modifiedBy)
    {
        var p = new DynamicParameters();
        p.Add("CategoryID", id);
        p.Add("ModifiedBy", modifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_DeleteCategory", p);
    }
}
