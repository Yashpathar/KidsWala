using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface IBookingService
{
    Task<ApiResult> GetAllAsync(ReportFilterModel filter);
    Task<ApiResult> GetByIdAsync(BookingByIdModel model);
    Task<ApiResult> CreateAsync(BookingCreateModel model);
    Task<ApiResult> UpdateAsync(BookingUpdateModel model);
    Task<ApiResult> DeleteAsync(BookingByIdModel model);
    Task<ApiResult> ProcessReturnAsync(ReturnProcessModel model);
    Task<ApiResult> CheckAvailabilityAsync(AvailabilityRequestModel model);
    Task<ApiResult> GetProductStatusByCodeAsync(string code, DateTime? deliveryDate = null, DateTime? returnDate = null);
    Task<ApiResult> AddPaymentAsync(PaymentCreateModel model);
}
