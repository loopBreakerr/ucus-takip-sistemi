using Microsoft.AspNetCore.Identity;

namespace UcusTakip.Data;

public static class IdentitySetup
{
    public const string AdminRole = "Admin";
    public const string UserRole = "User";

    /// <summary>api ve web için ortak Identity kuralları.</summary>
    public static void Configure(IdentityOptions options)
    {
        options.User.RequireUniqueEmail = true;

        options.Password.RequiredLength = 6;
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = false;
        options.Password.RequireUppercase = false;
        options.Password.RequireNonAlphanumeric = false;
        options.Password.RequiredUniqueChars = 1;
    }
}
