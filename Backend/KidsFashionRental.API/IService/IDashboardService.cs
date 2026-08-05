using KidsFashionRental.API.Common;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.IService;

public interface IDashboardService
{
    Task<ApiResult> GetCountsAsync(ReportFilterModel filter);
    Task<ApiResult> GetChartsAsync(ReportFilterModel filter);
    Task<ApiResult> TodayDeliveryReportAsync(ReportFilterModel filter);
    Task<ApiResult> TodayReturnReportAsync(ReportFilterModel filter);
    Task<ApiResult> GetSummaryAsync(ReportFilterModel filter);
    Task<ApiResult> PaymentReportAsync(ReportFilterModel filter);
}
