package xmpp

import "core:c"
import "core:strings"
import ffi "ffi:strophe"

// High-level wrapper around a libstrophe stanza handle
Stanza :: struct {
	handle:      ffi.Stanza,
	owns_handle: bool,
}

// Releases the underlying foreign stanza if owned
stanza_destroy :: proc(s: ^Stanza) {
	if s == nil || s.handle == nil do return

	if s.owns_handle {
		ffi.xmpp_stanza_release(s.handle)
	}
	s^ = {}
}

// Creates a deep copy of the stanza
stanza_clone :: proc(s: Stanza) -> Stanza {
	if s.handle == nil do return {}
	cloned := ffi.xmpp_stanza_copy(s.handle)
	return Stanza{handle = cloned, owns_handle = true}
}

// Returns the element name of the stanza (e.g. "message", "presence", "iq")
stanza_get_name :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_name := ffi.xmpp_stanza_get_name(s.handle)
	if c_name == nil do return ""
	return string(c_name)
}

// Sets the element name
stanza_set_name :: proc(s: ^Stanza, name: string) -> bool {
	if s == nil || s.handle == nil do return false
	c_name := strings.clone_to_cstring(name, context.temp_allocator)
	return ffi.xmpp_stanza_set_name(s.handle, c_name) == ffi.EOK
}

// Gets an attribute value by name
stanza_get_attribute :: proc(s: Stanza, name: string) -> (value: string, ok: bool) {
	if s.handle == nil do return "", false
	c_name := strings.clone_to_cstring(name, context.temp_allocator)
	c_val := ffi.xmpp_stanza_get_attribute(s.handle, c_name)
	if c_val == nil do return "", false
	return string(c_val), true
}

// Sets or replaces an attribute value
stanza_set_attribute :: proc(s: ^Stanza, key, value: string) -> bool {
	if s == nil || s.handle == nil do return false
	c_key := strings.clone_to_cstring(key, context.temp_allocator)
	c_val := strings.clone_to_cstring(value, context.temp_allocator)
	return ffi.xmpp_stanza_set_attribute(s.handle, c_key, c_val) == ffi.EOK
}

// Deletes an attribute
stanza_del_attribute :: proc(s: ^Stanza, name: string) -> bool {
	if s == nil || s.handle == nil do return false
	c_name := strings.clone_to_cstring(name, context.temp_allocator)
	return ffi.xmpp_stanza_del_attribute(s.handle, c_name) == ffi.EOK
}

// Convenience getters for standard attributes
stanza_get_type :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_type := ffi.xmpp_stanza_get_type(s.handle)
	return string(c_type) if c_type != nil else ""
}

stanza_get_id :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_id := ffi.xmpp_stanza_get_id(s.handle)
	return string(c_id) if c_id != nil else ""
}

stanza_get_to :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_to := ffi.xmpp_stanza_get_to(s.handle)
	return string(c_to) if c_to != nil else ""
}

stanza_get_from :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_from := ffi.xmpp_stanza_get_from(s.handle)
	return string(c_from) if c_from != nil else ""
}

stanza_get_ns :: proc(s: Stanza) -> string {
	if s.handle == nil do return ""
	c_ns := ffi.xmpp_stanza_get_ns(s.handle)
	return string(c_ns) if c_ns != nil else ""
}

// Sets text on a text-node stanza
stanza_set_text :: proc(s: ^Stanza, text: string) -> bool {
	if s == nil || s.handle == nil do return false
	c_text := strings.clone_to_cstring(text, context.temp_allocator)
	return ffi.xmpp_stanza_set_text(s.handle, c_text) == ffi.EOK
}

// Appends a text node containing `text` as a child of element `s`
stanza_add_text_child :: proc(s: ^Stanza, text: string) -> bool {
	if s == nil || s.handle == nil do return false
	ctx := ffi.xmpp_stanza_get_context(s.handle)
	if ctx == nil do return false

	text_node := ffi.xmpp_stanza_new(ctx)
	if text_node == nil do return false
	defer ffi.xmpp_stanza_release(text_node)

	c_text := strings.clone_to_cstring(text, context.temp_allocator)
	if ffi.xmpp_stanza_set_text(text_node, c_text) != ffi.EOK do return false

	return ffi.xmpp_stanza_add_child_ex(s.handle, text_node, 1) == ffi.EOK
}

