---
# 🎮 Err0rX Overlay

Welcome to **Err0rX Gaming Overlay**! This personal Gentoo ebuild repository is your go-to for an optimized Linux gaming experience.

---
### ✨ What You'll Find:
* **Tailored Ebuilds:** Updated and customized ebuilds for games, emulators, and essential gaming tools.
* **Upstream Fixes:** Solutions for outdated or unmaintained ebuilds from official repos.
* **Performance Tweaks:** Personal patches and enhancements designed to boost your gaming performance on Gentoo.

---
### 🚀 Purpose:
To centralize and maintain custom ebuilds, ensuring you always have access to the latest and greatest for gaming, with easy version control via Git.

---
### 📚 How to Use:

#### **1️⃣ Recommended (with `eselect-repository`):**
```bash
sudo eselect repository add err0rx-overlay git https://github.com/Err0rXG/err0rx-overlay.git
sudo emaint sync -r err0rx-overlay
```
 #### **2️⃣ Manual Method:**
 ```bash
  git clone https://github.com/Err0rXG/err0rx-overlay.git /var/db/repos/err0rx-overlay
```
   Then, create `/etc/portage/repos.conf/err0rx-overlay.conf`:
```bash
[err0rx-overlay] 
location = /var/db/repos/err0rx-overlay 
masters = gentoo 
auto-sync = true
```

----------

### 📜 License:

This overlay is licensed under **GPL-2.0**.

----------
🎲 Happy gaming on Gentoo! Level up your Linux gaming setup!
