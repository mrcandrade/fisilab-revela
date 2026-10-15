#!/usr/bin/env bash
# Build, sign and (optionally) notarize the macOS release artifacts:
#
#   $DIST/FisiLab-Revela-<version>-macOS.dmg             Revela.app on a drag-to-Applications DMG (universal;
#                                                        FisiLab-Revela-<version>-macOS-<arch>.dmg for one arch)
#   $DIST/fisilab-revela-cli-<version>-macos-<arch>.zip  the headless CLI
#
# Usage: packaging/macos/package.sh [--arch universal|aarch64|x86_64] [--skip-build]
#
# Signing (env):
#   MACOS_SIGN_IDENTITY   codesign identity (name or SHA-1). Default "-" = ad-hoc (local testing;
#                         Gatekeeper will reject the result on other Macs). In CI, import-cert.sh sets it.
#   MACOS_KEYCHAIN        keychain holding the identity (optional)
# Notarization (env; all three needed, and a real identity):
#   APPLE_ID, APPLE_PASSWORD (app-specific password), APPLE_TEAM_ID
set -euo pipefail
# shellcheck source=../env.sh
. "$(dirname "${BASH_SOURCE[0]}")/../env.sh"
HERE="$ROOT/packaging/macos"

ARCH=universal
SKIP_BUILD=0
while [ $# -gt 0 ]; do
  case "$1" in
    --arch) ARCH="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    -h | --help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
case "$ARCH" in
  universal) TARGETS=(aarch64-apple-darwin x86_64-apple-darwin) ;;
  aarch64) TARGETS=(aarch64-apple-darwin) ;;
  x86_64) TARGETS=(x86_64-apple-darwin) ;;
  *) echo "unknown --arch $ARCH" >&2; exit 2 ;;
esac

# Keep in sync with LSMinimumSystemVersion in Info.plist.in.
export MACOSX_DEPLOYMENT_TARGET=11.0
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
SHORT_VERSION="${VERSION%%-*}"
WORK="$CARGO_TARGET_DIR/macos-package"
APP="$WORK/Revela.app"
if [ "$ARCH" = universal ]; then DMG_SUFFIX=""; else DMG_SUFFIX="-$ARCH"; fi
DMG="$DIST/FisiLab-Revela-$VERSION-macOS$DMG_SUFFIX.dmg"
CLI_ZIP="$DIST/fisilab-revela-cli-$VERSION-macos-$ARCH.zip"

NOTARIZE=0
if [ "$IDENTITY" = "-" ]; then
  warn "macOS: ad-hoc signing (no MACOS_SIGN_IDENTITY); artifacts are not notarized"
elif [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_PASSWORD:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
  NOTARIZE=1
else
  warn "macOS: APPLE_ID / APPLE_PASSWORD / APPLE_TEAM_ID incomplete; signed but not notarized"
fi

echo "==> Revela $VERSION for macOS ($ARCH), identity: $IDENTITY, notarize: $NOTARIZE"

# ---- build -------------------------------------------------------------------------------------
if [ "$SKIP_BUILD" = 0 ]; then
  args=()
  for t in "${TARGETS[@]}"; do args+=(--target "$t"); done
  (cd "$ROOT" && cargo build --release --locked -p lightcraft -p lightcraft-cli --features lightcraft/heif,lightcraft-cli/heif "${args[@]}")
fi

rm -rf "$WORK"
mkdir -p "$WORK/bin"
for bin in fisilab-revela fisilab-revela-cli; do
  inputs=()
  for t in "${TARGETS[@]}"; do inputs+=("$CARGO_TARGET_DIR/$t/release/$bin"); done
  lipo -create -output "$WORK/bin/$bin" "${inputs[@]}"
  lipo -info "$WORK/bin/$bin"
done

# ---- signing helpers ---------------------------------------------------------------------------
sign() {
  # Hardened runtime + secure timestamp for a real identity; ad-hoc can't be timestamped.
  local ts=(--timestamp)
  [ "$IDENTITY" = "-" ] && ts=(--timestamp=none)
  local kc=()
  [ -n "${MACOS_KEYCHAIN:-}" ] && kc=(--keychain "$MACOS_KEYCHAIN")
  codesign --force --sign "$IDENTITY" ${kc[@]+"${kc[@]}"} "${ts[@]}" "$@"
}

notarize() {
  local file="$1" out id status
  echo "==> notarizing $(basename "$file") (this can take a few minutes)"
  out="$(xcrun notarytool submit "$file" --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" --wait --timeout 1h --output-format json)" || true
  echo "$out"
  id="$(printf '%s' "$out" | plutil -extract id raw -o - - 2>/dev/null || true)"
  status="$(printf '%s' "$out" | plutil -extract status raw -o - - 2>/dev/null || true)"
  if [ "$status" != "Accepted" ]; then
    if [ -n "$id" ]; then
      xcrun notarytool log "$id" --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID" || true
    fi
    echo "error: notarization of $(basename "$file") failed (status: ${status:-unknown})" >&2
    exit 1
  fi
}

