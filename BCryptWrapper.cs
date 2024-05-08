using Godot;
using BCrypt;

[GlobalClass]
public partial class BCryptWrapper: Node
{
	public string HashPassword(string password)
	{
		return BCrypt.Net.BCrypt.HashPassword(password);
	}
	public bool VerifyPassword(string password, string hashedPassword)
	{
	   return BCrypt.Net.BCrypt.Verify(password, hashedPassword);
	}
	public string EnhancedHashPassword(string password)
	{
		return BCrypt.Net.BCrypt.EnhancedHashPassword(password);
	}
	public bool EnhancedVerifyPassword(string password, string hashedPassword)
	{
	   return BCrypt.Net.BCrypt.EnhancedVerify(password, hashedPassword);
	}
}
