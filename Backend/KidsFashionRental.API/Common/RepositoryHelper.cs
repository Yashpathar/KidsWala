using Dapper;
using KidsFashionRental.API.Model;

namespace KidsFashionRental.API.Common;

public static class RepositoryHelper
{
    public static async Task<ApiResult> QueryListAsync<T>(string spName, DynamicParameters? parameters = null)
    {
        try
        {
            var data = await BaseDataProvider.QueryAsync<T>(spName, parameters);
            return ApiResult.Ok("Data retrieved", data ?? new List<T>());
        }
        catch (Exception ex)
        {
            return ApiResult.Fail(ex.Message);
        }
    }

    public static async Task<ApiResult> ExecuteSpAsync(string spName, DynamicParameters parameters)
    {
        try
        {
            var response = await BaseDataProvider.QuerySingleAsync<SpResponse>(spName, parameters);
            if (response == null)
                return ApiResult.Fail("No response from database. Check stored procedure exists.");

            if (response.Success == 1)
                return ApiResult.Ok(response.Message, new { id = response.ID, bookingNo = response.BookingNo });

            return ApiResult.Fail(string.IsNullOrWhiteSpace(response.Message) ? "Operation failed" : response.Message);
        }
        catch (Exception ex)
        {
            return ApiResult.Fail(ex.Message);
        }
    }
}
