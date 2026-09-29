# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH="/usr/share/openpgp-keys/torproject.org.asc"

inherit desktop verify-sig xdg

DESCRIPTION="Privacy-focused web browser based on Firefox and the Tor network"
HOMEPAGE="https://www.torproject.org/"

SRC_URI="
	https://dist.torproject.org/torbrowser/${PV}/tor-browser-linux-x86_64-${PV}.tar.xz
	verify-sig? (
		https://dist.torproject.org/torbrowser/${PV}/tor-browser-linux-x86_64-${PV}.tar.xz.asc
	)
"

S="${WORKDIR}/tor-browser"

LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64"
IUSE="verify-sig"

RESTRICT="strip"

BDEPEND="
	verify-sig? (
		>=sec-keys/openpgp-keys-tor-20250713
	)
"

RDEPEND="
	|| (
		media-libs/libpulse
		media-sound/apulse
	)
	>=app-accessibility/at-spi2-core-2.46.0:2
	>=dev-libs/glib-2.26:2
	media-libs/alsa-lib
	media-libs/fontconfig
	>=media-libs/freetype-2.4.10
	sys-apps/dbus
	virtual/freedesktop-icon-theme
	>=x11-libs/cairo-1.10[X]
	x11-libs/gdk-pixbuf:2
	>=x11-libs/gtk+-3.11:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libxcb
	>=x11-libs/pango-1.22.0
"

QA_PREBUILT="
	opt/torbrowser/*
"

src_install() {
	# Install the complete official Tor Browser bundle.
	dodir /opt
	cp -a "${S}" "${ED}/opt/torbrowser" || die "failed to install Tor Browser"

	# Tell the Tor Browser launcher and Firefox that this is a
	# system-packaged installation.
	echo 'This is a packaged app.' \
		> "${ED}/opt/torbrowser/Browser/is-packaged-app" \
		|| die "failed to create is-packaged-app marker"

	# The upstream archive ships executable files as 0744.
	# Add execute permission for group/other while preserving
	# the set of files that upstream marked executable.
	local -a _executables=()
	local _file

	while IFS= read -r -d '' _file; do
		_executables+=( "${_file#${ED}}" )
	done < <(
		find "${ED}/opt/torbrowser" \
			-type f \
			-perm -0100 \
			-print0
	)

	if ((${#_executables[@]})); then
		fperms +x "${_executables[@]}" || die "failed to fix executable permissions"
	fi

	# Main launcher.
	cat > "${T}/torbrowser" <<-EOF || die
		#!/bin/sh
		exec /opt/torbrowser/Browser/start-tor-browser "\$@"
	EOF

	newbin "${T}/torbrowser" torbrowser

	# Desktop entry.
	cat > "${T}/torbrowser.desktop" <<-EOF || die
		[Desktop Entry]
		Type=Application
		Name=Tor Browser
		GenericName=Web Browser
		Comment=Privacy-focused web browser using the Tor network
		Exec=/usr/bin/torbrowser %U
		Terminal=false
		Categories=Network;WebBrowser;
		StartupWMClass=Tor Browser
		Icon=torbrowser
	EOF

	domenu "${T}/torbrowser.desktop"

	# Use Tor Browser's bundled icon.
	if [[ -f "${S}/Browser/browser/chrome/icons/default/default128.png" ]]; then
		newicon -s 128 \
			"${S}/Browser/browser/chrome/icons/default/default128.png" \
			torbrowser.png
	elif [[ -f "${S}/Browser/browser/chrome/icons/default/default48.png" ]]; then
		newicon -s 48 \
			"${S}/Browser/browser/chrome/icons/default/default48.png" \
			torbrowser.png
	else
		die "Tor Browser icon not found"
	fi
}
