using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class SizeService : ISizeService
{
    private readonly ISizeRepository _repo;
    public SizeService(ISizeRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(int? companyId) => _repo.GetAllAsync(companyId);
    public Task<ApiResult> GetByIdAsync(int id) => id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid size id")) : _repo.GetByIdAsync(id);

    public async Task<ApiResult> InsertAsync(SizeModel model)
    {
        if (string.IsNullOrWhiteSpace(model.SizeName)) return ApiResult.Fail("Size name is required");
        return await _repo.InsertAsync(model);
    }

    public async Task<ApiResult> UpdateAsync(SizeModel model)
    {
        if (model.SizeID <= 0) return ApiResult.Fail("Invalid size id");
        if (string.IsNullOrWhiteSpace(model.SizeName)) return ApiResult.Fail("Size name is required");
        return await _repo.UpdateAsync(model);
    }

    public Task<ApiResult> DeleteAsync(int id, int? userId) =>
        id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid size id")) : _repo.DeleteAsync(id, userId);
}
