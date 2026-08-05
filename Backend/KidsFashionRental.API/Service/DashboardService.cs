using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.IService;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Service;

public class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repo;
    public DashboardService(IDashboardRepository repo) => _repo = repo;

    public Task<ApiResult> GetCountsAsync(ReportFilterModel filter) => _repo.GetCountsAsync(filter);
    public async Task<ApiResult> GetChartsAsync(ReportFilterModel filter)
    {
        var income = await _repo.GetMonthlyIncomeAsync(filter);
        var status = await _repo.GetBookingStatusChartAsync(filter);
        return new ApiResult
        {
            Success = true,
            Message = "Charts loaded",
            Data = new { monthlyIncome = income.Data, bookingStatus = status.Data }
        };
    }
    public Task<ApiResult> TodayDeliveryReportAsync(ReportFilterModel filter) => _repo.TodayDeliveryReportAsync(filter);
    public Task<ApiResult> TodayReturnReportAsync(ReportFilterModel filter) => _repo.TodayReturnReportAsync(filter);
    public Task<ApiResult> GetSummaryAsync(ReportFilterModel filter) => _repo.GetSummaryAsync(filter);
    public Task<ApiResult> PaymentReportAsync(ReportFilterModel filter) => _repo.PaymentReportAsync(filter);
}
