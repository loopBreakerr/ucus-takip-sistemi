using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using UcusTakip.Api.Services;
using UcusTakip.Data;
using UcusTakip.Data.Entities;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen();
builder.Services.AddSingleton<IFlightPriceProvider, SimulatedPriceProvider>();

// Bağlantı dizesi User Secrets'tan (ConnectionStrings:Default) okunur; dosyaya yazılmaz.
var connectionString = builder.Configuration.GetConnectionString("Default");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString, npgsql => npgsql.MigrationsAssembly("UcusTakip.Data")));

// Identity çekirdeği (giriş/kayıt endpoint'leri sonraki görevde eklenecek).
builder.Services.AddIdentityCore<ApplicationUser>()
    .AddRoles<IdentityRole<int>>()
    .AddEntityFrameworkStores<AppDbContext>();

var app = builder.Build();

// Başlangıçta "Admin" ve "User" rollerini oluştur. Veritabanına ulaşılamazsa API çökmez.
using (var scope = app.Services.CreateScope())
{
    var logger = scope.ServiceProvider.GetRequiredService<ILoggerFactory>().CreateLogger("VeritabaniBaslangic");
    try
    {
        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        if (!await db.Database.CanConnectAsync(cts.Token))
        {
            logger.LogWarning("Veritabanına bağlanılamadı; rol oluşturma atlandı. API veritabanı olmadan çalışmaya devam ediyor.");
        }
        else
        {
            var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<int>>>();
            foreach (var roleName in new[] { "Admin", "User" })
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new IdentityRole<int>(roleName));
                }
            }
        }
    }
    catch (Exception ex)
    {
        logger.LogWarning(ex, "Veritabanı başlangıç işlemi başarısız oldu (bağlantı dizesi eksik, veritabanı kapalı ya da migration uygulanmamış olabilir); API çalışmaya devam ediyor.");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
