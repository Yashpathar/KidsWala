using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class ReportController : ControllerBase
{
    private readonly IDashboardService _service;
    public ReportController(IDashboardService service) => _service = service;

    private void ApplyFilter(ReportFilterModel filter) =>
        ControllerHelper.ApplyReportFilter(User, filter, filter.CompanyID, filter.BranchID);

    [HttpGet("today-delivery")]
    public async Task<IActionResult> TodayDelivery([FromQuery] ReportFilterModel filter)
    {
        ApplyFilter(filter);
        return Ok(await _service.TodayDeliveryReportAsync(filter));
    }

    [HttpGet("today-return")]
    public async Task<IActionResult> TodayReturn([FromQuery] ReportFilterModel filter)
    {
        ApplyFilter(filter);
        return Ok(await _service.TodayReturnReportAsync(filter));
    }

    [HttpGet("payments")]
    public async Task<IActionResult> Payments([FromQuery] ReportFilterModel filter)
    {
        ApplyFilter(filter);
        return Ok(await _service.PaymentReportAsync(filter));
    }
}
