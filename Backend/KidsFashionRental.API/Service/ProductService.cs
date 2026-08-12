using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class ProductService : IProductService
{
    private readonly IProductRepository _repo;
    public ProductService(IProductRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(int? companyId, int? branchId = null) => _repo.GetAllAsync(companyId, branchId);

    public Task<ApiResult> GetByIdAsync(int id) =>
        id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid product id")) : _repo.GetByIdAsync(id);

    public Task<ApiResult> GetByCodeAsync(string productCode) =>
        string.IsNullOrWhiteSpace(productCode)
            ? Task.FromResult(ApiResult.Fail("Product code is required"))
            : _repo.GetByCodeAsync(productCode);

    public async Task<ApiResult> InsertAsync(ProductMasterModel model)
    {
        var err = ValidateProduct(model, isUpdate: false);
        if (err != null) return err;
        return await _repo.InsertAsync(model);
    }

    public async Task<ApiResult> UpdateAsync(ProductMasterModel model)
    {
        var err = ValidateProduct(model, isUpdate: true);
        if (err != null) return err;
        return await _repo.UpdateAsync(model);
    }

    public Task<ApiResult> DeleteAsync(int id, int? userId) =>
        id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid product id")) : _repo.DeleteAsync(id, userId);

    private static ApiResult? ValidateProduct(ProductMasterModel model, bool isUpdate)
    {
        if (isUpdate && model.ProductID <= 0) return ApiResult.Fail("Invalid product id");
        if (string.IsNullOrWhiteSpace(model.ProductCode)) return ApiResult.Fail("Product code is required");
        if (string.IsNullOrWhiteSpace(model.ProductName)) return ApiResult.Fail("Product name is required");
        if (model.CategoryID <= 0) return ApiResult.Fail("Category is required");
        if (model.SizeID <= 0) return ApiResult.Fail("Size is required");
        if (model.ColorID <= 0) return ApiResult.Fail("Color is required");
        if (model.RentAmount < 0) return ApiResult.Fail("Rent amount cannot be negative");
        if (model.DepositAmount < 0) return ApiResult.Fail("Deposit amount cannot be negative");
        return null;
    }
}
