using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace FitAppAPI.Services
{
    public class JwtService
    {
        private readonly string _secretKey;
        private readonly string _issuer;
        private readonly string _audience;

        public JwtService(IConfiguration configuration)
        {
            _secretKey = configuration["Jwt:SecretKey"];
            _issuer = configuration["Jwt:Issuer"];
            _audience = configuration["Jwt:Audience"];
        }

        public string GenerateToken(string username, string userId)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
    {
        new Claim(ClaimTypes.Name, username),
        new Claim(ClaimTypes.NameIdentifier, userId), 
    };

            var token = new JwtSecurityToken(
                _issuer,
                _audience,
                claims,
                expires: DateTime.Now.AddDays(1),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }



        public ClaimsPrincipal GetPrincipalFromToken(string token)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
            var tokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidIssuer = _issuer,
                ValidAudience = _audience,
                IssuerSigningKey = securityKey
            };

            var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out var validatedToken);
            return principal;
        }
    }
}
