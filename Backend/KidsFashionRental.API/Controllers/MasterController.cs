using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class MasterController : ControllerBase
{
    private readonly IMasterService _service;
    public MasterController(IMasterService service) => _service = service;

    private static bool IsSuperAdmin(ClaimsPrincipal user) =>
        ControllerHelper.CanManagePlatform(user);

    [HttpGet("products")]
    public async Task<IActionResult> GetProducts([FromQuery] int? companyId)
        => Ok(await _service.GetProductsAsync(companyId));

    [HttpGet("products/{code}")]
    public async Task<IActionResult> GetProductByCode(string code)
        => Ok(await _service.GetProductByCodeAsync(code));

    [HttpGet("customers")]
    public async Task<IActionResult> GetCustomers([FromQuery] int? companyId)
        => Ok(await _service.GetCustomersAsync(companyId));

    [HttpPost("customers")]
    public async Task<IActionResult> InsertCustomer([FromBody] CustomerModel model)
    {
        if (model.CompanyID <= 0)
            model.CompanyID = ControllerHelper.GetCompanyId(User);
        return Ok(await _service.InsertCustomerAsync(model));
    }

    [HttpGet("customers/by-mobile")]
    public async Task<IActionResult> GetCustomerByMobile([FromQuery] string mobile, [FromQuery] int? companyId)
        => Ok(await _service.GetCustomerByMobileAsync(mobile, companyId ?? ControllerHelper.GetCompanyId(User)));

    [HttpGet("roles")]
    public async Task<IActionResult> GetRoles()
        => Ok(await _service.GetRolesAsync());

    [HttpGet("role-rights/{roleId}")]
    public async Task<IActionResult> GetRoleRights(int roleId)
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _service.GetRoleRightsAsync(roleId));
    }

    [HttpPost("role-rights")]
    public async Task<IActionResult> SaveRoleRights([FromBody] RoleRightsSaveModel model)
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _service.SaveRoleRightsAsync(model));
    }

    [HttpPost("roles")]
    public async Task<IActionResult> InsertRole([FromBody] RoleInsertModel model)
    {
        if (!IsSuperAdmin(User)) return Ok(ApiResult.Fail("Super Admin only"));
        return Ok(await _service.InsertRoleAsync(model));
    }
}
