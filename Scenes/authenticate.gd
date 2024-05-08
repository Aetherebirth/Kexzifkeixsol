extends Node
class_name Connection

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6943
@export var max_servers: int = 5
@export var default_ip: String = "127.0.0.1"
@export var use_localhost_in_editor: bool

var peer
var bcrypt_cs = load("res://BCryptWrapper.cs")
var bcrypt = bcrypt_cs.new()

func _ready() -> void:
	var args = parse_cmdline_args()
	start_server(args)
	connected.connect(func(): Connection.is_peer_connected = true)
	disconnected.connect(func(): Connection.is_peer_connected = false)
	disconnected.connect(disconnect_all)

@rpc("any_peer", "call_remote", "reliable")
func AuthenticatePlayer(username, password, player_id):
	var token
	print("authentication request received")
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	print("Starting authentication")
	if not PlayerData.PlayerIDs.has(username):
		print("User not recognized")
		result = false
	elif not bcrypt.EnhancedVerifyPassword(password, PlayerData.PlayerIDs[username].Password):
		print("Incorrect password")
		result = false
	else:
		print("Succesful authentication")
		result = true
		
		token = str(randi()).sha256_text() + str(int(Time.get_unix_time_from_system())) 
		print(token)
		var gameserver = "GameServer1"
		ServerHub.DistributeLoginToken(token, gameserver)
		
	print("authentication result send to gateway server")
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)

@rpc("any_peer", "call_remote", "reliable")
func CreateAccount(username, password, player_id):
	var token
	print("Account creation request received")
	var gateway_id = multiplayer.get_remote_sender_id()
	var message = 1
	print("Starting authentication")
	if PlayerData.PlayerIDs.has(username):
		print("Username already taken")
		message = 2
	else:
		PlayerData.PlayerIDs[username] = {
			"Password": bcrypt.EnhancedHashPassword(password)
		}
		message = 3
	CreateAccountResults(gateway_id, player_id, message)
	print("Account creation results sent to gateway server")

@rpc("any_peer", "call_remote",  "reliable")
func CreateAccountResults(gateway_id, player_id, message):
	CreateAccountResults.rpc_id(gateway_id, player_id, message)

@rpc("any_peer", "call_remote",  "reliable")
func AuthenticationResults(result, player_id, token):
	pass

func parse_cmdline_args() -> Dictionary:
	var cmdline_args = OS.get_cmdline_args()
	var args = {}
	
	var i: int = 0
	while(i<len(cmdline_args)):
		if cmdline_args[i]=="--port":
			args.port = int(cmdline_args[i+1])
			i+=1
		i+=1
	if not "port" in args:
		args.port = default_port
	return args

func start_server(args: Dictionary) -> void:
	if max_servers == 0:
		max_servers = 5
	
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(args.port, max_servers)
	if err != OK:
		print("Cannot start authentication server. Err: " + str(err))
		disconnected.emit()
		return
	else:
		print("Authentication server started on port " + str(args.port))
		connected.emit()
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)


func server_connection_failure() -> void:
	print("Disconnected")
	disconnected.emit()


func peer_connected(id: int) -> void:
	print("Gateway connected: " + str(id))


func peer_disconnected(id: int) -> void:
	print("Gateway disconnected: " + str(id))


func disconnect_all() -> void:
	multiplayer.peer_connected.disconnect(peer_connected)
	multiplayer.peer_disconnected.disconnect(peer_disconnected)
	multiplayer.server_disconnected.disconnect(server_connection_failure)
	multiplayer.connection_failed.disconnect(server_connection_failure)
