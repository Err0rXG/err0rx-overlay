🎮 Custom Gentoo Gaming Ebuild Repository

Welcome! This is a personal Gentoo ebuild overlay focused on gaming. Here you’ll find:

    🛠️ Updated or customized ebuilds for games, emulators, and related tools

    🔄 Fixes for outdated/upstream-lagging ebuilds

    📝 Personal tweaks, patches, or enhancements for the best Linux gaming experience

🚀 Purpose

    Maintain Custom Ebuilds: Store and organize modified/upgraded ebuilds for games & gaming utilities.

    Stay Up-to-Date: Revive and renew abandoned or outdated ebuilds not available in official Gentoo repos.

    Gaming Focus: Prioritize tools, engines, and software relevant to Linux gamers.

    Version Control: Use Git for easy updates, rollback, and sharing across machines.

📚 How to Use This Overlay
1️⃣ Add the Repository with eselect-repository (Recommended)

text
sudo eselect repository add my-gaming-overlay git https://github.com/Err0rXG/err0rx-overlay.git
sudo emaint sync -r my-gaming-overlay

    The overlay will be added and synced, ready for use!
    📝 Note: Make sure eselect-repository is installed (emerge eselect-repository).

2️⃣ OR: Manual Method

    Clone the overlay:

text
git clone https://github.com/Err0rXG/err0rx-overlay.git /var/db/repos/err0rx-overlay

Register the overlay by creating /etc/portage/repos.conf/err0rx-overlay.conf:

    text
    [my-gaming-overlay]
    location = /var/db/repos/err0rx-overlay
    masters = gentoo
    auto-sync = true

🛠️ Typical Workflow

    📝 Add or update ebuilds in the correct category/package directory.

    ⚡ Run repoman manifest inside each package dir after changes.

    💾 git add, git commit, and git push your changes to your remote repo for backup and cross-device sync.

    🕹️ Use Portage as usual (emerge <package>) – your gaming customizations will be found and managed like any other Gentoo package!

💡 Best Practices

    🏷️ Describe major changes in the README.md or commit messages.

    ❌ Keep your .gitignore up to date to skip build artifacts or temp files.

    👾 Regularly test ebuilds to keep your overlay clean and functional.

📜 License

This repository is licensed under the GNU General Public License v2.0 (GPL-2.0), in the spirit of Gentoo and open source gaming.
📖 Resources

    Gentoo Custom Repository Guide

    Gentoo Overlays for Gaming

    Original Blog Tutorial (unixbhaskar)

🎲 Happy gaming on Gentoo! Level up your Linux gaming setup, one ebuild at a time!
