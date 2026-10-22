package xmpp

// Tagged error type for XMPP operations
Xmpp_Error :: enum {
	None = 0,
	Out_Of_Memory,
	Invalid_Argument,
	Invalid_JID,
	Connection_Failed,
	Disconnected,
	Timeout,
	Stanza_Error,
	Library_Internal_Error,
}

error_string :: proc(err: Xmpp_Error) -> string {
	switch err {
	case .None:
		return "no error"
	case .Out_Of_Memory:
		return "out of memory"
	case .Invalid_Argument:
		return "invalid argument"
	case .Invalid_JID:
		return "invalid JID format"
	case .Connection_Failed:
		return "connection failed"
	case .Disconnected:
		return "client disconnected"
	case .Timeout:
		return "operation timed out"
	case .Stanza_Error:
		return "stanza error"
	case .Library_Internal_Error:
		return "libstrophe internal error"
	}
	return "unknown error"
}
