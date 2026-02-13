extends Control

signal onUserLoggedIn(userId : String)

func _ready() -> void:
	
	$Login/Control/Register.pressed.connect($Register.show)
	$Login/Control/Login.pressed.connect(loginUser)
	$Register/Control/Register.pressed.connect(registerUser)
	$Register/Control/Login.pressed.connect($Register.hide)
	
func onLoginCallback(response):
	var action : String = response["action"]
	if action == null or action.is_empty():
		print("action is null or empty")
		return
	
	match action:
		"login-success":
			var newUUID : String = response["user_uuid"]
			onUserLoggedIn.emit(newUUID)
			$ReturnButton.disabled = false
			print("User Logged In")
			hide()
		"login-failed":
			$ReturnButton.disabled = false

func loginUser() -> void:
	if %UsernameLogin.text.is_empty():
		pass
	if %PasswordLogin.text.is_empty():
		pass
		
	var username : String = %UsernameLogin.text
	var password : String = %PasswordLogin.text
	var password_hash = (password+GameManager.SALT).sha256_text()
	
	var jsonString : String = JSON.stringify({"username" : username, "password_hash" : password_hash})
	
	#httpRequest.request("%s/login" % GameManager.SERVER_ADRESS, ["Content-Type: application/json"], HTTPClient.METHOD_POST, jsonString)
	RequestQueue.requestPost("%s/login" % GameManager.SERVER_ADRESS, onLoginCallback, jsonString)
	$ReturnButton.disabled = true

func registerUser() -> void:
	if %UsernameRegister.text.is_empty():
		pass
	if %PasswordRegister.text.is_empty():
		pass
	if %PasswordConfirmation.text.is_empty():
		pass
	if %FirstName.text.is_empty():
		pass
	if %LastName.text.is_empty():
		pass
		
	if %PasswordRegister.text != %PasswordConfirmation.text:
		pass
	
	$Register/Control/Register.disabled = true
	
	var username : String = %UsernameRegister.text
	var password : String = %PasswordRegister.text
	var password_hash = (password+GameManager.SALT).sha256_text()
	var first_name : String = %FirstName.text
	var last_name : String = %LastName.text
	
	var jsonString : String = JSON.stringify({"username" : username, "first_name" : first_name, "last_name" : last_name, "password_hash" : password_hash})
	
	#httpRequest.request("%s/register" % GameManager.SERVER_ADRESS, ["Content-Type: application/json"], HTTPClient.METHOD_POST, jsonString)
	RequestQueue.requestPost("%s/register" % GameManager.SERVER_ADRESS, onLoginCallback, jsonString)
	$ReturnButton.disabled = true
	
