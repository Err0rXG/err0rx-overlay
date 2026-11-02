# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.90.0"

inherit cargo desktop

DESCRIPTION="NetworkManager GUI client built on nmrs and gpui"
HOMEPAGE="https://github.com/freedesktop-rs/nmrs-gui"
SRC_URI="
	https://github.com/freedesktop-rs/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/Err0rXG/err0rx-overlay-distfiles/releases/download/${P}/${P}-crates.tar.xz
"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+=" 0BSD Apache-2.0 BSD BSD-2 Boost-1.0 CC0-1.0 GPL-2 ISC LGPL-2.1+ MIT-0 MPL-2.0 UoI-NCSA Unicode-3.0 Unlicense ZLIB"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+lto thinlto"
REQUIRED_USE="thinlto? ( lto )"

DEPEND="
	dev-libs/wayland
	media-libs/fontconfig
	media-libs/freetype
	x11-libs/libxcb:=
	x11-libs/libxkbcommon[X,wayland]
"
RDEPEND="
	${DEPEND}
	media-libs/vulkan-loader
	net-misc/networkmanager
"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default

	# Upstream sets strip = true in [profile.release]; let Portage handle stripping
	sed -i -e 's/^strip = true/strip = false/' Cargo.toml || die

	if ! use lto; then
		# no LTO, parallel codegen
		sed -i \
			-e 's/^lto = "fat"/lto = "off"/' \
			-e 's/^codegen-units = 1/codegen-units = 16/' \
			Cargo.toml || die
	elif use thinlto; then
		# thin LTO, parallel codegen
		sed -i \
			-e 's/^lto = "fat"/lto = "thin"/' \
			-e 's/^codegen-units = 1/codegen-units = 16/' \
			Cargo.toml || die
	fi
}

src_install() {
	cargo_src_install

	domenu nmrs.desktop
	dodoc README.md CHANGELOG.md
}

pkg_postinst() {
	elog "nmrs-gui renders through Vulkan (gpui). Make sure a Vulkan driver is"
	elog "installed, e.g. media-libs/mesa[vulkan] or your GPU vendor's driver."
}
