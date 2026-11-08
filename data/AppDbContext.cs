using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using UcusTakip.Data.Entities;

namespace UcusTakip.Data;

public class AppDbContext : IdentityDbContext<ApplicationUser, IdentityRole<int>, int>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Aircraft> Aircraft => Set<Aircraft>();
    public DbSet<Flight> Flights => Set<Flight>();
    public DbSet<UserFlight> UserFlights => Set<UserFlight>();
    public DbSet<PriceAlert> PriceAlerts => Set<PriceAlert>();
    public DbSet<PriceHistory> PriceHistories => Set<PriceHistory>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<ApiUsage> ApiUsages => Set<ApiUsage>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // DBML: Users.email unique
        builder.Entity<ApplicationUser>()
            .HasIndex(u => u.NormalizedEmail)
            .HasDatabaseName("EmailIndex")
            .IsUnique();

        builder.Entity<Aircraft>(e =>
        {
            e.ToTable("Aircraft");
            e.HasKey(x => x.Id);
            e.Property(x => x.IcaoHex).HasMaxLength(10);
            e.Property(x => x.Callsign).HasMaxLength(20);
            e.HasIndex(x => x.IcaoHex).IsUnique();
        });

        builder.Entity<Flight>(e =>
        {
            e.ToTable("Flights");
            e.HasKey(x => x.Id);
            e.Property(x => x.FlightNumber).IsRequired().HasMaxLength(10);
            e.Property(x => x.Origin).IsRequired().HasMaxLength(3);
            e.Property(x => x.Destination).IsRequired().HasMaxLength(3);
            e.HasIndex(x => new { x.FlightNumber, x.FlightDate });
            e.HasOne(x => x.Aircraft)
                .WithMany(a => a.Flights)
                .HasForeignKey(x => x.AircraftId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<UserFlight>(e =>
        {
            e.ToTable("UserFlights");
            e.HasKey(x => new { x.UserId, x.FlightId });
            e.HasOne(x => x.User)
                .WithMany(u => u.UserFlights)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Flight)
                .WithMany(f => f.UserFlights)
                .HasForeignKey(x => x.FlightId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<PriceAlert>(e =>
        {
            e.ToTable("PriceAlerts");
            e.HasKey(x => x.Id);
            e.Property(x => x.Origin).IsRequired().HasMaxLength(3);
            e.Property(x => x.Destination).IsRequired().HasMaxLength(3);
            e.Property(x => x.TargetPrice).HasPrecision(18, 2);
            e.Property(x => x.Currency).HasMaxLength(3);
            e.Property(x => x.IsActive).HasDefaultValue(true);
            e.HasIndex(x => new { x.UserId, x.IsActive });
            e.HasOne(x => x.User)
                .WithMany(u => u.PriceAlerts)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        builder.Entity<PriceHistory>(e =>
        {
            e.ToTable("PriceHistory");
            e.HasKey(x => x.Id);
            e.Property(x => x.Origin).IsRequired().HasMaxLength(3);
            e.Property(x => x.Destination).IsRequired().HasMaxLength(3);
            e.Property(x => x.Price).HasPrecision(18, 2);
            e.Property(x => x.Currency).HasMaxLength(3);
            e.HasIndex(x => new { x.Origin, x.Destination, x.TravelDate, x.CheckedAt });
        });

        builder.Entity<Notification>(e =>
        {
            e.ToTable("Notifications");
            e.HasKey(x => x.Id);
            e.Property(x => x.Message).IsRequired();
            e.Property(x => x.IsRead).HasDefaultValue(false);
            e.HasIndex(x => new { x.UserId, x.IsRead });
            e.HasOne(x => x.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Alert)
                .WithMany(a => a.Notifications)
                .HasForeignKey(x => x.AlertId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        builder.Entity<ApiUsage>(e =>
        {
            e.ToTable("ApiUsage");
            e.HasKey(x => x.Id);
            e.Property(x => x.Month).IsRequired().HasMaxLength(7);
            e.Property(x => x.RequestCount).HasDefaultValue(0);
            e.HasIndex(x => x.Month).IsUnique();
        });
    }
}
