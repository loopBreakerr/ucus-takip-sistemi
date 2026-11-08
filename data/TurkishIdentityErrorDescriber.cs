using Microsoft.AspNetCore.Identity;

namespace UcusTakip.Data;

/// <summary>Identity hata mesajlarını Türkçe verir (api ve web ortak kullanır).</summary>
public class TurkishIdentityErrorDescriber : IdentityErrorDescriber
{
    public override IdentityError DuplicateEmail(string email) =>
        new() { Code = nameof(DuplicateEmail), Description = "Bu e-posta adresi zaten kayıtlı." };

    public override IdentityError DuplicateUserName(string userName) =>
        new() { Code = nameof(DuplicateUserName), Description = "Bu e-posta adresi zaten kayıtlı." };

    public override IdentityError InvalidEmail(string? email) =>
        new() { Code = nameof(InvalidEmail), Description = "Geçerli bir e-posta adresi girin." };

    public override IdentityError InvalidUserName(string? userName) =>
        new() { Code = nameof(InvalidUserName), Description = "Geçerli bir e-posta adresi girin." };

    public override IdentityError PasswordTooShort(int length) =>
        new() { Code = nameof(PasswordTooShort), Description = $"Parola en az {length} karakter olmalıdır." };

    public override IdentityError PasswordRequiresDigit() =>
        new() { Code = nameof(PasswordRequiresDigit), Description = "Parola en az 1 rakam içermelidir." };

    public override IdentityError PasswordRequiresLower() =>
        new() { Code = nameof(PasswordRequiresLower), Description = "Parola en az 1 küçük harf içermelidir." };

    public override IdentityError PasswordRequiresUpper() =>
        new() { Code = nameof(PasswordRequiresUpper), Description = "Parola en az 1 büyük harf içermelidir." };

    public override IdentityError PasswordRequiresNonAlphanumeric() =>
        new() { Code = nameof(PasswordRequiresNonAlphanumeric), Description = "Parola en az 1 özel karakter içermelidir." };

    public override IdentityError PasswordRequiresUniqueChars(int uniqueChars) =>
        new() { Code = nameof(PasswordRequiresUniqueChars), Description = $"Parola en az {uniqueChars} farklı karakter içermelidir." };

    public override IdentityError DefaultError() =>
        new() { Code = nameof(DefaultError), Description = "Beklenmeyen bir hata oluştu." };
}
