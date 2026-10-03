# luci-theme-ariang

An **AriaNg-inspired, high-density, structured LuCI theme** for OpenWrt & ImmortalWrt.

Designed specifically for **power users & homelab engineers** who want **100% parameter access** without the chaotic, nested, multi-tab fragmentation of traditional LuCI.

---

## 🌟 Key Features

1. **AriaNg High-Density Key-Value Grid**
   - Clean tabular alignment: Parameter labels on the left, inputs and controls on the right.
   - Fixed-width labels and monospace fonts for network addresses (`IP`, `Netmask`, `Gateway`, `MAC`, `CIDR`, `Ports`).
   - Zero distracting backgrounds or bloated animations; 100% focused on engineering clarity.

2. **⚡ Instant Parameter Filter (Quick Search)**
   - Top-anchored instant search bar on all configuration pages.
   - Type any keyword (e.g., `gateway`, `ip`, `nat`, `bbr`, `dns`, `masquerade`) to instantly filter matching parameters in real time.
   - Shortcut: Press <kbd>Cmd</kbd> + <kbd>K</kbd> (or <kbd>Ctrl</kbd> + <kbd>K</kbd>) to focus search immediately.

3. **📜 "Flatten Tabs" Mode**
   - Tired of clicking through 5 nested tabs (`General Setup`, `Advanced Settings`, `Physical Settings`, `Firewall Settings`, `DHCP Server`) to find one parameter?
   - Click **"📜 Flatten Tabs"** to unroll all hidden tab contents into a single, scrollable document with section anchors.

4. **📋 One-Click Copy for Network Values**
   - Hover and click 📋 next to any IP address or MAC address to copy it to clipboard.

---

## 🚀 Installation on NanoPi R5C / OpenWrt

### Method 1: Using the Pre-built `.ipk` (Recommended)

1. Download the latest `.ipk` from GitHub Releases / Artifacts, or scp from your local machine:
   ```bash
   scp bin/luci-theme-ariang_1.0.0-1_all.ipk root@10.0.0.2:/tmp/
   ```

2. SSH into your R5C and install:
   ```bash
   ssh root@10.0.0.2
   opkg install /tmp/luci-theme-ariang_1.0.0-1_all.ipk
   ```

3. In LuCI WebUI:
   - Navigate to **System -> System -> Language and Style** (系统 -> 系统属性 -> 语言和界面).
   - Under **Theme** (主题), select **AriaNg**.
   - Click **Save & Apply** (保存并应用).

---

### Method 2: Live Hot-Reload Debugging (For Direct Tweaking)

Because LuCI themes are pure HTML/CSS/JS, you can sync files directly to your running router to see changes instantly:

```bash
# Push CSS and JS directly to router
scp -r htdocs/luci-static/ariang/* root@10.0.0.2:/www/luci-static/ariang/
```
Refresh your browser with <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> to see the immediate effect!

---

## 🛠 Building the `.ipk` Locally

```bash
chmod +x scripts/build-ipk.sh
./scripts/build-ipk.sh
# Output will be located in bin/luci-theme-ariang_1.0.0-1_all.ipk
```

---

## 📄 License
Apache License 2.0 - Copyright (C) 2026 gcxixi
