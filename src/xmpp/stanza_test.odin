package xmpp

import "core:mem"
import "core:strings"
import "core:testing"
import ffi "ffi:strophe"

@test
test_stanza_lifecycle_and_serialization :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
		mem.tracking_allocator_destroy(&track)
	}

	ffi.xmpp_initialize()
	defer ffi.xmpp_shutdown()

	ctx := ffi.xmpp_ctx_new(nil, nil)
	defer ffi.xmpp_ctx_free(ctx)

	msg := message_new(ctx, type = "chat", to = "user@example.com", id = "msg-123")
	defer stanza_destroy(&msg)

	testing.expect_value(t, stanza_get_name(msg), "message")
	testing.expect_value(t, stanza_get_type(msg), "chat")
	testing.expect_value(t, stanza_get_to(msg), "user@example.com")
	testing.expect_value(t, stanza_get_id(msg), "msg-123")

	// Set message body
	ok_body := message_set_body(&msg, "Hello from Odin!")
	testing.expect(t, ok_body, "setting body should succeed")

	// Serialize to XML string
	xml_str, ok_xml := stanza_to_text(msg)
	defer delete(xml_str)

	testing.expect(t, ok_xml, "stanza_to_text should succeed")
	testing.expect(t, strings.contains(xml_str, "<message"), "XML should contain <message")
	testing.expect(t, strings.contains(xml_str, `to="user@example.com"`), "XML should contain to attribute")
	testing.expect(t, strings.contains(xml_str, "<body>Hello from Odin!</body>"), "XML should contain body text")
}

@test
test_stanza_attributes :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
		mem.tracking_allocator_destroy(&track)
	}

	ffi.xmpp_initialize()
	defer ffi.xmpp_shutdown()

	ctx := ffi.xmpp_ctx_new(nil, nil)
	defer ffi.xmpp_ctx_free(ctx)

	s := stanza_new(ctx)
	defer stanza_destroy(&s)
	stanza_set_name(&s, "iq")

	stanza_set_attribute(&s, "type", "get")
	stanza_set_attribute(&s, "id", "iq-001")

	type_val, ok_type := stanza_get_attribute(s, "type")
	testing.expect(t, ok_type, "type attribute should exist")
	testing.expect_value(t, type_val, "get")

	id_val, ok_id := stanza_get_attribute(s, "id")
	testing.expect(t, ok_id, "id attribute should exist")
	testing.expect_value(t, id_val, "iq-001")

	// Delete attribute
	stanza_del_attribute(&s, "id")
	_, ok_id_after := stanza_get_attribute(s, "id")
	testing.expect(t, !ok_id_after, "id attribute should be deleted")
}
