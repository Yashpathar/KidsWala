using KidsFashionRental.API.Common;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KidsFashionRental.API.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class UploadController : ControllerBase
{
    private readonly IFileUploadService _uploadService;
    public UploadController(IFileUploadService uploadService) => _uploadService = uploadService;

    [HttpPost("image")]
    public async Task<IActionResult> UploadImage(IFormFile file)
        => Ok(await _uploadService.UploadImageAsync(file));

    [HttpPost("document")]
    public async Task<IActionResult> UploadDocument(IFormFile file)
        => Ok(await _uploadService.UploadDocumentAsync(file));
}
