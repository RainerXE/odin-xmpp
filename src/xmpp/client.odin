package xmpp

import "core:c"
import "core:mem"
import "core:strings"
import ffi "ffi:strophe"

// Connection status
Connection_Status :: enum {
	Disconnected = 0,
	Connecting,
	Connected,
	Failed,
}

// User-defined callback procedure types
On_Connect_Proc    :: #type proc(client: ^Client, user_data: rawptr)
On_Disconnect_Proc :: #type proc(client: ^Client, error: int, user_data: rawptr)
On_Stanza_Proc     :: #type proc(client: ^Client, stanza: Stanza, user_data: rawptr) -> bool

// High-level XMPP Client
Client :: struct {
	ctx:        ffi.Context,
	conn:       ffi.Connection,
	jid:        JID,
	status:     Connection_Status,
	allocator:  mem.Allocator,

	// Event hooks
	on_connect:         On_Connect_Proc,
	on_connect_data:    rawptr,
	on_disconnect:      On_Disconnect_Proc,
	on_disconnect_data: rawptr,

	// Active handlers (heap allocated elements for stable addresses)
	handlers: [dynamic]^Stanza_Handler_Entry,
}

// Initializes a new XMPP client.
// Returns a heap-allocated Client using the specified allocator.
client_init :: proc(
	jid_str: string,
	password: string,
	allocator := context.allocator,
) -> (
	client: ^Client,
	err: Xmpp_Error,
) {
	parsed_jid, ok := jid_parse(jid_str, allocator)
	if !ok {
		return nil, .Invalid_JID
	}

	// Ensure global C library is initialized
	ffi.xmpp_initialize()

	// Create runtime context
	ctx := ffi.xmpp_ctx_new(nil, nil)
	if ctx == nil {
		jid_destroy(&parsed_jid, allocator)
		return nil, .Out_Of_Memory
	}

	// Create connection
	conn := ffi.xmpp_conn_new(ctx)
	if conn == nil {
		ffi.xmpp_ctx_free(ctx)
		jid_destroy(&parsed_jid, allocator)
		return nil, .Out_Of_Memory
	}

	// Set credentials on foreign connection
	c_jid := strings.clone_to_cstring(parsed_jid.raw, context.temp_allocator)
	c_pass := strings.clone_to_cstring(password, context.temp_allocator)
	ffi.xmpp_conn_set_jid(conn, c_jid)
	ffi.xmpp_conn_set_pass(conn, c_pass)

	client = new(Client, allocator)
	if client == nil {
		ffi.xmpp_conn_release(conn)
		ffi.xmpp_ctx_free(ctx)
		jid_destroy(&parsed_jid, allocator)
		return nil, .Out_Of_Memory
	}

	client^ = Client{
		ctx       = ctx,
		conn      = conn,
		jid       = parsed_jid,
		status    = .Disconnected,
		allocator = allocator,
		handlers  = make([dynamic]^Stanza_Handler_Entry, allocator),
	}

	return client, .None
}

// Releases all client resources, cleans up handlers, and tears down the connection.
client_destroy :: proc(client: ^Client) {
	if client == nil do return

	allocator := client.allocator

	// Disconnect if active
	if client.conn != nil {
		if client.status == .Connected || client.status == .Connecting {
			ffi.xmpp_disconnect(client.conn)
		}
		ffi.xmpp_conn_release(client.conn)
		client.conn = nil
	}

	// Free context
	if client.ctx != nil {
		ffi.xmpp_ctx_free(client.ctx)
		client.ctx = nil
	}

	// Free handlers
	for entry in client.handlers {
		if entry != nil {
			free(entry, allocator)
		}
	}
	delete(client.handlers)

	// Free JID
	jid_destroy(&client.jid, allocator)

	// Free Client
	free(client, allocator)
}

// Configures connection lifecycle hooks
client_set_connect_handler :: proc(client: ^Client, handler: On_Connect_Proc, user_data: rawptr = nil) {
	if client == nil do return
	client.on_connect = handler
	client.on_connect_data = user_data
}