# ---- Revela.app ----------------------------------------------------------------------------
echo "==> assembling $APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
# Executable and icon carry the display name (CFBundleExecutable / CFBundleIconFile).
cp "$WORK/bin/fisilab-revela" "$APP/Contents/MacOS/Revela"
cp "$ROOT/assets/fisilab/fisilab-revela.icns" "$APP/Contents/Resources/Revela.icns"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@SHORT_VERSION@/$SHORT_VERSION/g" \
  -e "s/@BUILD_SHA@/${LIGHTCRAFT_BUILD_SHA:-unknown}/g" \
  "$HERE/Info.plist.in" >"$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist"
printf 'APPL????' >"$APP/Contents/PkgInfo"
# Licences (and the craft-fonts font licences when built with CRAFT_FONTS_DIR) inside the bundle.
copy_docs "$APP/Contents/Resources"

# Remove inherited build-time extended attributes BEFORE code signing.
# Never repair, re-sign or strip metadata from the published release after signing.
xattr -cr "$APP"

# Sign inside-out: nested code first, then the bundle itself (no --deep on the final signature).
# Today the only nested code is the main executable; frameworks/helpers would be signed here too.
sign --options runtime --entitlements "$HERE/entitlements.plist" "$APP/Contents/MacOS/Revela"
sign --options runtime --entitlements "$HERE/entitlements.plist" "$APP"
codesign --verify --strict --deep --verbose=2 "$APP"

if [ "$NOTARIZE" = 1 ]; then
  ditto -c -k --keepParent "$APP" "$WORK/Revela-notarize.zip"
  notarize "$WORK/Revela-notarize.zip"
  xcrun stapler staple "$APP"
  xcrun stapler validate "$APP"
  spctl --assess --type execute -vvv "$APP"
fi

# ---- DMG ---------------------------------------------------------------------------------------
echo "==> building $DMG"
STAGE="$WORK/dmg"
mkdir -p "$STAGE"
ditto "$APP" "$STAGE/Revela.app"
ln -s /Applications "$STAGE/Aplicativos"
# Finder window layout: background, icon size and positions (packaging/macos/dmg/README.md).
mkdir -p "$STAGE/.background"
cp "$HERE/dmg/background.tiff" "$STAGE/.background/background.tiff"
cp "$HERE/dmg/dmg-layout.DS_Store" "$STAGE/.DS_Store"
rm -f "$DMG"
# `hdiutil create -srcfolder` writes the files as they are. `makehybrid -hfs` gave every file a
# com.apple.FinderInfo, which `codesign --verify --strict` rejects as "Finder information, or
# similar detritus" on the app in the image and on a copy installed from it (problema conhecido
# dos projetos originais). `create` attaches a device
# while it copies, which fails now and then on CI runners ("Resource busy"), so it gets a few
# tries. The volume name has no version: .DS_Store finds the background through an alias that
# includes it.
# Usage: hdiutil_retry <what> <hdiutil args…>; tries five times with growing pauses.
hdiutil_retry() {
  local what="$1" attempt
  shift
  for attempt in 1 2 3 4 5; do
    if hdiutil "$@"; then
      return 0
    fi
    [ "$attempt" = 5 ] && { echo "hdiutil $what failed 5 times" >&2; return 1; }
    echo "hdiutil $what failed (attempt $attempt of 5); retrying in $((attempt * 10))s" >&2
    sleep $((attempt * 10))
  done
}
hdiutil_retry create create -srcfolder "$STAGE" -volname "Revela" -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$DMG"
sign "$DMG"
codesign --verify --strict --verbose=2 "$DMG"
# The app inside the image must still pass --strict, so a makehybrid-style regression can't ship.
MOUNT="$WORK/dmg-check"
rm -rf "$MOUNT"
mkdir -p "$MOUNT"
hdiutil_retry attach attach -nobrowse -readonly -mountpoint "$MOUNT" "$DMG" >/dev/null
if ! codesign --verify --strict --deep --verbose=2 "$MOUNT/Revela.app"; then
  hdiutil_retry detach detach "$MOUNT" >/dev/null || true
  exit 1
