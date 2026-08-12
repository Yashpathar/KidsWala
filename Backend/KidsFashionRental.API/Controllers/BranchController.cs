using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class BranchController : ControllerBase
{
    private readonly IBranchRepository _repo;
    public BranchController(IBranchRepository repo) => _repo = repo;

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        if (!ControllerHelper.CanManagePlatform(User))
            return Ok(await _repo.GetByCompanyAsync(ControllerHelper.GetCompanyId(User)));
        return Ok(await _repo.GetAllAsync());
    }

    [HttpGet("by-company/{companyId:int}")]
    public async Task<IActionResult> GetByCompany(int companyId)
    {
        var cid = ControllerHelper.GetCompanyId(User, companyId);
        return Ok(await _repo.GetByCompanyAsync(cid));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] BranchModel model)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        if (model.CompanyID <= 0) model.CompanyID = ControllerHelper.GetCompanyId(User);
        return Ok(await _repo.InsertAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] BranchModel model)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        if (model.CompanyID <= 0) model.CompanyID = ControllerHelper.GetCompanyId(User);
        return Ok(await _repo.UpdateAsync(model));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (!ControllerHelper.CanUseMasters(User)) return Ok(ApiResult.Fail("Not allowed"));
        return Ok(await _repo.DeleteAsync(id));
    }
}
