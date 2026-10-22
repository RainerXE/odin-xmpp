package strophe

import "core:c"

// Namespaces
NS_CLIENT             :: "jabber:client"
NS_COMPONENT          :: "jabber:component:accept"
NS_STREAMS            :: "http://etherx.jabber.org/streams"
NS_STREAMS_IETF       :: "urn:ietf:params:xml:ns:xmpp-streams"
NS_STANZAS_IETF       :: "urn:ietf:params:xml:ns:xmpp-stanzas"
NS_TLS                :: "urn:ietf:params:xml:ns:xmpp-tls"
NS_SASL               :: "urn:ietf:params:xml:ns:xmpp-sasl"
NS_BIND               :: "urn:ietf:params:xml:ns:xmpp-bind"
NS_SESSION            :: "urn:ietf:params:xml:ns:xmpp-session"
NS_AUTH               :: "jabber:iq:auth"
NS_DISCO_INFO         :: "http://jabber.org/protocol/disco#info"
NS_DISCO_ITEMS        :: "http://jabber.org/protocol/disco#items"
NS_ROSTER             :: "jabber:iq:roster"
NS_REGISTER           :: "jabber:iq:register"
NS_SM                 :: "urn:xmpp:sm:3"
NS_COMPRESSION        :: "http://jabber.org/protocol/compress"
NS_FEATURE_COMPRESSION :: "http://jabber.org/features/compress"

// Return codes
EOK    ::  0
EMEM   :: -1
EINVOP :: -2
EINT   :: -3

// Connection Flags
CONN_FLAG_DISABLE_TLS              :: c.long(1 << 0)
CONN_FLAG_MANDATORY_TLS            :: c.long(1 << 1)
CONN_FLAG_LEGACY_SSL               :: c.long(1 << 2)
CONN_FLAG_TRUST_TLS                :: c.long(1 << 3)
CONN_FLAG_LEGACY_AUTH              :: c.long(1 << 4)
CONN_FLAG_DISABLE_SM               :: c.long(1 << 5)
CONN_FLAG_ENABLE_COMPRESSION       :: c.long(1 << 6)
CONN_FLAG_COMPRESSION_DONT_RESET   :: c.long(1 << 7)

// Log level
Log_Level :: enum c.int {
	DEBUG = 0,
	INFO  = 1,
	WARN  = 2,
	ERROR = 3,
}

// Connection Type
Conn_Type :: enum c.int {
	UNKNOWN   = 0,
	CLIENT    = 1,
	COMPONENT = 2,
}

// Connection Event
Conn_Event :: enum c.int {
	CONNECT     = 0,
	RAW_CONNECT = 1,
	DISCONNECT  = 2,
	FAIL        = 3,
}

// Stream Error Type
Error_Type :: enum c.int {
	BAD_FORMAT = 0,
	BAD_NS_PREFIX,
	CONFLICT,
	CONN_TIMEOUT,
	HOST_GONE,
	HOST_UNKNOWN,
	IMPROPER_ADDR,
	INTERNAL_SERVER_ERROR,
	INVALID_FROM,
	INVALID_ID,
	INVALID_NS,
	INVALID_XML,
	NOT_AUTHORIZED,
	POLICY_VIOLATION,
	REMOTE_CONN_FAILED,
	RESOURCE_CONSTRAINT,
	RESTRICTED_XML,
	SEE_OTHER_HOST,
	SYSTEM_SHUTDOWN,
	UNDEFINED_CONDITION,
	UNSUPPORTED_ENCODING,
	UNSUPPORTED_STANZA_TYPE,
	UNSUPPORTED_VERSION,
	XML_NOT_WELL_FORMED,
}
