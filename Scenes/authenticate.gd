extends Node
class_name Connection

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6943
@export var max_servers: int = 5
@export var default_ip: String = "127.0.0.1"
@export var use_localhost_in_editor: bool

var peer: ENetMultiplayerPeer

func _ready() -> void:
	var args: Dictionary = parse_cmdline_args()
	start_server(args)
	connected.connect(func() -> void: Connection.is_peer_connected = true)
	disconnected.connect(func() -> void: Connection.is_peer_connected = false)
	disconnected.connect(disconnect_all)

@rpc("any_peer", "call_remote", "reliable")
func AuthenticatePlayer(name: String, password: String, player_id: int) -> void:
	var token: String
	print("authentication request received")
	var gateway_id: int = multiplayer.get_remote_sender_id()
	var result: bool
	print("Starting authentication")
	
	var user: Dictionary = PlayerData.get_user_by_name(name)
	if user.id < 0:
		print("User not recognized")
		result = false
	elif not ServerHub.BCryptManager.EnhancedVerifyPassword(password, user.password as String):
		print("Incorrect password")
		result = false
	else:
		print("Succesful authentication")
		result = true
		var player_data: Dictionary = PlayerData.get_user_common_data(name)
		
		token = str(randi()).sha256_text() + str(int(Time.get_unix_time_from_system())) 
		print(token)
		var gameserver: String = "GameServer1"
		ServerHub.DistributeLoginToken(gameserver, token, player_data)
		
	print("authentication result send to gateway server")
	AuthenticationResults(gateway_id, result, player_id, token)

@rpc("any_peer", "call_remote", "reliable")
func CreateAccount(name: String, password: String, player_id: int) -> void:
	var token: String
	print("Account creation request received")
	var gateway_id: int = multiplayer.get_remote_sender_id()
	var message: int = 1
	print("Starting authentication")
	if PlayerData.get_user_by_name(name):
		print("Name already taken")
		message = 2
	else:
		PlayerData.create_user(name, ServerHub.BCryptManager.EnhancedHashPassword(password))
		message = 3
	CreateAccountResults(gateway_id, player_id, message)
	print("Account creation results sent to gateway server")

@rpc("any_peer", "call_remote",  "reliable")
func CreateAccountResults(gateway_id: int, player_id: int, message: int) -> void:
	CreateAccountResults.rpc_id(gateway_id, player_id, message)

@rpc("any_peer", "call_remote",  "reliable")
func AuthenticationResults(gateway_id: int, result: int, player_id: int, token: String) -> void:
	AuthenticationResults.rpc_id(gateway_id, result, player_id, token)

func parse_cmdline_args() -> Dictionary:
	var cmdline_args: PackedStringArray = OS.get_cmdline_args()
	var args: Dictionary = {}
	
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
	var err: int = peer.create_server(args.port as int, max_servers)
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
