package xmpp

import "base:runtime"
import "core:c"
import ffi "ffi:strophe"

// Internal record tracking an active Odin stanza handler
Stanza_Handler_Entry :: struct {
	client:    ^Client,
	handler:   On_Stanza_Proc,
	user_data: rawptr,
}

// C-bridge connection event callback
@(private = "package")
conn_handler_bridge :: proc "c" (
	conn: ffi.Connection,
	event: ffi.Conn_Event,
	error: c.int,
	stream_error: ^ffi.Stream_Error,
	userdata: rawptr,
) {
	context = runtime.default_context()

	client := (^Client)(userdata)
	if client == nil do return

	#partial switch event {
	case .CONNECT:
		client.status = .Connected
		if client.on_connect != nil {
			client.on_connect(client, client.on_connect_data)
		}
	case .DISCONNECT:
		client.status = .Disconnected
		if client.on_disconnect != nil {
			client.on_disconnect(client, int(error), client.on_disconnect_data)
		}
	case .FAIL:
		client.status = .Failed
		if client.on_disconnect != nil {
			client.on_disconnect(client, int(error), client.on_disconnect_data)
		}
	}
}

// C-bridge stanza callback
@(private = "package")
stanza_handler_bridge :: proc "c" (
	conn: ffi.Connection,
	stanza: ffi.Stanza,
	userdata: rawptr,
) -> c.int {
	context = runtime.default_context()

	entry := (^Stanza_Handler_Entry)(userdata)
	if entry == nil || entry.handler == nil do return 0

	// Wrap the C stanza as a borrowed Odin Stanza (owns_handle = false)
	s := Stanza{
		handle      = stanza,
		owns_handle = false,
	}

	keep := entry.handler(entry.client, s, entry.user_data)
	return 1 if keep else 0
}
