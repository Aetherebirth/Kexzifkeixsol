extends Node

signal connected
signal disconnected

static var is_peer_connected: bool

@export var default_port: int = 6945
@export var max_servers: int = 4
@export var default_ip: String = "127.0.0.1"

var network = ENetMultiplayerPeer.new()
var hub_api
var gameserverlist = {}

@onready var hub = $"."

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
func DistributeLoginToken(token, gameserver):
	print("Sending token to " + gameserver)
	DistributeLoginToken.rpc_id(gameserverlist[gameserver], token)



func gameserver_connected(id: int) -> void:
	print("Gameserver " + str(id) + " connected to Hub")
	gameserverlist["GameServer1"] = id
	print(gameserverlist)
	
func gameserver_disconnected(id: int) -> void:
	print("Gameserver " + str(id) + " disconnected from Hub")
	
