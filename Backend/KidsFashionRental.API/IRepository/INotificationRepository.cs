using KidsFashionRental.API.Common;

namespace KidsFashionRental.API.IRepository;

public interface INotificationRepository
{
    Task<ApiResult> GetAsync(int? companyId, int? userId, int top);
    Task<ApiResult> MarkReadAsync(int notificationId);
}
