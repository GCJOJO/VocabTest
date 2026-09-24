extends Node

var httpRequest : HTTPRequest = HTTPRequest.new()

const HEADERS : = ["Content-Type: application/json"]

var requestQueue : Array[Dictionary]
var isProcessing : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tls_options : TLSOptions = TLSOptions.client_unsafe() if GameManager.IS_LOCAL_SERVER and GameManager.DEBUG_MODE else TLSOptions.client()
	
	httpRequest.set_tls_options(tls_options)
	httpRequest.request_completed.connect(self.onHttpRequestCompleted)
	add_child(httpRequest)

func requestGet(path : String, callback : Callable, body : String = ""):
	requestQueue.push_back({"method" : "get", "path" : path, "callback" : callback, "body" : body})
	
func requestPost(path: String, callback : Callable, body : String = ""):
	requestQueue.push_back({"method" : "post", "path" : path, "callback" : callback, "body" : body})

func onHttpRequestCompleted(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var request : Dictionary = requestQueue.pop_front()
	var callback : Callable = request["callback"]
		
	var json : = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response == null:
		if GameManager.DEBUG_MODE:
			push_error("Null response ! Request : %s" % request["path"])
		ErrorManager.show_error("Impossible d'atteindre le serveur.", "Veuillez vérifier que vos pouvez atteindre le serveur en cliquant sur ce [color=#91b8f1][url={%s/version}]lien[/url][/color].\nSi votre navigateur vous indique qu'il s'agit d'un lien dangereux c'est parce que le serveur n'a pas de certificat SSL valide et la connexion ne peut donc pas être sécurisée.\nVous devez ignorer ce message et rafraichir cette page si vous souhaitez jouer." % GameManager.SERVER_ADRESS)
		return
	if GameManager.DEBUG_MODE:
		print("Got response : %s" % response)
	
	callback.call(response)
	
	isProcessing = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not isProcessing and requestQueue.size() != 0:
		var request : Dictionary = requestQueue.front()
		var request_body : String = request["body"]
		var request_method_string : String = request["method"]
		var request_method : HTTPClient.Method
		match request_method_string:
			"get":
				request_method = HTTPClient.Method.METHOD_GET
			"post":
				request_method = HTTPClient.Method.METHOD_POST
		
		var path : String = request["path"]
		if GameManager.DEBUG_MODE:
			print("Processing request : %s %s, body : \"%s\"" % [request_method_string, path, request_body])
		httpRequest.request(path, HEADERS, request_method, request_body)
		isProcessing = true
