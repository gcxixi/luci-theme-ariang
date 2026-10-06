#!/usr/bin/env bash
#
# Standalone IPK packager for luci-theme-ariang
# Generates valid opkg-compatible .ipk without needing full OpenWrt SDK
#

set -e

PKG_NAME="luci-theme-ariang"
PKG_VERSION="1.0.0"
PKG_RELEASE="2"
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
# Also place cascade.css at theme root for LuCI sysauth / login page fallback
if [ -f "htdocs/luci-static/ariang/css/cascade.css" ]; then
  cp "htdocs/luci-static/ariang/css/cascade.css" "$DATA_DIR/www/luci-static/ariang/cascade.css"
fi

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
  uci -q batch <<-UCI_EOF
    set luci.themes.AriaNg=/luci-static/ariang
    commit luci
UCI_EOF
  rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
  [ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart
  [ -x /etc/init.d/uhttpd ] && /etc/init.d/uhttpd restart
}
exit 0
EOF
chmod +x "$CONTROL_DIR/postinst"

# Generate postrm script
cat <<EOF > "$CONTROL_DIR/postrm"
#!/bin/sh
[ -n "\$IPKG_INSTROOT" ] || {
  uci -q delete luci.themes.AriaNg
  [ "\$(uci -q get luci.main.mediaurlbase)" = "/luci-static/ariang" ] && {
    uci -q set luci.main.mediaurlbase=/luci-static/bootstrap
  }
  uci commit luci
  rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
  [ -x /etc/init.d/rpcd ] && /etc/init.d/rpcd restart
}
exit 0
EOF
chmod +x "$CONTROL_DIR/postrm"

export COPYFILE_DISABLE=1

# OpenWrt opkg/busybox tar strictly requires ustar format and rejects 0x78 (pax extended headers)
TAR_OPTS="--format ustar"
if tar --version 2>&1 | grep -q "bsdtar"; then
  TAR_OPTS="--format ustar --no-xattrs --no-mac-metadata"
fi

echo "==> Compressing data and control archives (ustar format)..."
tar $TAR_OPTS --numeric-owner --owner=0 --group=0 -czf "$WORKDIR/data.tar.gz" -C "$DATA_DIR" .
tar $TAR_OPTS --numeric-owner --owner=0 --group=0 -czf "$WORKDIR/control.tar.gz" -C "$CONTROL_DIR" .
echo "2.0" > "$WORKDIR/debian-binary"

IPK_FILE="${OUTPUT_DIR}/${PKG_NAME}_${PKG_VERSION}-${PKG_RELEASE}_${ARCH}.ipk"
echo "==> Packaging into ${IPK_FILE}..."

# Build tar.gz-based ipk (opkg standard)
tar $TAR_OPTS -czf "$IPK_FILE" -C "$WORKDIR" debian-binary control.tar.gz data.tar.gz

echo "✓ Successfully built: ${IPK_FILE}"
ls -lh "$IPK_FILE"
