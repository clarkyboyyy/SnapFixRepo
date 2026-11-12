
using AppBackend.Data;
using AppBackend.Model;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AppBackend.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController : ControllerBase
{
    private readonly AppDbContext _context;

    public ReportsController(AppDbContext context)
    {
        _context = context;
    }

    // Get all saved reports
    [HttpGet]
    public async Task<IActionResult> GetReports()
    {
        var reports = await _context.Reports
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();

        return Ok(reports);
    }

    // Save a new report
    [HttpPost]
    public async Task<IActionResult> CreateReport(Report report)
    {
        report.Id = 0;
        report.CreatedAt = DateTime.UtcNow;
        report.Status = "Pending";

        _context.Reports.Add(report);
        await _context.SaveChangesAsync();

        return Ok(report);
    }
}
