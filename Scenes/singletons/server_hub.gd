extends Node

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6945
@export var max_servers: int = 4
@export var default_ip: String = "127.0.0.1"

var network: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var hub_api: MultiplayerAPI
var gameserverlist: Dictionary = {}

var BCryptManager: BCryptWrapper = BCryptWrapper.new()

@onready var hub: Node = $"."

func _ready() -> void:
	LaunchServer()
	
func LaunchServer() -> void:
	print("GameServer Hub launching...")
	hub_api = MultiplayerAPI.create_default_interface()
	network.create_server(default_port, max_servers)
	get_tree().set_multiplayer(hub_api, hub.get_path())
	hub_api.multiplayer_peer = network
	
	network.peer_connected.connect(gameserver_connected)
	network.peer_disconnected.connect(gameserver_disconnected)

@rpc("any_peer", "reliable")
func DistributeLoginToken(gameserver: String, token: String, player_data: Dictionary) -> void:
	print("Sending token to " + gameserver)
	DistributeLoginToken.rpc_id(gameserverlist[gameserver] as int, token, player_data)

func gameserver_connected(id: int) -> void:
	print("Gameserver " + str(id) + " connected to Hub")
	gameserverlist["GameServer1"] = id
	print(gameserverlist)
	
func gameserver_disconnected(id: int) -> void:
	print("Gameserver " + str(id) + " disconnected from Hub")


## Global chat system
@rpc("any_peer", "call_remote", "reliable")
func BroadcastChatMessage(name: String, escaped_message: String, tab: String) -> void:
	print(name, escaped_message, tab)
	match tab:
		"global":
			SendGlobalChatMessage(name, escaped_message)
		"guild":
			SendGuildChatMessage(name, escaped_message, PlayerData.get_player_guild_id(name))

@rpc("authority", "call_remote", "reliable")
func SendGlobalChatMessage(name: String, escaped_message: String) -> void:
	SendGlobalChatMessage.rpc_id(0, name, escaped_message)

@rpc("authority", "call_remote", "reliable")
func SendGuildChatMessage(name: String, escaped_message: String, guild: int) -> void:
	SendGuildChatMessage.rpc_id(0, name, escaped_message, guild)
