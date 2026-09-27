# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
PYTHON_COMPAT=( python3_{12..14} )
inherit java-pkg-2 desktop python-single-r1

GRADLE_VER="9.8.0"

RELEASE_VERSION="${PV}"

DESCRIPTION="A software reverse engineering framework"
HOMEPAGE="https://ghidra-sre.org/"

PROTOC_VER="4.31.0"
#Z3_ARM64_OSX_VER = "11.0"
#Z3_X64_OSX_VER = "11.7.10"
SEVENZIP_VER="16.02-2.01"
case ${ARCH} in
	amd64)
		Z3_VER="4.13.0"
		Z3_ARCH="x64"
		Z3_GLIBC_VER="2.31"
		GHIDRA_PLATFORM="linux_x86_64"
		SEVENZIP_PLATFORM="Linux-amd64"
		;;
	arm64)
		Z3_VER="5.1.0"
		Z3_ARCH="arm64"
		Z3_GLIBC_VER="2.38"
		GHIDRA_PLATFORM="linux_arm_64"
		SEVENZIP_PLATFORM="Linux-arm64"
		;;
	*)
		Z3_VER="4.13.0"
		Z3_ARCH="x64"
		Z3_GLIBC_VER="2.31"
		GHIDRA_PLATFORM="linux_x86_64"
		SEVENZIP_PLATFORM="Linux-amd64"
		;;
esac

Z3_NAME="z3-${Z3_VER}-${Z3_ARCH}-glibc-${Z3_GLIBC_VER}"

SRC_URI="https://github.com/NationalSecurityAgency/${PN}/archive/refs/tags/Ghidra_${PV}_build.tar.gz
	https://github.com/Err0rXG/err0rx-overlay-distfiles/releases/download/${P}/${PN}-dependencies-${PV}.tar.gz
	https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip
	arm64? (
		https://github.com/Z3Prover/z3/releases/download/z3-5.1.0/z3-5.1.0-arm64-glibc-2.38.zip
		https://repo1.maven.org/maven2/com/google/protobuf/protoc/${PROTOC_VER}/protoc-${PROTOC_VER}-linux-aarch_64.exe
		https://repo1.maven.org/maven2/net/sf/sevenzipjbinding/sevenzipjbinding-linux-arm64/${SEVENZIP_VER}/sevenzipjbinding-linux-arm64-${SEVENZIP_VER}.jar
		https://repo1.maven.org/maven2/net/sf/sevenzipjbinding/sevenzipjbinding-linux-arm64/${SEVENZIP_VER}/sevenzipjbinding-linux-arm64-${SEVENZIP_VER}.pom
	)
"

S="${WORKDIR}/ghidra-Ghidra_${PV}_build"
LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 ~arm64"

QA_FLAGS_IGNORED="
	usr/share/ghidra/GPL/DemanglerGnu/os/${GHIDRA_PLATFORM}/demangler_gnu_v2_24
	usr/share/ghidra/GPL/DemanglerGnu/os/${GHIDRA_PLATFORM}/demangler_gnu_v2_41
	usr/share/ghidra/Ghidra/Features/Decompiler/os/${GHIDRA_PLATFORM}/decompile
	usr/share/ghidra/Ghidra/Features/Decompiler/os/${GHIDRA_PLATFORM}/sleigh
	usr/share/ghidra/Ghidra/Features/FileFormats/data/sevenzipnativelibs/${SEVENZIP_PLATFORM}/lib7-Zip-JBinding.so
	usr/share/ghidra/Ghidra/Features/FileFormats/os/${GHIDRA_PLATFORM}/lzfse
"

JAVA_PKG_WANT_SOURCE="27"
JAVA_PKG_WANT_TARGET="27"

REQUIRED_USE=${PYTHON_REQUIRED_USE}

RDEPEND="virtual/jre:27
		${PYTHON_DEPS}"
DEPEND="${RDEPEND}
	virtual/jdk:27
	sys-devel/bison
	dev-java/jflex
	app-arch/unzip"
BDEPEND=">=dev-java/gradle-bin-${GRADLE_VER}:* >=dev-java/gradle-bin-9.8.0
		dev-python/pip"

PATCHES=(
	"${FILESDIR}"/ghidra-12.1.4-jdk27-appcontext.patch
)

check_gradle_binary() {
        local gradle_link_target currentver requiredver

        gradle_link_target="$(readlink -n /usr/bin/gradle)"
        currentver="${gradle_link_target/gradle-bin-/}"
        requiredver="${GRADLE_VER}"

        einfo "Gradle version ${currentver} currently selected."
        einfo "Gradle version ${requiredver} or higher is required."

        if [[ -z ${currentver} ]]; then
                eerror "Unable to determine the currently selected Gradle version."
                die "Please run 'eselect gradle list' and select Gradle ${requiredver} or newer."
        elif [[ "$(printf '%s\n' "${requiredver}" "${currentver}" | sort -V | head -n1)" == "${requiredver}" ]]; then
                einfo "Selected Gradle ${currentver} satisfies the minimum required version ${requiredver}."
        else
                eerror "Gradle ${requiredver} or higher must be selected before building ${PN}."
                die "Please run 'eselect gradle list' and 'eselect gradle set <version>'."
        fi
}

pkg_setup() {
	java-pkg-2_pkg_setup
	python-single-r1_pkg_setup
}

