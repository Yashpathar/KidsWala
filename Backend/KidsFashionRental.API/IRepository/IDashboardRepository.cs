using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IRepository;

public interface IDashboardRepository
{
    Task<ApiResult> GetCountsAsync(ReportFilterModel filter);
    Task<ApiResult> GetMonthlyIncomeAsync(ReportFilterModel filter);
    Task<ApiResult> GetBookingStatusChartAsync(ReportFilterModel filter);
    Task<ApiResult> TodayDeliveryReportAsync(ReportFilterModel filter);
    Task<ApiResult> TodayReturnReportAsync(ReportFilterModel filter);
    Task<ApiResult> GetTopProductsAsync(ReportFilterModel filter, int topN = 5);
    Task<ApiResult> GetSummaryAsync(ReportFilterModel filter);
    Task<ApiResult> PaymentReportAsync(ReportFilterModel filter);
}
