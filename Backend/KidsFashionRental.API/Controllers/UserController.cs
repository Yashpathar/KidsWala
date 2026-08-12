using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly IUserService _service;
    public UserController(IUserService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? companyId, [FromQuery] int? branchId)
    {
        var cid = ControllerHelper.GetCompanyId(User, companyId);
        var bid = ControllerHelper.GetBranchId(User, branchId);
        return Ok(await _service.GetAllAsync(cid > 0 ? cid : null, bid > 0 ? bid : null));
    }

    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(int id)
        => Ok(await _service.GetByIdAsync(id));

    [HttpPost]
    public async Task<IActionResult> Insert([FromBody] UserMasterModel model)
    {
        if (model.CompanyID is null or <= 0)
            model.CompanyID = ControllerHelper.GetCompanyId(User);
        if (model.BranchID is null or <= 0)
        {
            var bId = ControllerHelper.GetBranchId(User);
            if (bId > 0) model.BranchID = bId;
        }
        return Ok(await _service.InsertAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UserMasterModel model)
    {
        if (model.CompanyID is null or <= 0)
            model.CompanyID = ControllerHelper.GetCompanyId(User);
        if (model.BranchID is null or <= 0)
        {
            var bId = ControllerHelper.GetBranchId(User);
            if (bId > 0) model.BranchID = bId;
        }
        return Ok(await _service.UpdateAsync(model));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
        => Ok(await _service.DeleteAsync(id));
}
