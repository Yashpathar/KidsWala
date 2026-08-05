namespace KidsFashionRental.API.Common;

public class ApiResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public object? Data { get; set; }

    public static ApiResult Ok(string message, object? data = null) =>
        new() { Success = true, Message = message, Data = data };

    public static ApiResult Fail(string message, object? data = null) =>
        new() { Success = false, Message = message, Data = data };
}

public class SpResponse
{
    public int Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public int ID { get; set; }
    public string? BookingNo { get; set; }
}
