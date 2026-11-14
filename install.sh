#!/bin/sh
# Builds handy-rewrite and installs it as Handy's transcription hook.
#
#   ./install.sh               build + install (binary, hook, example config)
#   ./install.sh --uninstall   remove binary and hook (config is kept)
#
# PREFIX defaults to ~/.local (binary goes to $PREFIX/bin).
set -eu

cd "$(dirname "$0")"
PREFIX="${PREFIX:-$HOME/.local}"
BIN="$PREFIX/bin/handy-rewrite"
HOOK_DIR="$HOME/Library/Application Support/com.pais.handy/hooks"
HOOK="$HOOK_DIR/transcription"
CONFIG_DIR="$HOME/.config/handy-rewrite"
CONFIG="$CONFIG_DIR/config.json"

if [ "${1:-}" = "--uninstall" ]; then
    if [ -f "$HOOK" ] && grep -q handy-rewrite "$HOOK"; then rm "$HOOK"; echo "removed $HOOK"; fi
    rm -f "$BIN" && echo "removed $BIN"
    echo "kept $CONFIG"
    exit 0
fi

command -v swiftc >/dev/null || { echo "swiftc not found – install the Command Line Tools: xcode-select --install" >&2; exit 1; }

echo "building …"
mkdir -p "$PREFIX/bin"
swiftc -O -swift-version 5 -parse-as-library HandyRewrite.swift -o "$BIN"
echo "installed $BIN"

mkdir -p "$HOOK_DIR"
if [ -f "$HOOK" ] && ! grep -q handy-rewrite "$HOOK"; then
    cp "$HOOK" "$HOOK.backup"
    echo "existing hook backed up to $HOOK.backup"
fi
cat > "$HOOK" <<EOF
#!/bin/sh
# Handy transcription hook: stdin = transcript, stdout = text to paste
exec 2>/dev/null
exec "$BIN" hook
EOF
chmod +x "$HOOK"
echo "installed hook $HOOK"

if [ ! -f "$CONFIG" ]; then
    mkdir -p "$CONFIG_DIR"
    cp config.example.json "$CONFIG"
    echo "created $CONFIG – edit base_url and model"
fi

echo
"$BIN" config || {
    echo
    echo "Next steps:"
    echo "  1. edit $CONFIG"
    echo "  2. store your API key:  security add-generic-password -s handy-rewrite -a \"\$USER\" -w"
    echo "  3. check:               handy-rewrite config"
}
