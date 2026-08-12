using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class SizeController : ControllerBase
{
    private readonly ISizeService _service;
    public SizeController(ISizeService service) => _service = service;

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
    public async Task<IActionResult> Insert([FromBody] SizeModel model)
    {
        model.CreatedBy = ControllerHelper.GetUserId(User);
        ControllerHelper.ApplyCompanyId(model, ControllerHelper.GetCompanyId(User));
        return Ok(await _service.InsertAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] SizeModel model)
    {
        model.ModifiedBy = ControllerHelper.GetUserId(User);
        ControllerHelper.ApplyCompanyId(model, ControllerHelper.GetCompanyId(User));
        return Ok(await _service.UpdateAsync(model));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
        => Ok(await _service.DeleteAsync(id, ControllerHelper.GetUserId(User)));
}
