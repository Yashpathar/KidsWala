using System.Text.Json;
using Dapper;
using KidsFashionRental.API.Common;
using KidsFashionRental.API.IRepository;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Repository;

public class MasterRepository : IMasterRepository
{
    public async Task<ApiResult> GetProductsAsync(int? companyId)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", companyId);
            var data = await BaseDataProvider.QueryAsync<ProductModel>("SP_GetAllProducts", p);
            result.Success = true;
            result.Data = data;
            result.Message = "Products loaded";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetProductByCodeAsync(string productCode)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("ProductCode", productCode);
            var data = await BaseDataProvider.QuerySingleAsync<ProductModel>("SP_GetProductByCode", p);
            result.Success = data != null;
            result.Data = data;
            result.Message = result.Success ? "Product found" : "Not found";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public Task<ApiResult> GetCustomersAsync(int? companyId)
    {
        var p = new DynamicParameters();
        p.Add("CompanyID", companyId);
        return RepositoryHelper.QueryListAsync<CustomerModel>("SP_GetAllCustomers", p);
    }

    public async Task<ApiResult> InsertCustomerAsync(CustomerModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", model.CompanyID);
            p.Add("FullName", model.FullName);
            p.Add("ContactNo1", model.ContactNo1);
            p.Add("ContactNo2", model.ContactNo2);
            p.Add("Address", model.Address);
            p.Add("City", model.City);
            p.Add("Notes", model.Notes);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_InsertCustomer", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
            result.Data = response?.ID;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> GetCustomerByMobileAsync(string mobile, int? companyId)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("CompanyID", companyId);
            p.Add("MobileNo", mobile);
            var data = await BaseDataProvider.QuerySingleAsync<CustomerModel>("SP_GetCustomerByMobile", p);
            result.Success = data != null;
            result.Data = data;
            result.Message = result.Success ? "Customer found" : "Customer not found";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public Task<ApiResult> GetRolesAsync() =>
        RepositoryHelper.QueryListAsync<RoleModel>("SP_GetAllRoles");

    public Task<ApiResult> GetRoleRightsAsync(int roleId)
    {
        var p = new DynamicParameters();
        p.Add("RoleID", roleId);
        return RepositoryHelper.QueryListAsync<RoleRightModel>("SP_GetRoleRights", p);
    }

    public async Task<ApiResult> SaveRoleRightsAsync(RoleRightsSaveModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("RoleID", model.RoleID);
            p.Add("RightsJson", JsonSerializer.Serialize(model.Rights, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            }));
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_SaveRoleRights", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }

    public async Task<ApiResult> InsertRoleAsync(RoleInsertModel model)
    {
        var result = new ApiResult();
        try
        {
            var p = new DynamicParameters();
            p.Add("RoleName", model.RoleName);
            p.Add("Description", model.Description);
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>("SP_InsertRole", p);
            result.Success = response?.Success == 1;
            result.Message = response?.Message ?? "Failed";
            result.Data = response;
        }
        catch (Exception ex) { result.Message = ex.Message; }
        return result;
    }
}
