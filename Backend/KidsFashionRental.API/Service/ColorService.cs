using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class ColorService : IColorService
{
    private readonly IColorRepository _repo;
    public ColorService(IColorRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(int? companyId) => _repo.GetAllAsync(companyId);
    public Task<ApiResult> GetByIdAsync(int id) => id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid color id")) : _repo.GetByIdAsync(id);

    public async Task<ApiResult> InsertAsync(ColorModel model)
    {
        if (string.IsNullOrWhiteSpace(model.ColorName)) return ApiResult.Fail("Color name is required");
        return await _repo.InsertAsync(model);
    }

    public async Task<ApiResult> UpdateAsync(ColorModel model)
    {
        if (model.ColorID <= 0) return ApiResult.Fail("Invalid color id");
        if (string.IsNullOrWhiteSpace(model.ColorName)) return ApiResult.Fail("Color name is required");
        return await _repo.UpdateAsync(model);
    }

    public Task<ApiResult> DeleteAsync(int id, int? userId) =>
        id <= 0 ? Task.FromResult(ApiResult.Fail("Invalid color id")) : _repo.DeleteAsync(id, userId);
}
