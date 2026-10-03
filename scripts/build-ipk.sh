#!/usr/bin/env bash
#
# Standalone IPK packager for luci-theme-ariang
# Generates valid opkg-compatible .ipk without needing full OpenWrt SDK
#

set -e

PKG_NAME="luci-theme-ariang"
PKG_VERSION="1.0.0"
PKG_RELEASE="1"
ARCH="all"
OUTPUT_DIR="bin"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Preparing package directory tree..."
PKG_ROOT="$WORKDIR/pkg"
DATA_DIR="$WORKDIR/data"
CONTROL_DIR="$WORKDIR/control"

mkdir -p "$DATA_DIR/www/luci-static/ariang"
mkdir -p "$DATA_DIR/usr/lib/lua/luci/view/themes/ariang"
mkdir -p "$DATA_DIR/usr/share/ucode/luci/template/themes/ariang"
mkdir -p "$DATA_DIR/etc/uci-defaults"
mkdir -p "$CONTROL_DIR"
mkdir -p "$OUTPUT_DIR"

# Copy web static assets
cp -r htdocs/luci-static/ariang/* "$DATA_DIR/www/luci-static/ariang/"

# Copy Lua templates
if [ -d "luasrc/view/themes/ariang" ]; then
  cp -r luasrc/view/themes/ariang/* "$DATA_DIR/usr/lib/lua/luci/view/themes/ariang/"
fi

# Copy ucode templates
if [ -d "ucode/template/themes/ariang" ]; then
  cp -r ucode/template/themes/ariang/* "$DATA_DIR/usr/share/ucode/luci/template/themes/ariang/"
fi

# Copy uci-defaults
if [ -f "root/etc/uci-defaults/30_luci-theme-ariang" ]; then
  cp root/etc/uci-defaults/30_luci-theme-ariang "$DATA_DIR/etc/uci-defaults/"
  chmod +x "$DATA_DIR/etc/uci-defaults/30_luci-theme-ariang"
fi

# Generate control file
cat <<EOF > "$CONTROL_DIR/control"
Package: ${PKG_NAME}
Version: ${PKG_VERSION}-${PKG_RELEASE}
Depends: libc
Section: luci
Architecture: ${ARCH}
Maintainer: gcxixi
Description: AriaNg High-Density Design Theme for LuCI with Instant Parameter Filter.
EOF

# Generate postinst script
cat <<EOF > "$CONTROL_DIR/postinst"
#!/bin/sh
[ -n "\$IPKG_INSTROOT" ] || {
  uci set luci.themes.AriaNg=/luci-static/ariang
  uci commit luci
}
exit 0
EOF
chmod +x "$CONTROL_DIR/postinst"

# Generate postrm script
cat <<EOF > "$CONTROL_DIR/postrm"
#!/bin/sh
[ -n "\$IPKG_INSTROOT" ] || {
  uci delete luci.themes.AriaNg 2>/dev/null
  uci commit luci
}
exit 0
EOF
chmod +x "$CONTROL_DIR/postrm"

echo "==> Compressing data and control archives..."
tar --numeric-owner --owner=0 --group=0 -czf "$WORKDIR/data.tar.gz" -C "$DATA_DIR" .
tar --numeric-owner --owner=0 --group=0 -czf "$WORKDIR/control.tar.gz" -C "$CONTROL_DIR" .
echo "2.0" > "$WORKDIR/debian-binary"

IPK_FILE="${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${ARCH}.ipk"
echo "==> Packaging into ${IPK_FILE}..."

# Build tar.gz-based ipk (opkg standard)
tar -czf "$IPK_FILE" -C "$WORKDIR" debian-binary control.tar.gz data.tar.gz

echo "✓ Successfully built: ${IPK_FILE}"
ls -lh "$IPK_FILE"
