using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class DashboardRepository : IDashboardRepository
{
    public async Task<ApiResult> GetCountsAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QuerySingleAsync<DashboardCountsModel>("SP_DashboardCounts", p);
            result.Success = true;
            result.Data = data;
            result.Message = "Dashboard loaded";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetMonthlyIncomeAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QueryAsync<ChartDataModel>("SP_MonthlyIncome", p);
            result.Success = true;
            result.Data = data;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetBookingStatusChartAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QueryAsync<ChartDataModel>("SP_BookingStatusChart", p);
            result.Success = true;
            result.Data = data;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> TodayDeliveryReportAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("ReportDate", filter.ReportDate);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QueryAsync<object>("SP_TodayDeliveryReport", p);
            result.Success = true;
            result.Data = data;
            result.Message = "Delivery report loaded";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> TodayReturnReportAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("ReportDate", filter.ReportDate);
            p.Add("FilterUserID", filter.FilterUserID);
            var data = await BaseDataProvider.QueryAsync<TodayReturnReportModel>("SP_TodayReturnReport", p);
            result.Success = true;
            result.Data = data;
            result.Message = "Return report loaded";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetTopProductsAsync(ReportFilterModel filter, int topN = 5)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("FilterUserID", filter.FilterUserID);
            p.Add("TopN", topN);
            var data = await BaseDataProvider.QueryAsync<TopProductModel>("SP_TopProducts", p);
            result.Success = true;
            result.Data = data;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetSummaryAsync(ReportFilterModel filter)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", filter.CompanyID);
            p.Add("BranchID", filter.BranchID);
            p.Add("ReportDate", filter.ReportDate ?? DateTime.Today);
            p.Add("FilterUserID", filter.FilterUserID);

            var counts = await GetCountsAsync(filter);
            var income = await GetMonthlyIncomeAsync(filter);
            var status = await GetBookingStatusChartAsync(filter);
            var top = await GetTopProductsAsync(filter, 5);
            var deliveries = await BaseDataProvider.QueryAsync<TodayDeliveryDashModel>("SP_TodayDeliveryReport", p);
            var returnRows = await BaseDataProvider.QueryAsync<TodayReturnDashModel>("SP_TodayReturnReport", p);

            var countsModel = counts.Data as DashboardCountsModel ?? new DashboardCountsModel();
            countsModel.NetProfit = countsModel.TotalIncome - countsModel.TotalExpenses;

            result.Success = counts.Success;
            result.Message = counts.Message;
            result.Data = new DashboardSummaryModel
            {
                Counts = countsModel,
                MonthlyIncome = income.Data as List<ChartDataModel> ?? [],
                BookingStatus = status.Data as List<ChartDataModel> ?? [],
                TopProducts = top.Data as List<TopProductModel> ?? [],
                TodayDeliveries = deliveries,
                TodayReturns = returnRows
            };
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public Task<ApiResult> PaymentReportAsync(ReportFilterModel filter)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", filter.CompanyID);
        p.Add("BranchID", filter.BranchID);
        p.Add("FromDate", filter.FromDate ?? filter.ReportDate);
        p.Add("ToDate", filter.ToDate ?? filter.ReportDate);
        p.Add("FilterUserID", filter.FilterUserID);
        return RepositoryHelper.QueryListAsync<object>("SP_PaymentReport", p);
    }
}
