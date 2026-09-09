EAPI=8

CRATES=""
RUST_MIN_VER="1.95.0"

inherit cargo desktop shell-completion xdg

DESCRIPTION="Blazing fast terminal file manager written in Rust, based on async I/O."
HOMEPAGE="https://yazi-rs.github.io https://github.com/sxyazi/yazi"

SRC_URI="
	https://github.com/sxyazi/yazi/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/gentoo-zh-drafts/${PN}/releases/download/v${PV}/${P}-crates.tar.xz
	${CARGO_CRATE_URIS}
"

# ratatui is pinned in Cargo.lock to a commit on the fix_buffer_diff_wide_cells branch.
# The Gentoo cargo helper fetches the commit archive, while the Cargo patch below
# redirects the lockfile's git source to the unpacked local checkout.
declare -A GIT_CRATES=(
	[ratatui-core]="https://github.com/yazi-rs/ratatui;dde5e05eccfe5b7cb7712b4bdf76edd0c2cd1f25;ratatui-%commit%/ratatui-core"
)

LICENSE="
	MIT
	Apache-2.0
	BSD
	BSD-2
	BSD-3
	ISC
	MPL-2.0
	Unicode-DFS-2016
	Unlicense
	ZLIB
"
SLOT="0"
KEYWORDS="~amd64 ~riscv"

IUSE="+cli"

QA_FLAGS_IGNORED="usr/bin/ya.*"

DOCS=( README.md )

src_prepare() {
	export YAZI_GEN_COMPLETIONS=true

	sed -i -r 's/strip\s+= true/strip = false/' Cargo.toml || die

	cat >> "${ECARGO_HOME}/config.toml" <<-EOF || die
		[patch.'https://github.com/yazi-rs/ratatui.git?branch=fix_buffer_diff_wide_cells']
		ratatui-core = { path = "${WORKDIR}/ratatui-dde5e05eccfe5b7cb7712b4bdf76edd0c2cd1f25/ratatui-core" }
	EOF

	eapply_user
}

src_compile() {
	cargo_src_compile --locked
	use cli && cargo_src_compile -p "${PN}-cli"
}

src_install() {
	dobin "$(cargo_target_dir)/${PN}"

	if use cli; then
		dobin "$(cargo_target_dir)/ya"
	fi

	newbashcomp yazi-boot/completions/yazi.bash yazi
	dozshcomp yazi-boot/completions/_yazi
	dofishcomp yazi-boot/completions/yazi.fish

	if use cli; then
		newbashcomp yazi-cli/completions/yazi.bash ya
		dozshcomp yazi-cli/completions/_yazi
		dofishcomp yazi-cli/completions/yazi.fish
	fi

	domenu assets/yazi.desktop
	einstalldocs
}
