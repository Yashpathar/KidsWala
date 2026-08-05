using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class CompanyController : ControllerBase
{
    private readonly ICompanyRepository _repo;
    public CompanyController(ICompanyRepository repo) => _repo = repo;

    private static bool IsSuperAdmin(ClaimsPrincipal user) =>
        ControllerHelper.CanManagePlatform(user);

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _repo.GetAllAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CompanyModel model)
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _repo.InsertAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] CompanyModel model)
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _repo.UpdateAsync(model));
    }
}
