using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class ProductRepository : IProductRepository
{
    public async Task<ApiResult> GetAllAsync(int? companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return await RepositoryHelper.QueryListAsync<ProductMasterModel>("SP_GetAllProducts", p);
    }

    public async Task<ApiResult> GetByIdAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ProductID", id);
            result.Data = await BaseDataProvider.QuerySingleAsync<ProductMasterModel>("SP_GetProductByID", p);
            result.Success = result.Data != null;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetByCodeAsync(string productCode)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ProductCode", productCode);
            result.Data = await BaseDataProvider.QuerySingleAsync<ProductMasterModel>("SP_GetProductByCode", p);
            result.Success = result.Data != null;
            result.Message = result.Success ? "Found" : "Not found";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertAsync(ProductMasterModel model)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", model.CompanyID);
        AddProductFields(p, model);
        p.Add("CreatedBy", model.CreatedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_InsertProduct", p);
    }

    public async Task<ApiResult> UpdateAsync(ProductMasterModel model)
    {
        // SP_UpdateProduct does not take @CompanyID — only insert does
        var p = new DynamicParameters();
        p.Add("ProductID", model.ProductID);
        AddProductFields(p, model);
        p.Add("IsAvailable", model.IsAvailable);
        p.Add("ModifiedBy", model.ModifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_UpdateProduct", p);
    }

    public async Task<ApiResult> DeleteAsync(int id, int? modifiedBy)
    {
        var p = new DynamicParameters();
        p.Add("ProductID", id);
        p.Add("ModifiedBy", modifiedBy);
        return await RepositoryHelper.ExecuteSpAsync("SP_DeleteProduct", p);
    }

    private static void AddProductFields(DynamicParameters p, ProductMasterModel model)
    {
        p.Add("ProductCode", model.ProductCode);
        p.Add("ProductName", model.ProductName);
        p.Add("CategoryID", model.CategoryID);
        p.Add("SizeID", model.SizeID);
        p.Add("ColorID", model.ColorID);
        p.Add("AgeGroup", model.AgeGroup);
        p.Add("RentAmount", model.RentAmount);
        p.Add("DepositAmount", model.DepositAmount);
        p.Add("DiscountPercent", model.DiscountPercent);
        p.Add("StandardRentalDays", model.StandardRentalDays);
        p.Add("ExtraChargePerDay", model.ExtraChargePerDay);
        p.Add("AvailableQuantity", model.AvailableQuantity);
        p.Add("Description", model.Description);
        p.Add("ProductImage", model.ProductImage);
        p.Add("IsFullSet", model.IsFullSet);
        p.Add("TopCode", model.TopCode);
        p.Add("TopSize", model.TopSize);
        p.Add("BottomCode", model.BottomCode);
        p.Add("BottomSize", model.BottomSize);
    }
}
