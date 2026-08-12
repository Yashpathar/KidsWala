using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class CategoryController : ControllerBase
{
    private readonly ICategoryService _service;
    public CategoryController(ICategoryService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? companyId)
    {
        var cid = ControllerHelper.GetCompanyId(User, companyId);
        return Ok(await _service.GetAllAsync(cid > 0 ? cid : null));
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
        => Ok(await _service.GetByIdAsync(id));

    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] CategoryModel model)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        model.CreatedBy = ControllerHelper.GetUserId(User);
        ControllerHelper.ApplyCompanyId(model, ControllerHelper.GetCompanyId(User));
        return Ok(await _service.InsertAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] CategoryModel model)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        model.ModifiedBy = ControllerHelper.GetUserId(User);
        ControllerHelper.ApplyCompanyId(model, ControllerHelper.GetCompanyId(User));
        return Ok(await _service.UpdateAsync(model));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        return Ok(await _service.DeleteAsync(id, ControllerHelper.GetUserId(User)));
    }
}
