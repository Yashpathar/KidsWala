using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class NotificationController : ControllerBase
{
    private readonly INotificationRepository _repo;
    public NotificationController(INotificationRepository repo) => _repo = repo;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int? companyId, [FromQuery] int top = 20)
        => Ok(await _repo.GetAsync(companyId ?? ControllerHelper.GetCompanyId(User), ControllerHelper.GetUserId(User), top));

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkRead(int id)
        => Ok(await _repo.MarkReadAsync(id));
}