src_unpack() {
	unpack ${A}

	# Merge the pre-fetched dependency bundle into the source tree. It
	# already matches what Ghidra's own gradle/support/fetchDependencies.gradle
	# produces (flatRepo, fidb, Debugger-agent-dbgeng, Debugger-rmi-trace,
	# GhidraDev, GhidraServer, BSim, SymbolicSummaryZ3, and a pre-populated
	# dependencies/gradle offline module cache) -- verified end-to-end via
	# `gradle --offline prepdev` in CI before being published.
	cd "${S}" || die
	mv "${WORKDIR}/dependencies" . || die "failed to merge dependencies bundle"

	# dex-tools isn't part of Ghidra's own fetchDependencies.gradle deps
	# list, so it's still fetched and placed separately.
	cp "${WORKDIR}"/dex-tools-v2.4/lib/dex-*.jar \
		dependencies/flatRepo/ || die "dex-tools cp failed"

	if use arm64; then
		# No Linux-arm64 Z3 build exists in Ghidra's official fetcher,
		# so it's fetched and placed manually here.
		mkdir -p dependencies/SymbolicSummaryZ3/os/${GHIDRA_PLATFORM} || die

		cp "${WORKDIR}/${Z3_NAME}"/bin/libz3*.so \
			dependencies/SymbolicSummaryZ3/os/${GHIDRA_PLATFORM} || die

		cp "${WORKDIR}/${Z3_NAME}"/bin/*.jar \
			dependencies/flatRepo/ || die

		local sevenzip_dir="dependencies/net/sf/sevenzipjbinding/sevenzipjbinding-linux-arm64/${SEVENZIP_VER}"

		mkdir -p "${sevenzip_dir}" || die
		cp "${DISTDIR}/sevenzipjbinding-linux-arm64-${SEVENZIP_VER}.jar" \
			"${sevenzip_dir}/" || die
		cp "${DISTDIR}/sevenzipjbinding-linux-arm64-${SEVENZIP_VER}.pom" \
			"${sevenzip_dir}/" || die

		mkdir -p "dependencies/com/google/protobuf/protoc/${PROTOC_VER}" || die
		cp "${DISTDIR}/protoc-${PROTOC_VER}-linux-aarch_64.exe" \
			"dependencies/com/google/protobuf/protoc/${PROTOC_VER}/" || die
		chmod +x \
			"dependencies/com/google/protobuf/protoc/${PROTOC_VER}/protoc-${PROTOC_VER}-linux-aarch_64.exe" || die
	fi
}

src_prepare() {
        mkdir -p "dependencies/gradle/init.d" || die "(10) mkdir failed"
        cp "${FILESDIR}"/repos.gradle dependencies/gradle/init.d || die "(11) cp failed"
        sed -i "s|S_DIR|${S}|g" dependencies/gradle/init.d/repos.gradle || die "(12) sed failed"

        # Remove build date so we can unpack dist.zip later
        sed -i "s|_\${rootProject.BUILD_DATE_SHORT}||g" \
                gradle/root/distribution.gradle || die "(13) sed failed"

        # Use the correct Python version selected by python-single-r1
        # https://github.com/pentoo/pentoo-overlay/issues/2243
        sed -i "s/findPython3(true)/\"${EPYTHON}\"/" build.gradle || die

        if use arm64; then
                eapply "${FILESDIR}/ghidra-12.1.3-sevenzip-arm64.patch"
        fi

        eapply "${PATCHES[@]}"

        eapply_user
}

src_compile() {
        check_gradle_binary
        export _JAVA_OPTIONS="$_JAVA_OPTIONS -Duser.home=$HOME -Djava.io.tmpdir=${T}"

        GRADLE="gradle --gradle-user-home dependencies/gradle --console rich --no-daemon"
        GRADLE="${GRADLE} --offline --parallel --max-workers $(nproc)"
        unset TERM

        ${GRADLE} prepDev -x check -x test || die
        ${GRADLE} assembleAll -x check -x test --parallel || die

}

src_install() {
        # Remove zip files which aren't needed at runtime
        find "build/dist/ghidra_${PV}_DEV/" -type f -name '*.zip' -exec rm -f {} +

        # FIXME: add doc flag
        rm -r "build/dist/ghidra_${PV}_DEV/docs/" || die "rm failed"

        insinto /usr/share/ghidra
        doins -r "build/dist/ghidra_${PV}_DEV/"*

        fperms +x /usr/share/ghidra/ghidraRun
        fperms +x /usr/share/ghidra/support/launch.sh
        fperms +x /usr/share/ghidra/GPL/DemanglerGnu/os/${GHIDRA_PLATFORM}/demangler_gnu_v2_41
        fperms +x /usr/share/ghidra/Ghidra/Features/Decompiler/os/${GHIDRA_PLATFORM}/decompile

        shopt -s nullglob
        # cd to install dir so the globbing works even when Ghidra isn't installed already
        pushd "${ED}" || die
        fperms +x usr/share/ghidra/Ghidra/Debug/Debugger-*/data/{debugger-launchers,support}/*.sh
        popd || die
        shopt -u nullglob

        dosym -r /usr/share/ghidra/ghidraRun /usr/bin/ghidra

        # icon
        doicon GhidraDocs/GhidraClass/Beginner/Images/GhidraLogo64.png

        # desktop entry
        make_desktop_entry ${PN} "Ghidra" /usr/share/pixmaps/GhidraLogo64.png "Utility"
}
