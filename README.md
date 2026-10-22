# Odin-xmpp

An XMPP (Jabber) client library for the Odin programming language, providing both low-level C FFI bindings to [libstrophe](https://github.com/strophe/libstrophe) and an idiomatic, memory-conscious Odin interface.

## Prerequisites

- **Odin compiler** (recent dev/release build)
- **libstrophe**:
  - macOS (Homebrew): `brew install libstrophe`
  - Debian/Ubuntu: `sudo apt-get install libstrophe-dev`
  - Arch Linux: `sudo pacman -S libstrophe`

## Project Structure

```
Odin-xmpp/
├── src/xmpp/          # High-level idiomatic Odin XMPP package
├── ffi/strophe/       # Low-level foreign C bindings to libstrophe
├── cmd/xmpp_echo/     # Sample echo bot CLI
├── scripts/           # Build, test, and verification entry points
└── artifacts/         # Build outputs (binaries, libraries; gitignored)
```

## Quick Start

### Build

```sh
./scripts/build.sh
```

This compiles the example CLI executable into `artifacts/xmpp_echo`.

### Test

```sh
./scripts/test.sh
```

Runs the test suite under the Odin tracking allocator to guarantee zero leaks.

### Running the Example Echo Bot

```sh
XMPP_JID="user@example.com" XMPP_PASS="secret" ./artifacts/xmpp_echo
```

## License

This project is licensed under the zlib/libpng license. See the [LICENSE](LICENSE) file for details.