fi
hdiutil_retry detach detach "$MOUNT" >/dev/null

# Verification must use the FINISHED image (and a normal ditto-installed copy).
# Signatures of the DMG container alone do not validate the bundle in the image.
verify_dmg_app() {
  local mount="$WORK/dmg-verify-mount" copy="$WORK/dmg-verify-copy" rc=0
  mkdir -p "$mount" "$copy"
  if ! hdiutil_retry attach -readonly -nobrowse -noautoopen -mountpoint "$mount" "$DMG" >/dev/null; then
    echo "error: unable to mount finished $DMG" >&2
    hdiutil detach "$mount" >/dev/null 2>&1 || true
    return 1
  fi
  echo "==> strict codesign of Revela.app in finished DMG"
  codesign --verify --deep --strict --verbose=2 "$mount/Revela.app" || rc=1
  if [ "$rc" = 0 ]; then
    ditto "$mount/Revela.app" "$copy/Revela.app" || rc=1
  fi
  if [ "$rc" = 0 ]; then
    echo "==> strict codesign of Revela.app after ditto install-copy"
    codesign --verify --deep --strict --verbose=2 "$copy/Revela.app" || rc=1
  fi
  if [ "$rc" = 0 ] && [ "$NOTARIZE" = 1 ]; then
    spctl --assess --type execute -vvv "$copy/Revela.app" || rc=1
  fi
  if [ "$rc" != 0 ]; then
    echo "error: published-image app verification failed; reject $DMG" >&2
    xattr -lr "$mount/Revela.app" >&2 || true
  fi
  if ! hdiutil_retry detach "$mount" >/dev/null; then
    echo "error: could not detach verification mount" >&2
    rc=1
  fi
  rm -rf "$copy"
  return "$rc"
}
verify_dmg_app
if [ "$NOTARIZE" = 1 ]; then
  notarize "$DMG"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  spctl --assess --type open --context context:primary-signature -vvv "$DMG"
fi

# ---- CLI ---------------------------------------------------------------------------------------
echo "==> building $CLI_ZIP"
CLI_DIR="$WORK/fisilab-revela-cli-$VERSION-macos-$ARCH"
mkdir -p "$CLI_DIR"
cp "$WORK/bin/fisilab-revela-cli" "$CLI_DIR/"
copy_docs "$CLI_DIR"
# Same entitlements as the app: `--opt addToPhotos=true` / `app.export {addToPhotos}` send Apple
# Events to Photos through osascript too (macOS asks about the app that started the CLI, usually
# the terminal).
sign --options runtime --entitlements "$HERE/entitlements.plist" "$CLI_DIR/fisilab-revela-cli"
codesign --verify --strict --verbose=2 "$CLI_DIR/fisilab-revela-cli"
rm -f "$CLI_ZIP"
ditto -c -k --keepParent "$CLI_DIR" "$CLI_ZIP"
# A bare Mach-O can't carry a stapled ticket; Gatekeeper looks the notarization up online.
if [ "$NOTARIZE" = 1 ]; then notarize "$CLI_ZIP"; fi

"$WORK/bin/fisilab-revela-cli" --version
echo "==> done"
ls -lh "$DMG" "$CLI_ZIP"
