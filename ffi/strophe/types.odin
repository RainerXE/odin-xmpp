package strophe

import "core:c"

// Opaque handles
Context    :: distinct rawptr
Connection :: distinct rawptr
Stanza     :: distinct rawptr
Sm_State   :: distinct rawptr
TlsCert    :: distinct rawptr
Sha1       :: distinct rawptr
Rand       :: distinct rawptr

// Stream error details passed to connection handlers
Stream_Error :: struct {
	type:   Error_Type,
	text:   cstring,
	stanza: Stanza,
}

// Memory allocator hooks
Mem_Alloc_Proc   :: #type proc "c" (size: c.size_t, userdata: rawptr) -> rawptr
Mem_Free_Proc    :: #type proc "c" (p: rawptr, userdata: rawptr)
Mem_Realloc_Proc :: #type proc "c" (p: rawptr, size: c.size_t, userdata: rawptr) -> rawptr

Mem :: struct {
	alloc:    Mem_Alloc_Proc,
	free:     Mem_Free_Proc,
	realloc:  Mem_Realloc_Proc,
	userdata: rawptr,
}

// Logging hooks
Log_Handler :: #type proc "c" (userdata: rawptr, level: Log_Level, area: cstring, msg: cstring)

Log :: struct {
	handler:  Log_Handler,
	userdata: rawptr,
}

// Callback procedures
Conn_Handler         :: #type proc "c" (conn: Connection, event: Conn_Event, error: c.int, stream_error: ^Stream_Error, userdata: rawptr)
Stanza_Handler       :: #type proc "c" (conn: Connection, stanza: Stanza, userdata: rawptr) -> c.int
Timed_Handler        :: #type proc "c" (conn: Connection, userdata: rawptr) -> c.int
Global_Timed_Handler :: #type proc "c" (ctx: Context, userdata: rawptr) -> c.int
Certfail_Handler     :: #type proc "c" (cert: TlsCert, errormsg: cstring) -> c.int
Password_Callback    :: #type proc "c" (pw: [^]c.char, pw_max: c.size_t, conn: Connection, userdata: rawptr) -> c.int
