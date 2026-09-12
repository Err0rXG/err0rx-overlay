# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CMAKE_MAKEFILE_GENERATOR="ninja"

inherit cmake xdg

DESCRIPTION="A lightweight Qt6/QML file manager for Hyprland"
HOMEPAGE="https://github.com/soyeb-jim285/hyprfm"

# hyprfm vendors its icon set (quill-icons) and its QML component
# library (quill) as git submodules under src/qml/. A plain
# archive/refs/tags/*.tar.gz from GitHub does NOT include submodule
# content (only a gitlink placeholder), so each submodule is fetched
# here as its own pinned-commit archive and moved into place in
# src_prepare. Commit hashes below are exactly what the v0.6.1 tag's
# .gitmodules pins point at (confirmed via `git fetch` output when
# building this package -- see the submodule commit lines logged
# during "Fetching ... quill-icons.git" / "... quill.git").
# If bumping to a newer hyprfm release, these WILL need updating:
# check .gitmodules in the new tag, or just `git submodule status`
# in a manual clone of that tag, for the new pinned commits.
QUILL_ICONS_COMMIT="10db5facf6a560e60d2693ccd1909267ef436002"
QUILL_COMMIT="bc13deae669a1333a0d7bdd991c7015270a16a38"

SRC_URI="
	https://github.com/soyeb-jim285/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/soyeb-jim285/quill-icons/archive/${QUILL_ICONS_COMMIT}.tar.gz -> ${PN}-quill-icons-${QUILL_ICONS_COMMIT}.tar.gz
	https://github.com/soyeb-jim285/quill/archive/${QUILL_COMMIT}.tar.gz -> ${PN}-quill-${QUILL_COMMIT}.tar.gz
"
S="${WORKDIR}/${PN}-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# Each flag below maps 1:1 to an entry in HyprFM's own in-app
# "Missing dependencies" panel, confirmed by actually running a
# built copy: wl-clipboard -> clipboard, bat -> bat, GVFS gphoto2
# backend -> gphoto2, EXIF/GPS/timestamp metadata -> exif. mtp and
# ffmpeg are documented in upstream release notes (Android/MTP
# device detection, video thumbnails). kwindowsystem is optional at
# the CMake level (find_package(... QUIET) in CMakeLists.txt).
IUSE="+kwindowsystem bat clipboard exif ffmpeg gphoto2 mtp test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-libs/glib:2
	dev-qt/qtbase:6[concurrent,dbus,gui,network,widgets]
	dev-qt/qtdeclarative:6
	dev-qt/qtsvg:6
	dev-qt/qtwayland:6
	sys-apps/fd
	x11-misc/xdg-utils
	kwindowsystem? ( kde-frameworks/kwindowsystem:6 )
	bat? ( sys-apps/bat )
	clipboard? ( gui-apps/wl-clipboard )
	exif? ( media-libs/exiftool )
	ffmpeg? ( media-video/ffmpeg )
	gphoto2? ( gnome-base/gvfs[gphoto2] )
	mtp? ( gnome-base/gvfs[mtp] )
"
DEPEND="${RDEPEND}"
BDEPEND="
	dev-build/cmake
	dev-build/ninja
	virtual/pkgconfig
	test? ( dev-qt/qttest:6 )
"

src_unpack() {
	default

	# Move the two submodule archives into the exact paths the
	# .gitmodules entries (and src/CMakeLists.txt's qt_add_qml_module
	# calls) expect. GitHub archive extraction dirs are named
	# "<repo>-<commit>", not the submodule's target directory name.
	rmdir "${S}/src/qml/icons" "${S}/src/qml/Quill" 2>/dev/null
	mv "${WORKDIR}/quill-icons-${QUILL_ICONS_COMMIT}" \
		"${S}/src/qml/icons" || die
	mv "${WORKDIR}/quill-${QUILL_COMMIT}" \
		"${S}/src/qml/Quill" || die
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTS=$(usex test)
	)
	cmake_src_configure
}
