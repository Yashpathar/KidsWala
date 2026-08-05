using System.Security.Claims;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _service;
    public AuthController(IAuthService service) => _service = service;

    [AllowAnonymous]
    [HttpGet("companies")]
    public async Task<IActionResult> GetCompanies()
        => Ok(await _service.GetCompaniesForLoginAsync());

    [AllowAnonymous]
    [HttpPost("verify")]
    public async Task<IActionResult> Verify([FromBody] LoginModel model)
        => Ok(await _service.VerifyAsync(model));

    [AllowAnonymous]
    [HttpPost("session")]
    public async Task<IActionResult> CreateSession([FromBody] LoginModel model)
        => Ok(await _service.LoginAsync(model));

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginModel model)
        => Ok(await _service.LoginAsync(model));

    [Authorize]
    [HttpGet("menu-rights")]
    public async Task<IActionResult> GetMyMenuRights()
    {
        var roleIdClaim = User.FindFirst("RoleID")?.Value;
        if (!int.TryParse(roleIdClaim, out var roleId) || roleId <= 0)
            return Ok(ApiResult.Fail("Invalid session"));
        return Ok(await _service.GetMenuRightsForRoleAsync(roleId));
    }
}
