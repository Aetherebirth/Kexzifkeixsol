extends Node

var userdb: SQLite

var user_table: Dictionary = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"name": { "data_type": "text", "not_null": true, "unique": true },
	"password": { "data_type": "text" },
	"guild": { "data_type": "int", "foreign_key": "guilds.id", "default":-1, "not_null": true }
}

var friends_table: Dictionary = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"user1": { "data_type": "text", "not_null": true },
	"user2": { "data_type": "text", "not_null": true },
}

var guild_table: Dictionary = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"name": { "data_type": "text", "not_null": true, "unique": true },
	"level": { "data_type": "int", "default": 0 },
	"owner": { "data_type": "int", "foreign_key": "users.id" }
}


func _ready() -> void:
	userdb = SQLite.new()
	userdb.path = "res://users.db"
	userdb.open_db()
	userdb.create_table("users", user_table)
	userdb.create_table("friends", friends_table)
	userdb.create_table("guilds", guild_table)

func create_user(name: String, password: String) -> void:
	userdb.insert_row("users", {
		"name": name,
		"password": password
	})

func get_user_by_name(name: String) -> Dictionary:
	var user: Array[Dictionary] =  userdb.select_rows("users", "name='%s'"%name, ["*"])
	if len(user) > 0:
		return user[0]
	else:
		return {"id": -1}

func get_friends(name: String) -> Array:
	var f1: Array = userdb.select_rows("friends", "user1='%s'"%name, ["user2"])
	var f2: Array = userdb.select_rows("friends", "user2='%s'"%name, ["user1"])
	var friends: Array = []
	if f1:
		friends.append_array(f1)
	if f2:
		friends.append_array(f2)
	return friends

func get_player_guild(name: String) -> Dictionary:
	var guild_id: int = get_player_guild_id(name)
	print(guild_id)
	if(guild_id!=-1):
		return userdb.select_rows("guilds", "id=%d"%guild_id, ["*"])[0]
	else:
		return {"id":-1}

func get_player_guild_id(name: String) -> int:
	return userdb.select_rows("users", "name='%s'"%name, ["guild"])[0].guild
		
func get_user_common_data(name: String) -> Dictionary:
	var friends: Array = get_friends(name)
	var user: Dictionary = get_user_by_name(name)
	print(user)
	return {
		"id": user.id,
		"friends": friends,
		"name": name,
		"guild": get_player_guild(name)
	}
	
