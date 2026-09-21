extends Node


const SUPABASE_URL := "https://azfkhxnqbeattzigxcbf.supabase.co"
const SUPABASE_PUBLISHABLE_KEY := "sb_publishable_G-GqL00Vg8imAu-qtuA_0w_KR7m_ley"


var access_token: String = ""
var refresh_token: String = ""
var user_id: String = ""


func is_logged_in() -> bool:
	return access_token != "" and user_id != ""


func _headers(authenticated: bool = false) -> PackedStringArray:
	var headers := PackedStringArray()

	headers.append("apikey: %s" % SUPABASE_PUBLISHABLE_KEY)
	headers.append("Content-Type: application/json")

	if authenticated and access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)

	return headers


func _request(
	method: HTTPClient.Method,
	path: String,
	payload = null,
	authenticated: bool = false,
	extra_headers: PackedStringArray = PackedStringArray()
) -> Dictionary:

	var request := HTTPRequest.new()
	add_child(request)

	var headers := _headers(authenticated)

	for header in extra_headers:
		headers.append(header)

	var body := ""

	if payload != null:
		body = JSON.stringify(payload)

	var request_error := request.request(
		SUPABASE_URL + path,
		headers,
		method,
		body
	)

	if request_error != OK:
		request.queue_free()

		return {
			"ok": false,
			"status": 0,
			"data": null,
			"error": "HTTPRequest failed: %s" % request_error
		}

	var response = await request.request_completed

	request.queue_free()

	var result_code: int = int(response[0])
	var status_code: int = int(response[1])
	var response_body: PackedByteArray = response[3]

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {
			"ok": false,
			"status": status_code,
			"data": null,
			"error": "Network request failed."
		}

	var response_text := response_body.get_string_from_utf8()

	var data = null

	if response_text != "":
		data = JSON.parse_string(response_text)

	var success := status_code >= 200 and status_code < 300

	if success:
		return {
			"ok": true,
			"status": status_code,
			"data": data,
			"error": ""
		}

	var error_message := "HTTP %d" % status_code

	if data is Dictionary:
		for key in ["msg", "message", "error_description", "error"]:
			if data.has(key):
				error_message = str(data[key])
				break

	return {
		"ok": false,
		"status": status_code,
		"data": data,
		"error": error_message
	}


func _set_session(data: Dictionary) -> void:

	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))

	var user = data.get("user", {})

	if user is Dictionary:
		user_id = str(user.get("id", ""))


func sign_up(email: String, password: String, username: String) -> Dictionary:

	var payload := {
		"email": email,
		"password": password,
		"data": {
			"username": username
		}
	}

	var result := await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/signup",
		payload
	)

	if result["ok"] and result["data"] is Dictionary:
		_set_session(result["data"])

	return result


func sign_in(email: String, password: String) -> Dictionary:

	var payload := {
		"email": email,
		"password": password
	}

	var result := await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=password",
		payload
	)

	if result["ok"] and result["data"] is Dictionary:
		_set_session(result["data"])

	return result
	
func get_email_from_username(username: String) -> Dictionary:

	var payload := {
		"input_username": username
	}

	return await _request(
		HTTPClient.METHOD_POST,
		"/rest/v1/rpc/get_email_from_username",
		payload,
		false
	)


func sign_in_user_or_email(
	username_or_email: String,
	password: String
) -> Dictionary:

	var login_value := username_or_email.strip_edges()

	if login_value.contains("@"):

		return await sign_in(
			login_value,
			password
		)

	var lookup_result := await get_email_from_username(
		login_value
	)

	if not lookup_result["ok"]:
		return {
			"ok": false,
			"status": lookup_result["status"],
			"data": null,
			"error": "Could not find that username."
		}

	var email = lookup_result["data"]

	if email == null or str(email).is_empty():
		return {
			"ok": false,
			"status": 404,
			"data": null,
			"error": "Username not found."
		}

	return await sign_in(
		str(email),
		password
	)


func reset_password(email: String) -> Dictionary:

	var payload := {
		"email": email
	}

	return await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/recover",
		payload,
		false
	)


func refresh_session() -> Dictionary:

	if refresh_token == "":
		return {
			"ok": false,
			"status": 0,
			"data": null,
			"error": "No refresh token available."
		}

	var payload := {
		"refresh_token": refresh_token
	}

	var result := await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=refresh_token",
		payload
	)

	if result["ok"] and result["data"] is Dictionary:
		_set_session(result["data"])

	return result


func load_game_state() -> Dictionary:

	if not is_logged_in():
		return {
			"ok": false,
			"status": 0,
			"data": null,
			"error": "Not logged in."
		}

	var path := "/rest/v1/player_progress?select=*&user_id=eq.%s" % user_id

	var result := await _request(
		HTTPClient.METHOD_GET,
		path,
		null,
		true
	)

	if result["status"] == 401 and refresh_token != "":
		var refresh_result := await refresh_session()

		if refresh_result["ok"]:
			result = await _request(
				HTTPClient.METHOD_GET,
				path,
				null,
				true
			)

	return result


func save_game_state() -> Dictionary:

	if not is_logged_in():
		return {
			"ok": false,
			"status": 0,
			"data": null,
			"error": "Not logged in."
		}

	var payload := {
		"user_id": user_id,
		"economy": GameState.economy,
		"employment": GameState.employment,
		"environment": GameState.environment,
		"satisfaction": GameState.satisfaction,
		"turn": GameState.turn,
		"action_points": GameState.action_points,
		"log_entries": GameState.log_entries,
		"updated_at": Time.get_datetime_string_from_system(true)
	}

	var headers := PackedStringArray()
	headers.append("Prefer: resolution=merge-duplicates, return=representation")

	var result := await _request(
		HTTPClient.METHOD_POST,
		"/rest/v1/player_progress",
		payload,
		true,
		headers
	)

	if result["status"] == 401 and refresh_token != "":
		var refresh_result := await refresh_session()

		if refresh_result["ok"]:
			result = await _request(
				HTTPClient.METHOD_POST,
				"/rest/v1/player_progress",
				payload,
				true,
				headers
			)

	return result


func sign_out() -> void:

	access_token = ""
	refresh_token = ""
	user_id = ""
