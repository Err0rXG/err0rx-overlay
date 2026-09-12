# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CMAKE_MAKEFILE_GENERATOR="ninja"

inherit cmake git-r3 xdg

DESCRIPTION="A lightweight Qt6/QML file manager for Hyprland"
HOMEPAGE="https://github.com/soyeb-jim285/hyprfm"

# Fetched via git-r3 rather than a plain SRC_URI tag tarball: GitHub's
# archive/refs/tags/*.tar.gz does NOT include git submodule content,
# and hyprfm vendors its icon set + "Quill" QML component library as
# submodules under src/qml/. git-r3 defaults to checking out all
# submodules when EGIT_SUBMODULES is unset.
EGIT_REPO_URI="https://github.com/soyeb-jim285/${PN}.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
PROPERTIES="live"

# Each flag below maps 1:1 to an entry in HyprFM's own in-app
# "Missing dependencies" panel (Settings -> checked at runtime),
# confirmed by actually running a built copy:
#   - wl-clipboard  -> clipboard
#   - bat           -> bat
#   - GVFS gphoto2 backend (camera/PTP browsing) -> gphoto2
#   - EXIF/GPS/timestamp metadata reading -> exif
# mtp and ffmpeg are documented in upstream release notes (Android/MTP
# device detection, video thumbnails) rather than shown in that panel,
# but follow the same optional-runtime-helper pattern.
# kwindowsystem is optional at the CMake level (find_package(...
# QUIET), confirmed from CMakeLists.txt) rather than a runtime helper.
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
	bat? ( app-text/bat )
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
# None of the optional deps above are linked at build time -- they're
# all spawned as external processes (bat, exiftool, ffmpeg) or used
# via gvfs/GIO at runtime, so RDEPEND-only is correct for all of them.

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTS=$(usex test)
	)
	cmake_src_configure
}
