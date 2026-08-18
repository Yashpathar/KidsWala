using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class ProductRepository : IProductRepository
{
    public async Task<ApiResult> GetAllAsync(int? companyId, int? branchId = null)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        p.Add("BranchID", branchId);
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
        var result = await RepositoryHelper.ExecuteSpAsync("SP_InsertProduct", p);
        if (!result.Success && result.Message != null && result.Message.Contains("too many arguments"))
        {
            var pCompat = new DynamicParameters();
            pCompat.Add("CompanyID", model.CompanyID);
            pCompat.Add("BranchID", model.BranchID);
            pCompat.Add("ProductCode", model.ProductCode);
            pCompat.Add("ProductName", model.ProductName);
            pCompat.Add("CategoryID", model.CategoryID);
            pCompat.Add("SizeID", model.SizeID);
            pCompat.Add("ColorID", model.ColorID);
            pCompat.Add("AgeGroup", model.AgeGroup);
            pCompat.Add("RentAmount", model.RentAmount);
            pCompat.Add("DepositAmount", model.DepositAmount);
            pCompat.Add("DiscountPercent", model.DiscountPercent);
            pCompat.Add("StandardRentalDays", model.StandardRentalDays);
            pCompat.Add("ExtraChargePerDay", model.ExtraChargePerDay);
            pCompat.Add("AvailableQuantity", model.AvailableQuantity);
            pCompat.Add("Description", model.Description);
            pCompat.Add("ProductImage", model.ProductImage);
            pCompat.Add("CreatedBy", model.CreatedBy);

            result = await RepositoryHelper.ExecuteSpAsync("SP_InsertProduct", pCompat);
            if (!result.Success && result.Message != null && result.Message.Contains("too many arguments"))
            {
                var pLegacy = new DynamicParameters();
                pLegacy.Add("CompanyID", model.CompanyID);
                pLegacy.Add("ProductCode", model.ProductCode);
                pLegacy.Add("ProductName", model.ProductName);
                pLegacy.Add("CategoryID", model.CategoryID);
                pLegacy.Add("SizeID", model.SizeID);
                pLegacy.Add("ColorID", model.ColorID);
                pLegacy.Add("AgeGroup", model.AgeGroup);
                pLegacy.Add("RentAmount", model.RentAmount);
                pLegacy.Add("DepositAmount", model.DepositAmount);
                pLegacy.Add("DiscountPercent", model.DiscountPercent);
                pLegacy.Add("StandardRentalDays", model.StandardRentalDays);
                pLegacy.Add("ExtraChargePerDay", model.ExtraChargePerDay);
                pLegacy.Add("AvailableQuantity", model.AvailableQuantity);
                pLegacy.Add("Description", model.Description);
                pLegacy.Add("ProductImage", model.ProductImage);
                pLegacy.Add("CreatedBy", model.CreatedBy);

                result = await RepositoryHelper.ExecuteSpAsync("SP_InsertProduct", pLegacy);
            }
        }
        return result;
    }

    public async Task<ApiResult> UpdateAsync(ProductMasterModel model)
    {
        // SP_UpdateProduct does not take @CompanyID — only insert does
        var p = new DynamicParameters();
        p.Add("ProductID", model.ProductID);
        AddProductFields(p, model);
        p.Add("IsAvailable", model.IsAvailable);
        p.Add("ModifiedBy", model.ModifiedBy);
        var result = await RepositoryHelper.ExecuteSpAsync("SP_UpdateProduct", p);
        if (!result.Success && result.Message != null && result.Message.Contains("too many arguments"))
        {
            var pCompat = new DynamicParameters();
            pCompat.Add("ProductID", model.ProductID);
            pCompat.Add("BranchID", model.BranchID);
            pCompat.Add("ProductCode", model.ProductCode);
            pCompat.Add("ProductName", model.ProductName);
            pCompat.Add("CategoryID", model.CategoryID);
            pCompat.Add("SizeID", model.SizeID);
            pCompat.Add("ColorID", model.ColorID);
            pCompat.Add("AgeGroup", model.AgeGroup);
            pCompat.Add("RentAmount", model.RentAmount);
            pCompat.Add("DepositAmount", model.DepositAmount);
            pCompat.Add("DiscountPercent", model.DiscountPercent);
            pCompat.Add("StandardRentalDays", model.StandardRentalDays);
            pCompat.Add("ExtraChargePerDay", model.ExtraChargePerDay);
            pCompat.Add("AvailableQuantity", model.AvailableQuantity);
            pCompat.Add("Description", model.Description);
            pCompat.Add("ProductImage", model.ProductImage);
            pCompat.Add("IsAvailable", model.IsAvailable);
            pCompat.Add("ModifiedBy", model.ModifiedBy);

            result = await RepositoryHelper.ExecuteSpAsync("SP_UpdateProduct", pCompat);
            if (!result.Success && result.Message != null && result.Message.Contains("too many arguments"))
            {
                var pLegacy = new DynamicParameters();
                pLegacy.Add("ProductID", model.ProductID);
                pLegacy.Add("ProductCode", model.ProductCode);
                pLegacy.Add("ProductName", model.ProductName);
                pLegacy.Add("CategoryID", model.CategoryID);
                pLegacy.Add("SizeID", model.SizeID);
                pLegacy.Add("ColorID", model.ColorID);
                pLegacy.Add("AgeGroup", model.AgeGroup);
                pLegacy.Add("RentAmount", model.RentAmount);
                pLegacy.Add("DepositAmount", model.DepositAmount);
                pLegacy.Add("DiscountPercent", model.DiscountPercent);
                pLegacy.Add("StandardRentalDays", model.StandardRentalDays);
                pLegacy.Add("ExtraChargePerDay", model.ExtraChargePerDay);
                pLegacy.Add("AvailableQuantity", model.AvailableQuantity);
                pLegacy.Add("Description", model.Description);
                pLegacy.Add("ProductImage", model.ProductImage);
                pLegacy.Add("IsAvailable", model.IsAvailable);
                pLegacy.Add("ModifiedBy", model.ModifiedBy);

                result = await RepositoryHelper.ExecuteSpAsync("SP_UpdateProduct", pLegacy);
            }
        }
        return result;
    }

    public async Task<ApiResult> DeleteAsync(int id, int? modifiedBy)
    {
        try
        {
            using var conn = new Microsoft.Data.SqlClient.SqlConnection(AppConfiguration.ConnectionString);
            await conn.OpenAsync();

            // 1. Fetch ProductCode
            string? productCode = await conn.QueryFirstOrDefaultAsync<string>(
                "SELECT ProductCode FROM tblProducts WHERE ProductID = @id", new { id });

            // 2. Check if associated with tblBookingDetails (correcting the tblBookingItems bug)
            bool existsInBookings = await conn.ExecuteScalarAsync<bool>(@"
                SELECT CASE WHEN EXISTS (
                    SELECT 1 FROM tblBookingDetails 
                    WHERE ProductID = @id OR (ProductCode IS NOT NULL AND ProductCode = @productCode)
                ) THEN 1 ELSE 0 END", new { id, productCode });

            if (existsInBookings)
            {
                return ApiResult.Fail("Cannot delete product: It is associated with active or historical booking records.");
            }

            // 3. Mark as deleted
            await conn.ExecuteAsync(@"
                UPDATE tblProducts 
                SET IsDeleted = 1, ModifiedDate = GETDATE(), ModifiedBy = @modifiedBy 
                WHERE ProductID = @id", new { id, modifiedBy });

            return ApiResult.Ok("Product deleted successfully", new { id });
        }
        catch (Exception ex)
        {
            return ApiResult.Fail(ex.Message);
        }
    }

    private static void AddProductFields(DynamicParameters p, ProductMasterModel model)
    {
        p.Add("BranchID", model.BranchID);
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
