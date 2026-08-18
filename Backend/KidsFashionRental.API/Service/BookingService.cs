using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class BookingService : IBookingService
{
    private readonly IBookingRepository _repo;
    public BookingService(IBookingRepository repo) => _repo = repo;

    public Task<ApiResult> GetAllAsync(ReportFilterModel filter) => _repo.GetAllAsync(filter);
    public Task<ApiResult> GetByIdAsync(BookingByIdModel model) => _repo.GetByIdAsync(model);
    public Task<ApiResult> CreateAsync(BookingCreateModel model)
    {
        if (model.CustomerID <= 0)
            return Task.FromResult(ApiResult.Fail("Please select a customer"));
        if (model.BookingCreatedBy <= 0)
            return Task.FromResult(ApiResult.Fail("Session expired. Please login again."));
        if (model.Items == null || model.Items.Count == 0)
            return Task.FromResult(ApiResult.Fail("Add at least one product to the booking"));
        if (model.Items.Any(i => i.ProductID <= 0))
            return Task.FromResult(ApiResult.Fail("Invalid product in booking items. Search and add the product again."));
        return _repo.CreateAsync(model);
    }
    public Task<ApiResult> UpdateAsync(BookingUpdateModel model) => _repo.UpdateAsync(model);
    public Task<ApiResult> DeleteAsync(BookingByIdModel model) => _repo.DeleteAsync(model);
    public Task<ApiResult> ProcessReturnAsync(ReturnProcessModel model) => _repo.ProcessReturnAsync(model);
    public Task<ApiResult> CheckAvailabilityAsync(AvailabilityRequestModel model) => _repo.CheckAvailabilityAsync(model);
    public Task<ApiResult> GetProductStatusByCodeAsync(string code, DateTime? deliveryDate = null, DateTime? returnDate = null)
        => _repo.GetProductStatusByCodeAsync(code, deliveryDate, returnDate);
    public Task<ApiResult> AddPaymentAsync(PaymentCreateModel model) => _repo.AddPaymentAsync(model);
}
