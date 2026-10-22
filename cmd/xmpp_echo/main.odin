package main

import "core:fmt"
import "core:os"
import "xmpp:xmpp"

handle_connect :: proc(client: ^xmpp.Client, user_data: rawptr) {
	fmt.println("[xmpp] Connected successfully!")
	fmt.println("[xmpp] Sending initial presence...")

	err := xmpp.client_send_presence(client)
	if err != .None {
		fmt.printfln("[xmpp] Failed to send presence: %s", xmpp.error_string(err))
	} else {
		fmt.println("[xmpp] Presence sent. Listening for messages (echo mode active)...")
	}
}

handle_disconnect :: proc(client: ^xmpp.Client, error: int, user_data: rawptr) {
	fmt.printfln("[xmpp] Disconnected (status/error code: %d)", error)
}

handle_incoming_message :: proc(client: ^xmpp.Client, stanza: xmpp.Stanza, user_data: rawptr) -> bool {
	from := xmpp.stanza_get_from(stanza)
	type := xmpp.stanza_get_type(stanza)
	body := xmpp.message_get_body(stanza)
	defer delete(body)

	if len(body) == 0 {
		return true // Ignore messages without body
	}

	fmt.printfln("[xmpp] Received message from '%s' (type: %s): %s", from, type, body)

	// Don't reply to error stanzas
	if type == "error" do return true

	// Echo back to sender
	reply_body := fmt.tprintf("Echo: %s", body)
	err := xmpp.client_send_message(client, to = from, body = reply_body, type = "chat")
	if err != .None {
		fmt.printfln("[xmpp] Failed to send echo reply: %s", xmpp.error_string(err))
	} else {
		fmt.printfln("[xmpp] Echoed back to '%s'", from)
	}

	return true // Keep handler registered
}

main :: proc() {
	jid := os.get_env("XMPP_JID", context.temp_allocator)
	pass := os.get_env("XMPP_PASS", context.temp_allocator)

	if len(jid) == 0 || len(pass) == 0 {
		fmt.println("Usage:")
		fmt.println("  XMPP_JID=\"user@example.com/resource\" XMPP_PASS=\"secret\" ./artifacts/xmpp_echo")
		fmt.println("")
		fmt.println("Error: XMPP_JID and XMPP_PASS environment variables must be set.")
		os.exit(1)
	}

	fmt.printfln("[xmpp] Initializing client for JID: %s", jid)
	client, err := xmpp.client_init(jid, pass)
	if err != .None {
		fmt.eprintfln("Failed to initialize client: %s", xmpp.error_string(err))
		os.exit(1)
	}
	defer xmpp.client_destroy(client)

	xmpp.client_set_connect_handler(client, handle_connect)
	xmpp.client_set_disconnect_handler(client, handle_disconnect)

	// Register message handler for incoming message stanzas
	xmpp.client_add_handler(client, handle_incoming_message, name = "message")

	fmt.println("[xmpp] Connecting...")
	conn_err := xmpp.client_connect(client)
	if conn_err != .None {
		fmt.eprintfln("Connection initiation failed: %s", xmpp.error_string(conn_err))
		os.exit(1)
	}

	// Run event loop until disconnected or stopped
	xmpp.client_run(client)
	fmt.println("[xmpp] Exiting.")
}
