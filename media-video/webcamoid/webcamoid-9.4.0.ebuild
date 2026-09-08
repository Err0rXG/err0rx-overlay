# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="Full featured webcam capture application"
HOMEPAGE="
	https://webcamoid.github.io
	https://github.com/webcamoid/webcamoid
"
SRC_URI="https://github.com/webcamoid/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

IUSE="
	alsa
	avdevice
	debug
	ffmpeg
	ffmpeg-screencap
	flatpak-vcam
	libusb
	libuvc
	openmp
	pipewire
	pipewire-dynload
	portaudio
	pulseaudio
	pulseaudio-dynload
	qtcamera
	qtscreencapture
	+screencapture
	v4l
	veffects
	wlroots
	X

	cpu_flags_arm_neon
	cpu_flags_arm_sve
	cpu_flags_x86_avx
	cpu_flags_x86_avx2
	cpu_flags_x86_mmx
	cpu_flags_x86_sse
	cpu_flags_x86_sse2
	cpu_flags_x86_sse4_1
"

REQUIRED_USE="
	avdevice? ( ffmpeg )
	ffmpeg-screencap? ( ffmpeg )
	qtscreencapture? ( screencapture )
	wlroots? ( screencapture )
	X? ( screencapture )
	pipewire-dynload? ( pipewire )
	pulseaudio-dynload? ( pulseaudio )
"

COMMON_DEPEND="
	dev-qt/qtbase:6[concurrent,dbus,gui,network,opengl,widgets]
	dev-qt/qtdeclarative:6
	dev-qt/qtmultimedia:6
	dev-qt/qtsvg:6

	alsa? (
		media-libs/alsa-lib
	)

	ffmpeg? (
		media-video/ffmpeg:=
	)

	libusb? (
		dev-libs/libusb:1
	)

	libuvc? (
		>=media-libs/libuvc-0.0.7
	)

	pipewire? (
		media-video/pipewire:=
	)

	portaudio? (
		media-libs/portaudio
	)

	pulseaudio? (
		media-libs/libpulse
	)

	v4l? (
		media-libs/libv4l
	)

	wlroots? (
		dev-libs/wayland
		dev-libs/wayland-protocols
	)

	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXrandr
	)
"

DEPEND="
	${COMMON_DEPEND}
	>=sys-kernel/linux-headers-3.6
"

BDEPEND="
	wlroots? (
		dev-util/wayland-scanner
	)
"

RDEPEND="
	${COMMON_DEPEND}
	virtual/opengl
"

src_configure() {
	# Release tarballs do not contain the Git metadata expected by
	# Webcamoid's CMake configuration.
	sed -i \
		's|find_program(GIT_BIN git)|#find_program(GIT_BIN git)|' \
		libAvKys/cmake/ProjectCommons.cmake || die

	local mycmakeargs=(
		# ---------------------------------------------------------------
		# Update checking
		# ---------------------------------------------------------------

		# Compile out Webcamoid's update-check functionality.
		-DNOCHECKUPDATES=ON

		# ---------------------------------------------------------------
		# General build configuration
		# ---------------------------------------------------------------

		# Gentoo controls compiler/linker optimisation flags.
		-DENABLE_IPO=OFF

		# Flatpak virtual-camera support.
		-DWITH_FLATPAK_VCAM=$(usex flatpak-vcam)

		# ---------------------------------------------------------------
		# OpenMP
		# ---------------------------------------------------------------

		-DNOOPENMP=$(usex !openmp)

		# ---------------------------------------------------------------
		# Audio backends
		# ---------------------------------------------------------------

		-DNOALSA=$(usex !alsa)
		-DNOPORTAUDIO=$(usex !portaudio)
		-DNOPULSEAUDIO=$(usex !pulseaudio)
		-DPIPEWIRE_DYNLOAD=$(usex pipewire-dynload)
		-DPULSEAUDIO_DYNLOAD=$(usex pulseaudio-dynload)

		# ---------------------------------------------------------------
		# Camera / media backends
		# ---------------------------------------------------------------

		-DNOFFMPEG=$(usex !ffmpeg)
		-DNOLIBAVDEVICE=$(usex !avdevice)
		-DNOLIBUSB=$(usex !libusb)
		-DNOLIBUVC=$(usex !libuvc)
		-DNOQTCAMERA=$(usex !qtcamera)
		-DNOV4L2=$(usex !v4l)

		# ---------------------------------------------------------------
		# Desktop / screen capture backends
		# ---------------------------------------------------------------

		-DNOSCREENCAPTURE=$(usex !screencapture)
		-DNOFFMPEGSCREENCAP=$(usex !ffmpeg-screencap)
		-DNOQTSCREENCAPTURE=$(usex !qtscreencapture)
		-DNOWLROOTS=$(usex !wlroots)
		-DNOXLIBSCREENCAP=$(usex !X)

		# ---------------------------------------------------------------
		# Video effects
		# ---------------------------------------------------------------

		-DNOVIDEOEFFECTS=$(usex !veffects)

		# ---------------------------------------------------------------
		# SIMD / Gentoo USE_EXPAND CPU feature flags
		# ---------------------------------------------------------------

		-DNOSIMDMMX=$(usex !cpu_flags_x86_mmx)
		-DNOSIMDSSE=$(usex !cpu_flags_x86_sse)
		-DNOSIMDSSE2=$(usex !cpu_flags_x86_sse2)
		-DNOSIMDSSE4_1=$(usex !cpu_flags_x86_sse4_1)
		-DNOSIMDAVX=$(usex !cpu_flags_x86_avx)
		-DNOSIMDAVX2=$(usex !cpu_flags_x86_avx2)
		-DNOSIMDNEON=$(usex !cpu_flags_arm_neon)
		-DNOSIMDSVE=$(usex !cpu_flags_arm_sve)

		# ---------------------------------------------------------------
		# Non-Linux platform backends
		# ---------------------------------------------------------------

		-DNODSHOW=ON
		-DNOMEDIAFOUNDATION=ON
		-DNOWASAPI=ON
		-DNONDKMEDIA=ON
	)

	if use debug; then
		mycmakeargs+=(
			-DCMAKE_BUILD_TYPE=Debug
		)
	else
		mycmakeargs+=(
			-DCMAKE_BUILD_TYPE=RelWithDebInfo
		)
	fi

	cmake_src_configure
}

src_install() {
	docompress -x /usr/share/man/man1/${PN}.1.gz
	cmake_src_install
}
