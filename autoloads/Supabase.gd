extends Node

const SUPABASE_URL := "https://azfkhxnqbeattzigxcbf.supabase.co"
const SUPABASE_PUBLISHABLE_KEY := "sb_publishable_G-GqL00Vg8imAu-qtuA_0w_KR7m_ley"

var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""

func is_logged_in() -> bool:
	return access_token != "" and user_id != ""

func _headers(authenticated: bool) -> PackedStringArray:
	var headers := PackedStringArray(["apikey: " + SUPABASE_PUBLISHABLE_KEY, "Content-Type: application/json"])
	if authenticated and not access_token.is_empty():
		headers.append("Authorization: Bearer " + access_token)
	return headers

func _request(method: HTTPClient.Method, path: String, payload = null,
		authenticated: bool = false, extra_headers: PackedStringArray = PackedStringArray()) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = 12.0
	add_child(request)
	var headers := _headers(authenticated)
	headers.append_array(extra_headers)
	var body := "" if payload == null else JSON.stringify(payload)
	var error := request.request(SUPABASE_URL + path, headers, method, body)
	if error != OK:
		request.queue_free()
		return {"ok": false, "status": 0, "data": null, "error": "HTTPRequest failed: %s" % error}
	var response: Array = await request.request_completed
	request.queue_free()
	var status: int = int(response[1])
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "status": status, "data": null, "error": "Network request failed."}
	var bytes: PackedByteArray = response[3]
	var text := bytes.get_string_from_utf8()
	var data = JSON.parse_string(text) if not text.is_empty() else null
	var success := status >= 200 and status < 300
	var message := "" if success else "HTTP %d" % status
	if not success and data is Dictionary:
		for key in ["msg", "message", "error_description", "error"]:
			if data.has(key):
				message = str(data[key])
				break
	return {"ok": success, "status": status, "data": data, "error": message}

func _set_session(data: Dictionary) -> void:
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	var user = data.get("user", {})
	user_id = str(user.get("id", "")) if user is Dictionary else ""

func sign_up(email: String, password: String, username: String) -> Dictionary:
	var payload := {"email": email, "password": password, "data": {"username": username}}
	var result: Dictionary = await _request(HTTPClient.METHOD_POST, "/auth/v1/signup", payload)
	if result.ok and result.data is Dictionary:
		_set_session(result.data)
	return result

func sign_in(email: String, password: String) -> Dictionary:
	var payload := {"email": email, "password": password}
	var result: Dictionary = await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=password", payload)
	if result.ok and result.data is Dictionary:
		_set_session(result.data)
	return result

func sign_in_user_or_email(username_or_email: String, password: String) -> Dictionary:
	var login_name := username_or_email.strip_edges()
	if login_name.contains("@"):
		return await sign_in(login_name, password)
	var lookup: Dictionary = await _request(HTTPClient.METHOD_POST,
		"/rest/v1/rpc/get_email_from_username", {"input_username": login_name})
	if not lookup.ok:
		return {"ok": false, "status": lookup.status, "data": null, "error": "Could not find that username."}
	if lookup.data == null or str(lookup.data).is_empty():
		return {"ok": false, "status": 404, "data": null, "error": "Username not found."}
	return await sign_in(str(lookup.data), password)

func reset_password(email: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/auth/v1/recover", {"email": email})

func refresh_session() -> Dictionary:
	if refresh_token.is_empty():
		return {"ok": false, "status": 0, "data": null, "error": "No refresh token available."}
	var result: Dictionary = await _request(HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh_token})
	if result.ok and result.data is Dictionary:
		_set_session(result.data)
	return result

func island_request(method: HTTPClient.Method, path: String, payload = null,
		headers: PackedStringArray = PackedStringArray()) -> Dictionary:
	var result: Dictionary = await _request(method, path, payload, true, headers)
	if int(result.status) == 401 and not refresh_token.is_empty():
		var refresh: Dictionary = await refresh_session()
		if refresh.ok:
			result = await _request(method, path, payload, true, headers)
	return result

func sign_out() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
