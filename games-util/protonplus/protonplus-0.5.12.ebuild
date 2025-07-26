# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson xdg

DESCRIPTION="A modern compatibility tools manager for gaming launchers"
HOMEPAGE="https://github.com/Vysp3r/ProtonPlus"

if [[ ${PV} == *9999* ]] ; then
	EGIT_REPO_URI="https://github.com/Vysp3r/ProtonPlus.git"
	inherit git-r3
else
	SRC_URI="https://github.com/Vysp3r/ProtonPlus/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=gui-libs/gtk-4.0:4
	>=gui-libs/libadwaita-1.6:1
	>=dev-libs/glib-2.0:2
	>=dev-libs/json-glib-1.0:0
	>=net-libs/libsoup-3.0:3.0
	>=dev-libs/libgee-0.8:0.8
	>=app-arch/libarchive-3.0:0=
"

DEPEND="${RDEPEND}"

BDEPEND="
	>=dev-util/meson-1.0.0
	dev-util/ninja
	dev-lang/vala:*
	sys-devel/gettext
	test? (
		dev-util/desktop-file-utils
		dev-libs/appstream-glib
		dev-util/glib-utils
	)
"

src_configure() {
	local emesonargs=(
		# Install to /opt instead of default locations
		--bindir=/opt/${PN}
		--datadir=/opt/${PN}/share
		$(meson_use test tests)
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	# Create wrapper script and symlink to /usr/bin for PATH access
	cat > "${T}/${PN}" <<-EOF || die
#!/bin/sh
exec /opt/${PN}/protonplus "\$@"
EOF

	dobin "${T}/${PN}"

	# Adjust desktop file to point to correct binary location
	if [[ -f "${ED}/opt/${PN}/share/applications/com.vysp3r.ProtonPlus.desktop" ]]; then
		sed -i "s|Exec=protonplus|Exec=${PN}|" 			"${ED}/opt/${PN}/share/applications/com.vysp3r.ProtonPlus.desktop" || die

		# Install desktop file to system location for XDG integration
		insinto /usr/share/applications
		doins "${ED}/opt/${PN}/share/applications/com.vysp3r.ProtonPlus.desktop"

		# Remove from /opt/share to avoid duplication
		rm "${ED}/opt/${PN}/share/applications/com.vysp3r.ProtonPlus.desktop" || die
	fi

	# Install icons to system location for XDG integration
	if [[ -d "${ED}/opt/${PN}/share/icons" ]]; then
		cp -r "${ED}/opt/${PN}/share/icons" "${ED}/usr/share/" || die
		rm -rf "${ED}/opt/${PN}/share/icons" || die
	fi

	# Install metainfo to system location for XDG integration
	if [[ -f "${ED}/opt/${PN}/share/metainfo/com.vysp3r.ProtonPlus.metainfo.xml" ]]; then
		insinto /usr/share/metainfo
		doins "${ED}/opt/${PN}/share/metainfo/com.vysp3r.ProtonPlus.metainfo.xml"
		rm "${ED}/opt/${PN}/share/metainfo/com.vysp3r.ProtonPlus.metainfo.xml" || die
	fi

	# Install GSettings schema to system location
	if [[ -f "${ED}/opt/${PN}/share/glib-2.0/schemas/com.vysp3r.ProtonPlus.gschema.xml" ]]; then
		insinto /usr/share/glib-2.0/schemas
		doins "${ED}/opt/${PN}/share/glib-2.0/schemas/com.vysp3r.ProtonPlus.gschema.xml"
		rm "${ED}/opt/${PN}/share/glib-2.0/schemas/com.vysp3r.ProtonPlus.gschema.xml" || die
	fi

	# Install localization files to system location
	if [[ -d "${ED}/opt/${PN}/share/locale" ]]; then
		cp -r "${ED}/opt/${PN}/share/locale" "${ED}/usr/share/" || die
		rm -rf "${ED}/opt/${PN}/share/locale" || die
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	elog ""
	elog "ProtonPlus has been installed to /opt/${PN}"
	elog "A wrapper script has been created at /usr/bin/${PN} for easy access"
	elog ""
	elog "ProtonPlus can manage compatibility tools for:"
	elog "  - Steam"
	elog "  - Lutris"
	elog "  - Heroic Games Launcher"
	elog "  - Bottles"
	elog "  - WineZGUI"
	elog ""
	elog "Make sure you have your gaming launchers properly configured"
	elog "before using ProtonPlus to manage compatibility tools."
	elog ""
}

pkg_postrm() {
	xdg_pkg_postrm
}
