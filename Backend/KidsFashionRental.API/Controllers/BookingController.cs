using KidsFashionRental.API.Common;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class BookingController : ControllerBase
{
    private readonly IBookingService _service;
    public BookingController(IBookingService service) => _service = service;

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] ReportFilterModel filter)
    {
        ControllerHelper.ApplyReportFilter(User, filter, filter.CompanyID, filter.BranchID);
        return Ok(await _service.GetAllAsync(filter));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
        => Ok(await _service.GetByIdAsync(new BookingByIdModel { BookingID = id }));

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] BookingCreateModel model)
    {
        var userId = ControllerHelper.GetUserId(User);
        if (userId is > 0) model.BookingCreatedBy = userId.Value;
        if (model.CompanyID <= 0) model.CompanyID = ControllerHelper.GetCompanyId(User);
        if (model.BranchID <= 0) model.BranchID = ControllerHelper.GetBranchId(User);
        return Ok(await _service.CreateAsync(model));
    }

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] BookingUpdateModel model)
        => Ok(await _service.UpdateAsync(model));

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
        => Ok(await _service.DeleteAsync(new BookingByIdModel { BookingID = id }));

    [HttpPost("process-return")]
    public async Task<IActionResult> ProcessReturn([FromBody] ReturnProcessModel model)
        => Ok(await _service.ProcessReturnAsync(model));

    [HttpGet("check-availability")]
    public async Task<IActionResult> CheckAvailability([FromQuery] AvailabilityRequestModel model)
        => Ok(await _service.CheckAvailabilityAsync(model));

    [HttpPost("payment")]
    public async Task<IActionResult> AddPayment([FromBody] PaymentCreateModel model)
        => Ok(await _service.AddPaymentAsync(model));
}
