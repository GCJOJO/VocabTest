extends Node

@onready var PEER : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var is_server : bool = false

func startServer():
	PEER.create_server(5763, 32)
	print("Created server")
	PEER.peer_connected.connect(self.onPeerConnected)
	PEER.peer_disconnected.connect(self.onPeerDisconnected)
	is_server = true
	
func startClient():
	print(PEER.create_client("localhost", 5763))
	PEER.peer_connected.connect(self.onPeerConnected)
	PEER.peer_disconnected.connect(self.onPeerDisconnected)
	is_server = false
	
func IsServer() -> bool:
	return is_server
	
	
func onPeerConnected(id : int) -> void:
	print("Peer connected %d" % id)
	
func onPeerDisconnected(id : int) -> void:
	print("Peer disconnected %d" % id)
