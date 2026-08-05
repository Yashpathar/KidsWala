using Dapper;
using Microsoft.Data.SqlClient;
using System.Data;

namespace KidsFashionRental.API.Common;

public static class BaseDataProvider
{
    private static string ConnectionString =>
        AppConfiguration.ConnectionString;

    public static async Task<List<T>> QueryAsync<T>(string spName, DynamicParameters? parameters = null)
    {
        using var conn = new SqlConnection(ConnectionString);
        var result = await conn.QueryAsync<T>(spName, parameters, commandType: CommandType.StoredProcedure);
        return result.ToList();
    }

    public static async Task<T?> QuerySingleAsync<T>(string spName, DynamicParameters? parameters = null)
    {
        using var conn = new SqlConnection(ConnectionString);
        return await conn.QueryFirstOrDefaultAsync<T>(spName, parameters, commandType: CommandType.StoredProcedure);
    }

    public static async Task ExecuteAsync(string spName, DynamicParameters? parameters = null)
    {
        using var conn = new SqlConnection(ConnectionString);
        await conn.ExecuteAsync(spName, parameters, commandType: CommandType.StoredProcedure);
    }

    public static async Task<SqlMapper.GridReader> QueryMultipleAsync(string spName, DynamicParameters? parameters = null)
    {
        var conn = new SqlConnection(ConnectionString);
        await conn.OpenAsync();
        return await conn.QueryMultipleAsync(spName, parameters, commandType: CommandType.StoredProcedure);
    }
}

public static class AppConfiguration
{
    public static string ConnectionString { get; set; } = string.Empty;
    public static string JwtKey { get; set; } = string.Empty;
    public static string JwtIssuer { get; set; } = string.Empty;
    public static string JwtAudience { get; set; } = string.Empty;
}
