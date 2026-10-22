package xmpp

import "core:mem"
import "core:testing"

@test
test_jid_parse_full :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
		mem.tracking_allocator_destroy(&track)
	}

	jid, ok := jid_parse("alice@example.com/mobile")
	defer jid_destroy(&jid)

	testing.expect(t, ok, "expected valid parse")
	testing.expect_value(t, jid.node, "alice")
	testing.expect_value(t, jid.domain, "example.com")
	testing.expect_value(t, jid.resource, "mobile")
	testing.expect_value(t, jid.raw, "alice@example.com/mobile")

	bare := jid_bare(jid)
	defer delete(bare)
	testing.expect_value(t, bare, "alice@example.com")
}

@test
test_jid_parse_bare :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
		mem.tracking_allocator_destroy(&track)
	}

	jid, ok := jid_parse("bob@chat.server.org")
	defer jid_destroy(&jid)

	testing.expect(t, ok, "expected valid parse")
	testing.expect_value(t, jid.node, "bob")
	testing.expect_value(t, jid.domain, "chat.server.org")
	testing.expect_value(t, jid.resource, "")

	bare := jid_bare(jid)
	defer delete(bare)
	testing.expect_value(t, bare, "bob@chat.server.org")
}

@test
test_jid_parse_domain_only :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)
	defer {
		testing.expect_value(t, len(track.allocation_map), 0)
		testing.expect_value(t, len(track.bad_free_array), 0)
		mem.tracking_allocator_destroy(&track)
	}

	jid, ok := jid_parse("muc.chat.server.org")
	defer jid_destroy(&jid)

	testing.expect(t, ok, "expected valid parse")
	testing.expect_value(t, jid.node, "")
	testing.expect_value(t, jid.domain, "muc.chat.server.org")
	testing.expect_value(t, jid.resource, "")

	bare := jid_bare(jid)
	defer delete(bare)
	testing.expect_value(t, bare, "muc.chat.server.org")
}

@test
test_jid_invalid :: proc(t: ^testing.T) {
	testing.expect(t, !jid_is_valid(""), "empty string is invalid")
	testing.expect(t, !jid_is_valid("@domain.com"), "missing node is invalid when @ is present")

	_, ok1 := jid_parse("")
	testing.expect(t, !ok1, "empty parse should fail")

	_, ok2 := jid_parse("@")
	testing.expect(t, !ok2, "lonely @ should fail")
}
