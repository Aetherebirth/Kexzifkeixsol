extends Node

var userdb: SQLite

var user_table = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"username": { "data_type": "text", "not_null": true, "unique": true },
	"password": { "data_type": "text" }
}

var friends_table = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"user1": { "data_type": "text", "not_null": true },
	"user2": { "data_type": "text", "not_null": true },
}

func _ready():
	userdb = SQLite.new()
	userdb.path = "res://users.db"
	userdb.open_db()
	userdb.create_table("users", user_table)
	userdb.create_table("friends", friends_table)

func create_user(username, password):
	userdb.insert_row("users", {
		"username": username,
		"password": password
	})

func get_user_by_name(username):
	var user =  userdb.select_rows("users", "username='%s'"%username, ["*"])
	if len(user) > 0:
		return user[0]
	else:
		return null

func get_friends(username):
	var f1 = userdb.select_rows("friends", "user1='%s'"%username, ["user2"])
	var f2 = userdb.select_rows("friends", "user2='%s'"%username, ["user1"])
	var friends = []
	if f1:
		friends.append_array(f1)
	if f2:
		friends.append_array(f2)
	return friends

func get_user_common_data(username):
	var friends = get_friends(username)
	return {
		"friends": friends,
		"username": username,
	}
	
