# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson xdg gnome2-utils

DESCRIPTION="A modern compatibility tools manager for gaming launchers"
HOMEPAGE="https://github.com/Vysp3r/ProtonPlus"

if [[ ${PV} == *9999* ]] ; then
	EGIT_REPO_URI="https://github.com/Vysp3r/ProtonPlus.git"
	inherit git-r3
else
	SRC_URI="https://github.com/Vysp3r/ProtonPlus/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/ProtonPlus-${PV}"
	KEYWORDS="~amd64 ~x86"
fi

LICENSE="GPL-3"
SLOT="0"

IUSE="+protontricks"

RDEPEND="
	>=gui-libs/gtk-4.0:4
	>=gui-libs/libadwaita-1.6:1
	>=dev-libs/glib-2.0:2
	>=dev-libs/json-glib-1.0:0
	>=net-libs/libsoup-3.0:3.0
	>=dev-libs/libgee-0.8:0.8
	>=app-arch/libarchive-3.0:0=

	protontricks? ( app-emulation/protontricks[gui] )
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-build/meson-1.0.0
	dev-build/ninja
	dev-lang/vala:*
	sys-devel/gettext

"

src_configure() {
	local emesonargs=(
		# Install to /opt instead of default locations
		--bindir=/opt/${PN}/bin
		--datadir=/opt/${PN}/share
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	
	# Create wrapper script and symlink to /usr/bin for PATH access
	cat > "${T}/${PN}" <<-EOF || die
#!/bin/sh
exec /opt/${PN}/bin/protonplus "\$@"
EOF
	dobin "${T}/${PN}"
	
	# Handle desktop file
	local desktop_file="${ED}/opt/${PN}/share/applications/com.vysp3r.ProtonPlus.desktop"
	if [[ -f "${desktop_file}" ]]; then
		sed -i "s|Exec=protonplus|Exec=${PN}|" "${desktop_file}" || die
		# Install desktop file to system location for XDG integration
		insinto /usr/share/applications
		doins "${desktop_file}"
		# Remove from /opt/share to avoid duplication
		rm "${desktop_file}" || die
		# Remove empty applications directory if it exists
		[[ -d "${ED}/opt/${PN}/share/applications" ]] && rmdir "${ED}/opt/${PN}/share/applications" 2>/dev/null || true
	fi
	
	# Handle icons
	local icons_dir="${ED}/opt/${PN}/share/icons"
	if [[ -d "${icons_dir}" ]]; then
		cp -r "${icons_dir}" "${ED}/usr/share/" || die
		rm -rf "${icons_dir}" || die
	fi
	
	# Handle metainfo
	local metainfo_file="${ED}/opt/${PN}/share/metainfo/com.vysp3r.ProtonPlus.metainfo.xml"
	if [[ -f "${metainfo_file}" ]]; then
		insinto /usr/share/metainfo
		doins "${metainfo_file}"
		rm "${metainfo_file}" || die
		# Remove empty metainfo directory if it exists
		[[ -d "${ED}/opt/${PN}/share/metainfo" ]] && rmdir "${ED}/opt/${PN}/share/metainfo" 2>/dev/null || true
	fi
	
	# Handle GSettings schema
	local gschema_file="${ED}/opt/${PN}/share/glib-2.0/schemas/com.vysp3r.ProtonPlus.gschema.xml"
	if [[ -f "${gschema_file}" ]]; then
		insinto /usr/share/glib-2.0/schemas
		doins "${gschema_file}"
		rm "${gschema_file}" || die
		# Remove empty schema directories if they exist
		[[ -d "${ED}/opt/${PN}/share/glib-2.0/schemas" ]] && rmdir "${ED}/opt/${PN}/share/glib-2.0/schemas" 2>/dev/null || true
		[[ -d "${ED}/opt/${PN}/share/glib-2.0" ]] && rmdir "${ED}/opt/${PN}/share/glib-2.0" 2>/dev/null || true
	fi
	
	# Look for additional schema files that might exist
	if [[ -d "${ED}/opt/${PN}/share/glib-2.0/schemas" ]]; then
		insinto /usr/share/glib-2.0/schemas
		doins "${ED}"/opt/${PN}/share/glib-2.0/schemas/*.xml
		rm -rf "${ED}/opt/${PN}/share/glib-2.0" || die
	fi
	
	# Handle localization files
	#local locale_dir="${ED}/opt/${PN}/share/locale"
	#if [[ -d "${locale_dir}" ]]; then
	#	cp -r "${locale_dir}" "${ED}/usr/share/" || die
	#	rm -rf "${locale_dir}" || die
	#fi
	
	# Clean up empty share directory if it exists
	[[ -d "${ED}/opt/${PN}/share" ]] && rmdir "${ED}/opt/${PN}/share" 2>/dev/null || true
}

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
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

	if ! use protontricks; then
		elog "Optional: Install app-emulation/protontricks or enable the"
		elog "'protontricks' USE flag to integrate with Protontricks for"
		elog "advanced Proton prefix management and game tweaking."
		elog ""
	fi
	elog "Make sure you have your gaming launchers properly configured"
	elog "before using ProtonPlus to manage compatibility tools."
	elog ""
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
