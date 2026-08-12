using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _service;
    public DashboardController(IDashboardService service) => _service = service;

    private ReportFilterModel BuildFilter(int? companyId, int? branchId = null) {
        var f = new ReportFilterModel();
        ControllerHelper.ApplyReportFilter(User, f, companyId, branchId);
        return f;
    }

    [HttpGet("counts")]
    public async Task<IActionResult> GetCounts([FromQuery] int? companyId, [FromQuery] int? branchId)
        => Ok(await _service.GetCountsAsync(BuildFilter(companyId, branchId)));

    [HttpGet("charts")]
    public async Task<IActionResult> GetCharts([FromQuery] int? companyId, [FromQuery] int? branchId)
        => Ok(await _service.GetChartsAsync(BuildFilter(companyId, branchId)));

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary([FromQuery] int? companyId, [FromQuery] int? branchId)
        => Ok(await _service.GetSummaryAsync(BuildFilter(companyId, branchId)));
}
