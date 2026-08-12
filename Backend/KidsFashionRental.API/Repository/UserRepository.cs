using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class UserRepository : IUserRepository
{
    public Task<ApiResult> GetAllAsync(int? companyId, int? branchId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        p.Add("BranchID", branchId);
        return RepositoryHelper.QueryListAsync<UserMasterModel>("SP_GetAllUsers", p);
    }

    public async Task<ApiResult> GetByIdAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("UserID", id);
            var data = await BaseDataProvider.QuerySingleAsync<UserMasterModel>("SP_GetUserByID", p);
            result.Success = data != null;
            result.Data = data;
            result.Message = result.Success ? "User found" : "Not found";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertAsync(UserMasterModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("BranchID", model.BranchID);
            p.Add("RoleID", model.RoleID);
            p.Add("Username", model.Username);
            p.Add("PasswordHash", model.Password);
            p.Add("FullName", model.FullName);
            p.Add("Email", model.Email);
            p.Add("MobileNo", model.MobileNo);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_InsertUser", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Insert failed";
            result.Data = response?.ID;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> UpdateAsync(UserMasterModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("UserID", model.UserID);
            p.Add("CompanyID", model.CompanyID);
            p.Add("BranchID", model.BranchID);
            p.Add("RoleID", model.RoleID);
            p.Add("Username", model.Username);
            p.Add("PasswordHash", model.Password);
            p.Add("FullName", model.FullName);
            p.Add("Email", model.Email);
            p.Add("MobileNo", model.MobileNo);
            p.Add("IsActive", model.IsActive);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_UpdateUser", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Update failed";
            result.Data = response?.ID;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> DeleteAsync(int id)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("UserID", id);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_DeleteUser", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Delete failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
