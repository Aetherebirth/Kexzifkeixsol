extends Node

var userdb: SQLite

var user_table = {
	"id": { "data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true },
	"username": { "data_type": "text", "not_null": true, "unique": true },
	"password": { "data_type": "text" }
}


func _ready():
	userdb = SQLite.new()
	userdb.path = "res://users.db"
	userdb.open_db()
	userdb.create_table("users", user_table)

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
