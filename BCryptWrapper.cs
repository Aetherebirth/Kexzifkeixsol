using Godot;
using BCrypt;

[GlobalClass]
public partial class BCryptWrapper : Node
{
	public static string HashPassword(string password)
	{
		return BCrypt.Net.BCrypt.HashPassword(password);
	}
	public static bool VerifyPassword(string password, string hashedPassword)
	{
	   return BCrypt.Net.BCrypt.Verify(password, hashedPassword);
	}
	public static string EnhancedHashPassword(string password)
	{
		return BCrypt.Net.BCrypt.EnhancedHashPassword(password);
	}
	public static bool EnhancedVerifyPassword(string password, string hashedPassword)
	{
	   return BCrypt.Net.BCrypt.EnhancedVerify(password, hashedPassword);
	}
}
