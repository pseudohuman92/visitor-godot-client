extends Node2D

func _ready():
	var new_socket = false
	if !GS.socket:
		new_socket = true
		GS.socket = Websocket.new()
	GS.socket.connect("got_collection", got_collection)
	if new_socket:
		GS.socket.connect("got_login_response", func(): GS.socket.get_collection())
		GS.socket.connect_to_server()
	else:
		GS.socket.get_collection()

func got_collection(coll):
	GS.collection = coll;
	GS.collection.sort_custom(CS.compare_color_cost_name_cardP)
	find_child("Collection").populate()

func _process(_delta):
	if GS.socket:
		GS.socket._process(_delta)
	if GS.gameSocket:
		GS.gameSocket._process(_delta)