client_set_disconnect_handler :: proc(client: ^Client, handler: On_Disconnect_Proc, user_data: rawptr = nil) {
	if client == nil do return
	client.on_disconnect = handler
	client.on_disconnect_data = user_data
}

// Initiates client connection.
// Optional altdomain and altport can override standard SRV lookup.
client_connect :: proc(client: ^Client, altdomain := "", altport: u16 = 0) -> Xmpp_Error {
	if client == nil || client.conn == nil do return .Invalid_Argument

	c_host: cstring = nil
	if len(altdomain) > 0 {
		c_host = strings.clone_to_cstring(altdomain, context.temp_allocator)
	}

	rc := ffi.xmpp_connect_client(
		client.conn,
		c_host,
		c.ushort(altport),
		conn_handler_bridge,
		rawptr(client),
	)

	if rc != ffi.EOK {
		return .Connection_Failed
	}

	client.status = .Connecting
	return .None
}

// Disconnects an active connection
client_disconnect :: proc(client: ^Client) {
	if client == nil || client.conn == nil do return
	ffi.xmpp_disconnect(client.conn)
	client.status = .Disconnected
}

// Runs a single event loop step with timeout in milliseconds
client_poll :: proc(client: ^Client, timeout_ms: u32 = 100) {
	if client == nil || client.ctx == nil do return
	ffi.xmpp_run_once(client.ctx, c.ulong(timeout_ms))
}

// Runs the blocking event loop until client_stop is called
client_run :: proc(client: ^Client) {
	if client == nil || client.ctx == nil do return
	ffi.xmpp_run(client.ctx)
}

// Stops a blocking event loop
client_stop :: proc(client: ^Client) {
	if client == nil || client.ctx == nil do return
	ffi.xmpp_stop(client.ctx)
}

// Registers a stanza handler matching optional namespace, element name, and type.
client_add_handler :: proc(
	client: ^Client,
	handler: On_Stanza_Proc,
	ns := "",
	name := "",
	type := "",
	user_data: rawptr = nil,
) {
	if client == nil || client.conn == nil || handler == nil do return

	entry := new(Stanza_Handler_Entry, client.allocator)
	entry.client = client
	entry.handler = handler
	entry.user_data = user_data
	append(&client.handlers, entry)

	c_ns: cstring = strings.clone_to_cstring(ns, context.temp_allocator) if len(ns) > 0 else nil
	c_name: cstring = strings.clone_to_cstring(name, context.temp_allocator) if len(name) > 0 else nil
	c_type: cstring = strings.clone_to_cstring(type, context.temp_allocator) if len(type) > 0 else nil

	ffi.xmpp_handler_add(
		client.conn,
		stanza_handler_bridge,
		c_ns,
		c_name,
		c_type,
		rawptr(entry),
	)
}

// Sends a stanza over the active connection
client_send :: proc(client: ^Client, stanza: Stanza) -> Xmpp_Error {
	if client == nil || client.conn == nil || stanza.handle == nil {
		return .Invalid_Argument
	}
	ffi.xmpp_send(client.conn, stanza.handle)
	return .None
}

// Sends initial presence announcing client availability
client_send_presence :: proc(client: ^Client) -> Xmpp_Error {
	if client == nil || client.ctx == nil do return .Invalid_Argument

	pres := presence_new(client.ctx)
	defer stanza_destroy(&pres)

	return client_send(client, pres)
}

// Helper to construct and send a simple chat message
client_send_message :: proc(
	client: ^Client,
	to: string,
	body: string,
	type := "chat",
) -> Xmpp_Error {
	if client == nil || client.ctx == nil do return .Invalid_Argument

	msg := message_new(client.ctx, type = type, to = to)
	defer stanza_destroy(&msg)

	if len(body) > 0 {
		message_set_body(&msg, body)
	}

	return client_send(client, msg)
}
