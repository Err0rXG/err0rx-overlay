# @Author : XaetaCore
# Distributed under the terms of the GNU General Public License v2
EAPI=8
inherit desktop unpacker

DESCRIPTION="ProtonPass Free password manager with identity protection"
HOMEPAGE="https://proton.me/pass"
SRC_URI="https://proton.me/download/pass/linux/proton-pass_${PV}_amd64.deb"
S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
DEPEND="x11-libs/gtk+:3
    x11-libs/libnotify
    dev-libs/nss
    x11-libs/libXtst
    x11-misc/xdg-utils
    app-accessibility/at-spi2-core
    x11-libs/libdrm
    x11-libs/libxcb
    dev-libs/glib:2"
RDEPEND="${DEPEND}"

src_install() {
  # We skip /usr/share/doc
  insinto /usr
  doins -r usr/bin
  doins -r usr/lib
  insinto /usr/share
  doins -r usr/share/applications
  doins -r usr/share/pixmaps
  doins -r usr/share/lintian

  # Fix permissions
  fperms +x /usr/bin/proton-pass
}
