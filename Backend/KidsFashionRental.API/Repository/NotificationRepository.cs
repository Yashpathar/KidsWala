using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class NotificationRepository : INotificationRepository
{
    public Task<ApiResult> GetAsync(int? companyId, int? userId, int top)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        p.Add("UserID", userId);
        p.Add("TopN", top);
        return RepositoryHelper.QueryListAsync<NotificationModel>("SP_GetNotifications", p);
    }

    public async Task<ApiResult> MarkReadAsync(int notificationId)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("NotificationID", notificationId);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_MarkNotificationRead", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
