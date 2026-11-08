using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using UcusTakip.Api.Services;
using UcusTakip.Data;
using UcusTakip.Data.Entities;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        Description = "Giriş yanıtındaki token değerini yapıştırın."
    });
    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});
builder.Services.AddSingleton<IFlightPriceProvider, SimulatedPriceProvider>();

// Bağlantı dizesi User Secrets'tan (ConnectionStrings:Default) okunur; dosyaya yazılmaz.
var connectionString = builder.Configuration.GetConnectionString("Default");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString, npgsql => npgsql.MigrationsAssembly("UcusTakip.Data")));

// Identity çekirdeği: benzersiz e-posta, parola en az 6 karakter + 1 rakam.
builder.Services.AddIdentityCore<ApplicationUser>(IdentitySetup.Configure)
    .AddRoles<IdentityRole<int>>()
    .AddErrorDescriber<TurkishIdentityErrorDescriber>()
    .AddEntityFrameworkStores<AppDbContext>();

// JWT kimlik doğrulaması. Jwt:Key yoksa API çökmez; auth endpoint'leri 503 döner.
JwtSettings jwtSettings;
using (var startupLoggerFactory = LoggerFactory.Create(b => b.AddConsole()))
{
    jwtSettings = JwtSettings.FromConfiguration(builder.Configuration, startupLoggerFactory.CreateLogger("Jwt"));
}
builder.Services.AddSingleton(jwtSettings);
builder.Services.AddSingleton<JwtTokenService>();
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwtSettings.Issuer,
            ValidateAudience = true,
            ValidAudience = jwtSettings.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = jwtSettings.SigningKey,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = "email",
            RoleClaimType = "role"
        };
    });
builder.Services.AddAuthorization();

if (builder.Environment.IsDevelopment())
{
    builder.Services.AddCors(options => options.AddPolicy("FlutterLocal", policy => policy
        .WithOrigins("http://localhost:7357")
        .WithMethods("GET", "POST")
        .WithHeaders("Authorization", "Content-Type")));
}

var app = builder.Build();

// Başlangıçta rolleri ve (tanımlıysa) yönetici hesabını oluştur. Veritabanına ulaşılamazsa API çökmez.
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
            foreach (var roleName in new[] { IdentitySetup.AdminRole, IdentitySetup.UserRole })
            {
                if (!await roleManager.RoleExistsAsync(roleName))
                {
                    await roleManager.CreateAsync(new IdentityRole<int>(roleName));
                }
            }

            // Yönetici hesabı: Admin:Email ve Admin:Password tanımlıysa ve kullanıcı yoksa oluştur.
            var adminEmail = builder.Configuration["Admin:Email"];
            var adminPassword = builder.Configuration["Admin:Password"];
            if (!string.IsNullOrWhiteSpace(adminEmail) && !string.IsNullOrEmpty(adminPassword))
            {
                var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
                if (await userManager.FindByEmailAsync(adminEmail.Trim()) is null)
                {
                    var admin = new ApplicationUser
                    {
                        UserName = adminEmail.Trim(),
                        Email = adminEmail.Trim(),
                        EmailConfirmed = true
                    };
                    var created = await userManager.CreateAsync(admin, adminPassword);
                    if (created.Succeeded)
                    {
                        await userManager.AddToRoleAsync(admin, IdentitySetup.AdminRole);
                        logger.LogInformation("Yönetici hesabı oluşturuldu: {Email}", admin.Email);
                    }
                    else
                    {
                        logger.LogWarning("Yönetici hesabı oluşturulamadı: {Errors}",
                            string.Join(" | ", created.Errors.Select(e => e.Code)));
                    }
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
    app.UseCors("FlutterLocal");
}

app.UseHttpsRedirection();

// Jwt:Key yoksa kimlik doğrulama endpoint'leri 503 döner (arama endpoint'i etkilenmez).
if (!jwtSettings.IsConfigured)
{
    app.Use(async (context, next) =>
    {
        if (context.Request.Path.StartsWithSegments("/api/auth"))
        {
            context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
            await context.Response.WriteAsJsonAsync(new { error = "Kimlik doğrulama yapılandırılmamış." });
            return;
        }
        await next();
    });
}

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
