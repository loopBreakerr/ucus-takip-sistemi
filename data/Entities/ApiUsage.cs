namespace UcusTakip.Data.Entities;

public class ApiUsage
{
    public int Id { get; set; }

    /// <summary>Ör. 2026-10.</summary>
    public string Month { get; set; } = string.Empty;

    public int RequestCount { get; set; }
}
