#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

CATALOG=Sources/DomicileCore/Resources/Localizable.xcstrings
SD_DIR=$(mktemp -d)/stringsdata
mkdir -p "$SD_DIR"

# SwiftBuild skips our targets for -emit-localized-strings; native does not.
swift package clean
swift build --build-system native \
    -Xswiftc -emit-localized-strings \
    -Xswiftc -emit-localized-strings-path \
    -Xswiftc "$SD_DIR" 2>&1 | grep -v "deprecat" || true

jq -n '{sourceLanguage:"en",strings:{},version:"1.0"}' > "$CATALOG"

FILES=""
for f in "$SD_DIR"/*.stringsdata; do
    src=$(plutil -convert json -o - "$f" | jq -r '.source // empty')
    case "$src" in
        "$PWD"/Sources/*) FILES="$FILES $f" ;;
    esac
done
[ -n "$FILES" ] || { echo "no stringsdata emitted for package sources" >&2; exit 1; }
# shellcheck disable=SC2086
xcrun xcstringstool sync "$CATALOG" --stringsdata $FILES

jq '.strings |= with_entries(
    if .value.localizations.en.stringUnit.state == "new"
    then .value.localizations.en.stringUnit.state = "translated" else . end
)' "$CATALOG" > "$CATALOG.tmp" && mv "$CATALOG.tmp" "$CATALOG"
jq empty "$CATALOG"

OUT=$(mktemp -d)
xcrun xcstringstool compile "$CATALOG" -o "$OUT"
plutil -lint "$OUT/en.lproj/Localizable.strings" >/dev/null
echo "catalog: $(xcrun xcstringstool print "$CATALOG" | grep -c .) keys, compiled OK"