// Sets the body element of a <message> stanza using libstrophe's message helper
message_set_body :: proc(msg: ^Stanza, text: string) -> bool {
	if msg == nil || msg.handle == nil do return false
	c_text := strings.clone_to_cstring(text, context.temp_allocator)
	return ffi.xmpp_message_set_body(msg.handle, c_text) == ffi.EOK
}

// Retrieves the body string of a <message> stanza, cloned into caller's allocator
message_get_body :: proc(msg: Stanza, allocator := context.allocator) -> string {
	if msg.handle == nil do return ""
	c_body := ffi.xmpp_message_get_body(msg.handle)
	if c_body == nil do return ""

	ctx := ffi.xmpp_stanza_get_context(msg.handle)
	defer ffi.xmpp_free(ctx, rawptr(c_body))

	return strings.clone_from_cstring(c_body, allocator)
}

// Retrieves all concatenated child text nodes into caller's allocator
stanza_get_text :: proc(s: Stanza, allocator := context.allocator) -> string {
	if s.handle == nil do return ""
	c_text := ffi.xmpp_stanza_get_text(s.handle)
	if c_text == nil do return ""

	// Ensure we free the C memory returned by libstrophe after cloning
	ctx := ffi.xmpp_stanza_get_context(s.handle)
	defer ffi.xmpp_free(ctx, rawptr(c_text))

	return strings.clone_from_cstring(c_text, allocator)
}

// Serializes the entire stanza to an XML string
stanza_to_text :: proc(s: Stanza, allocator := context.allocator) -> (string, bool) {
	if s.handle == nil do return "", false

	var_buf: cstring
	var_buflen: c.size_t
	res := ffi.xmpp_stanza_to_text(s.handle, &var_buf, &var_buflen)
	if res != ffi.EOK || var_buf == nil do return "", false

	ctx := ffi.xmpp_stanza_get_context(s.handle)
	defer ffi.xmpp_free(ctx, rawptr(var_buf))

	cloned := strings.clone_from_cstring(var_buf, allocator)
	return cloned, true
}

// Adds a child stanza to this stanza
stanza_add_child :: proc(parent: ^Stanza, child: Stanza) -> bool {
	if parent == nil || parent.handle == nil || child.handle == nil do return false
	// Add child with cloning enabled to keep caller's ownership simple and safe
	return ffi.xmpp_stanza_add_child_ex(parent.handle, child.handle, 1) == ffi.EOK
}

// Creates an empty stanza
stanza_new :: proc(ctx: ffi.Context) -> Stanza {
	if ctx == nil do return {}
	h := ffi.xmpp_stanza_new(ctx)
	return Stanza{handle = h, owns_handle = true}
}

// Creates a new <message> stanza
message_new :: proc(ctx: ffi.Context, type := "chat", to := "", id := "") -> Stanza {
	if ctx == nil do return {}

	c_type := strings.clone_to_cstring(type, context.temp_allocator) if len(type) > 0 else nil
	c_to := strings.clone_to_cstring(to, context.temp_allocator) if len(to) > 0 else nil
	c_id := strings.clone_to_cstring(id, context.temp_allocator) if len(id) > 0 else nil

	h := ffi.xmpp_message_new(ctx, c_type, c_to, c_id)
	return Stanza{handle = h, owns_handle = true}
}

// Creates a new <presence> stanza
presence_new :: proc(ctx: ffi.Context) -> Stanza {
	if ctx == nil do return {}
	h := ffi.xmpp_presence_new(ctx)
	return Stanza{handle = h, owns_handle = true}
}

// Creates a new <iq> stanza
iq_new :: proc(ctx: ffi.Context, type := "get", id := "") -> Stanza {
	if ctx == nil do return {}

	c_type := strings.clone_to_cstring(type, context.temp_allocator) if len(type) > 0 else nil
	c_id := strings.clone_to_cstring(id, context.temp_allocator) if len(id) > 0 else nil

	h := ffi.xmpp_iq_new(ctx, c_type, c_id)
	return Stanza{handle = h, owns_handle = true}
}
