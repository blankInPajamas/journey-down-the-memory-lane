# LLMStream.gd
class_name LLMStream extends RefCounted

signal token_received(token)
signal stream_finished
signal stream_failed(error_message)

var http_client = HTTPClient.new()
var was_streaming = false

func stream_request(url: String, data: Dictionary):
	var body = JSON.stringify(data)
	var headers = [
		"Content-Type: application/json",
		"Content-Length: " + str(body.length())
	]
	
	var err = http_client.connect_to_host("192.168.10.127", 5000)
	if err != OK:
		emit_signal("stream_failed", "Could not connect to host.")
		return

	was_streaming = true
	
	while http_client.get_status() == HTTPClient.STATUS_CONNECTING or \
		  http_client.get_status() == HTTPClient.STATUS_RESOLVING:
		http_client.poll()
		await Engine.get_main_loop().process_frame

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		emit_signal("stream_failed", "Connection failed after waiting.")
		return

	http_client.request(HTTPClient.METHOD_POST, "/interact", headers, body)

func poll():
	if not was_streaming:
		return
		
	http_client.poll()
	var current_status = http_client.get_status()
	
	# Read any available data from the stream's body
	while current_status == HTTPClient.STATUS_BODY:
		var chunk = http_client.read_response_body_chunk()
		if chunk.size() > 0:
			emit_signal("token_received", chunk.get_string_from_utf8())
		else:
			break
		
		http_client.poll()
		current_status = http_client.get_status()

	# Check if the stream has ended (cleanly or with an error)
	if was_streaming and current_status != HTTPClient.STATUS_BODY and \
	current_status != HTTPClient.STATUS_CONNECTING and \
	current_status != HTTPClient.STATUS_CONNECTED:
		
		was_streaming = false
		
		# THE FIX IS HERE: A clean finish is just STATUS_DISCONNECTED.
		if current_status == HTTPClient.STATUS_DISCONNECTED:
			emit_signal("stream_finished")
		else:
			# Any other status is an error
			var error_msg = "Stream ended with an error. Status: " + str(current_status)
			emit_signal("stream_failed", error_msg)
