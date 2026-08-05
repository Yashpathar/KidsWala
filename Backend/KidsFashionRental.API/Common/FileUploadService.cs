namespace KidsFashionRental.API.Common;

public interface IFileUploadService
{
    Task<ApiResult> UploadImageAsync(IFormFile file);
    Task<ApiResult> UploadDocumentAsync(IFormFile file);
}

public class FileUploadService : IFileUploadService
{
    private readonly IWebHostEnvironment _env;
    private readonly string[] _imageExtensions = [".jpg", ".jpeg", ".png", ".gif", ".webp"];
    private readonly string[] _docExtensions = [".pdf", ".doc", ".docx", ".xls", ".xlsx"];

    public FileUploadService(IWebHostEnvironment env) => _env = env;

    public async Task<ApiResult> UploadImageAsync(IFormFile file)
        => await SaveFileAsync(file, "uploads/images", _imageExtensions, 5);

    public async Task<ApiResult> UploadDocumentAsync(IFormFile file)
        => await SaveFileAsync(file, "uploads/documents", _docExtensions, 10);

    private async Task<ApiResult> SaveFileAsync(IFormFile file, string folder, string[] allowedExt, int maxMb)
    {
        var result = new ApiResult();
        if (file == null || file.Length == 0)
        {
            result.Message = "No file uploaded";
            return result;
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExt.Contains(ext))
        {
            result.Message = "Invalid file type";
            return result;
        }

        if (file.Length > maxMb * 1024 * 1024)
        {
            result.Message = $"File size exceeds {maxMb}MB";
            return result;
        }

        var uploadPath = Path.Combine(_env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot"), folder);
        Directory.CreateDirectory(uploadPath);

        var fileName = $"{Guid.NewGuid()}{ext}";
        var fullPath = Path.Combine(uploadPath, fileName);

        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        result.Success = true;
        result.Message = "File uploaded successfully";
        result.Data = $"/{folder.Replace("\\", "/")}/{fileName}";
        return result;
    }
}
