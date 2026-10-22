package xmpp

import "core:strings"

// Structured representation of a Jabber Identifier (RFC 6122)
JID :: struct {
	raw:      string,
	node:     string,
	domain:   string,
	resource: string,
}

// Parses a string into a JID struct.
// Allocates internal strings using the provided allocator.
jid_parse :: proc(str: string, allocator := context.allocator) -> (jid: JID, ok: bool) {
	if len(str) == 0 do return {}, false

	rem := str
	node := ""
	domain := ""
	resource := ""

	// Check for resource separator first
	slash_idx := strings.index_byte(rem, '/')
	if slash_idx >= 0 {
		resource = rem[slash_idx+1:]
		rem = rem[:slash_idx]
	}

	// Check for node separator
	at_idx := strings.index_byte(rem, '@')
	if at_idx >= 0 {
		node = rem[:at_idx]
		domain = rem[at_idx+1:]
	} else {
		domain = rem
	}

	// Domain is mandatory in XMPP JIDs
	if len(domain) == 0 do return {}, false

	// Clone into caller's allocator to guarantee unambiguous ownership
	jid.raw = strings.clone(str, allocator)
	jid.node = strings.clone(node, allocator)
	jid.domain = strings.clone(domain, allocator)
	jid.resource = strings.clone(resource, allocator)

	return jid, true
}

// Frees all strings allocated for this JID
jid_destroy :: proc(jid: ^JID, allocator := context.allocator) {
	if jid == nil do return

	if len(jid.raw) > 0 do delete(jid.raw, allocator)
	if len(jid.node) > 0 do delete(jid.node, allocator)
	if len(jid.domain) > 0 do delete(jid.domain, allocator)
	if len(jid.resource) > 0 do delete(jid.resource, allocator)

	jid^ = {}
}

// Formats a bare JID (node@domain or domain)
jid_bare :: proc(jid: JID, allocator := context.allocator) -> string {
	if len(jid.node) > 0 {
		return strings.concatenate({jid.node, "@", jid.domain}, allocator)
	}
	return strings.clone(jid.domain, allocator)
}

// Returns true if the string is a syntactically valid JID
jid_is_valid :: proc(str: string) -> bool {
	if len(str) == 0 do return false

	rem := str
	slash_idx := strings.index_byte(rem, '/')
	if slash_idx >= 0 {
		rem = rem[:slash_idx]
	}

	at_idx := strings.index_byte(rem, '@')
	if at_idx >= 0 {
		node := rem[:at_idx]
		domain := rem[at_idx+1:]
		return len(node) > 0 && len(domain) > 0
	}

	return len(rem) > 0
}
