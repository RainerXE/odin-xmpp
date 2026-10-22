package strophe

import "core:c"

when ODIN_OS == .Windows {
	STROPHE_LIB :: #config(STROPHE_LIB, "artifacts/strophe.lib")
	foreign import libstrophe { STROPHE_LIB }
} else {
	STROPHE_SYSTEM :: #config(STROPHE_SYSTEM, true)
	when STROPHE_SYSTEM {
		foreign import libstrophe { "system:strophe" }
	} else {
		STROPHE_LIB :: #config(STROPHE_LIB, "../../artifacts/libstrophe.a")
		foreign import libstrophe { STROPHE_LIB }
	}
}

@(default_calling_convention = "c")
foreign libstrophe {
	// Library lifecycle
	xmpp_initialize :: proc() ---
	xmpp_shutdown   :: proc() ---
	xmpp_version_check :: proc(major, minor: c.int) -> c.int ---

	// Context lifecycle & memory
	xmpp_ctx_new           :: proc(mem: ^Mem, log: ^Log) -> Context ---
	xmpp_ctx_free          :: proc(ctx: Context) ---
	xmpp_ctx_set_verbosity :: proc(ctx: Context, level: c.int) ---
	xmpp_free              :: proc(ctx: Context, p: rawptr) ---
	xmpp_get_default_logger :: proc(level: Log_Level) -> ^Log ---

	// Connection lifecycle & configuration
	xmpp_conn_new          :: proc(ctx: Context) -> Connection ---
	xmpp_conn_clone        :: proc(conn: Connection) -> Connection ---
	xmpp_conn_release      :: proc(conn: Connection) -> c.int ---
	xmpp_conn_get_flags    :: proc(conn: Connection) -> c.long ---
	xmpp_conn_set_flags    :: proc(conn: Connection, flags: c.long) -> c.int ---
	xmpp_conn_get_jid      :: proc(conn: Connection) -> cstring ---
	xmpp_conn_get_bound_jid :: proc(conn: Connection) -> cstring ---
	xmpp_conn_set_jid      :: proc(conn: Connection, jid: cstring) ---
	xmpp_conn_get_pass     :: proc(conn: Connection) -> cstring ---
	xmpp_conn_set_pass     :: proc(conn: Connection, pass: cstring) ---
	xmpp_conn_get_context  :: proc(conn: Connection) -> Context ---
	xmpp_conn_is_secured   :: proc(conn: Connection) -> c.int ---
	xmpp_conn_is_connecting :: proc(conn: Connection) -> c.int ---
	xmpp_conn_is_connected :: proc(conn: Connection) -> c.int ---
	xmpp_conn_is_disconnected :: proc(conn: Connection) -> c.int ---

	// Connection operations
	xmpp_connect_client    :: proc(conn: Connection, altdomain: cstring, altport: c.ushort, callback: Conn_Handler, userdata: rawptr) -> c.int ---
	xmpp_connect_component :: proc(conn: Connection, server: cstring, port: c.ushort, callback: Conn_Handler, userdata: rawptr) -> c.int ---
	xmpp_connect_raw       :: proc(conn: Connection, altdomain: cstring, altport: c.ushort, callback: Conn_Handler, userdata: rawptr) -> c.int ---
	xmpp_disconnect        :: proc(conn: Connection) ---
	xmpp_send              :: proc(conn: Connection, stanza: Stanza) ---
	xmpp_send_raw          :: proc(conn: Connection, data: [^]u8, len: c.size_t) ---

	// Event loop
	xmpp_run_once          :: proc(ctx: Context, timeout: c.ulong) ---
	xmpp_run               :: proc(ctx: Context) ---
	xmpp_stop              :: proc(ctx: Context) ---
	xmpp_ctx_set_timeout   :: proc(ctx: Context, timeout: c.ulong) ---

	// Handlers
	xmpp_timed_handler_add    :: proc(conn: Connection, handler: Timed_Handler, period: c.ulong, userdata: rawptr) ---
	xmpp_timed_handler_delete :: proc(conn: Connection, handler: Timed_Handler) ---
	xmpp_handler_add          :: proc(conn: Connection, handler: Stanza_Handler, ns: cstring, name: cstring, type: cstring, userdata: rawptr) ---
	xmpp_handler_delete       :: proc(conn: Connection, handler: Stanza_Handler) ---
	xmpp_id_handler_add       :: proc(conn: Connection, handler: Stanza_Handler, id: cstring, userdata: rawptr) ---
	xmpp_id_handler_delete    :: proc(conn: Connection, handler: Stanza_Handler, id: cstring) ---

	// Stanza lifecycle & creation
	xmpp_stanza_new             :: proc(ctx: Context) -> Stanza ---
	xmpp_stanza_new_from_string :: proc(ctx: Context, str: cstring) -> Stanza ---
	xmpp_stanza_clone           :: proc(stanza: Stanza) -> Stanza ---
	xmpp_stanza_copy            :: proc(stanza: Stanza) -> Stanza ---
	xmpp_stanza_release         :: proc(stanza: Stanza) -> c.int ---
	xmpp_stanza_get_context     :: proc(stanza: Stanza) -> Context ---

	// Stanza tree operations
	xmpp_stanza_is_text                   :: proc(stanza: Stanza) -> c.int ---
	xmpp_stanza_is_tag                    :: proc(stanza: Stanza) -> c.int ---
	xmpp_stanza_to_text                   :: proc(stanza: Stanza, buf: ^cstring, buflen: ^c.size_t) -> c.int ---
	xmpp_stanza_get_children              :: proc(stanza: Stanza) -> Stanza ---
	xmpp_stanza_get_child_by_name         :: proc(stanza: Stanza, name: cstring) -> Stanza ---
	xmpp_stanza_get_child_by_ns           :: proc(stanza: Stanza, ns: cstring) -> Stanza ---
	xmpp_stanza_get_child_by_name_and_ns  :: proc(stanza: Stanza, name: cstring, ns: cstring) -> Stanza ---
	xmpp_stanza_get_next                  :: proc(stanza: Stanza) -> Stanza ---
	xmpp_stanza_add_child                 :: proc(stanza: Stanza, child: Stanza) -> c.int ---
	xmpp_stanza_add_child_ex              :: proc(stanza: Stanza, child: Stanza, do_clone: c.int) -> c.int ---

	// Stanza attributes & content
	xmpp_stanza_get_attribute     :: proc(stanza: Stanza, name: cstring) -> cstring ---
	xmpp_stanza_get_attribute_count :: proc(stanza: Stanza) -> c.int ---
	xmpp_stanza_get_text          :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_text_ptr      :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_name          :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_set_attribute     :: proc(stanza: Stanza, key: cstring, value: cstring) -> c.int ---
	xmpp_stanza_set_name          :: proc(stanza: Stanza, name: cstring) -> c.int ---
	xmpp_stanza_set_text          :: proc(stanza: Stanza, text: cstring) -> c.int ---
	xmpp_stanza_set_text_with_size :: proc(stanza: Stanza, text: cstring, size: c.size_t) -> c.int ---
	xmpp_stanza_del_attribute     :: proc(stanza: Stanza, name: cstring) -> c.int ---

	// Stanza common attributes
	xmpp_stanza_get_ns   :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_type :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_id   :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_to   :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_get_from :: proc(stanza: Stanza) -> cstring ---
	xmpp_stanza_set_ns   :: proc(stanza: Stanza, ns: cstring) -> c.int ---
	xmpp_stanza_set_id   :: proc(stanza: Stanza, id: cstring) -> c.int ---
	xmpp_stanza_set_type :: proc(stanza: Stanza, type: cstring) -> c.int ---
	xmpp_stanza_set_to   :: proc(stanza: Stanza, to: cstring) -> c.int ---
	xmpp_stanza_set_from :: proc(stanza: Stanza, from: cstring) -> c.int ---

	// Stanza replies
	xmpp_stanza_reply       :: proc(stanza: Stanza) -> Stanza ---
	xmpp_stanza_reply_error :: proc(stanza: Stanza, error_type: cstring, condition: cstring, text: cstring) -> Stanza ---

	// Specialized constructors
	xmpp_message_new      :: proc(ctx: Context, type: cstring, to: cstring, id: cstring) -> Stanza ---
	xmpp_message_get_body :: proc(msg: Stanza) -> cstring ---
	xmpp_message_set_body :: proc(msg: Stanza, text: cstring) -> c.int ---
	xmpp_iq_new           :: proc(ctx: Context, type: cstring, id: cstring) -> Stanza ---
	xmpp_presence_new     :: proc(ctx: Context) -> Stanza ---

	// JID utilities
	xmpp_jid_new      :: proc(ctx: Context, node: cstring, domain: cstring, resource: cstring) -> cstring ---
	xmpp_jid_bare     :: proc(ctx: Context, jid: cstring) -> cstring ---
	xmpp_jid_node     :: proc(ctx: Context, jid: cstring) -> cstring ---
	xmpp_jid_domain   :: proc(ctx: Context, jid: cstring) -> cstring ---
	xmpp_jid_resource :: proc(ctx: Context, jid: cstring) -> cstring ---

	// UUID
	xmpp_uuid_gen :: proc(ctx: Context) -> cstring ---
}
