using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _repo;
    public CategoryService(ICategoryRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(int? companyId) => _repo.GetAllAsync(companyId);

    public Task<ApiResult> GetByIdAsync(int id)
    {
        if (id <= 0) return Task.FromResult(ApiResult.Fail("Invalid category id"));
        return _repo.GetByIdAsync(id);
    }

    public async Task<ApiResult> InsertAsync(CategoryModel model)
    {
        if (string.IsNullOrWhiteSpace(model.CategoryName))
            return ApiResult.Fail("Category name is required");
        return await _repo.InsertAsync(model);
    }

    public async Task<ApiResult> UpdateAsync(CategoryModel model)
    {
        if (model.CategoryID <= 0) return ApiResult.Fail("Invalid category id");
        if (string.IsNullOrWhiteSpace(model.CategoryName))
            return ApiResult.Fail("Category name is required");
        return await _repo.UpdateAsync(model);
    }

    public Task<ApiResult> DeleteAsync(int id, int? userId)
    {
        if (id <= 0) return Task.FromResult(ApiResult.Fail("Invalid category id"));
        return _repo.DeleteAsync(id, userId);
    }
}
