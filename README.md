# TP-Link Archer T2U Plus (Realtek RTL8811AU) - Complete Wi-Fi 5 GHz Fix Guide

<p align="center">
  <img src="assets/story.jpg" alt="Wi-Fi Transformation Story" width="600" />
</p>

Official repository for resolving intermittent disconnects, high-throughput socket crashes (150+ Mbps), and driver watchdog stalls on the **TP-Link Archer T2U Plus** USB Wi-Fi adapter when connected to modern Wi-Fi 6 routers.

---

## 📌 Hardware & System Specifications

* **Wireless Adapter**: TP-Link Archer T2U Plus (AC600 High Gain Wireless Dual Band USB Adapter)
* **Chipset**: Realtek RTL8811AU Wireless LAN 802.11ac USB 2.0
* **Hardware ID**: `USB\VID_2357&PID_0120`
* **Router / Gateway**: ZTE ZXHN H3601P V9.0 (Wi-Fi 6 AX3000 / TurkNet Fiber)
* **Motherboard & CPU**: Gigabyte B550 GAMING X / AMD Ryzen 5 5600X
* **Operating System**: Windows 10 / Windows 11 x64

---

## ❌ Symptoms & Issues Identified (Pre-Fix)

1. **High-Throughput Driver Stall & Socket Error**:
   * During heavy downloads or Speedtests hitting **150–170 Mbps**, the adapter abruptly stalled.
   * Windows Kernel Event Log recorded a **12.4-second driver freeze**:  
     `Microsoft-Windows-Kernel-PnP/Driver Watchdog (Event 902/903): Service RtlWlanu, Total run time: 12375 ms`
   * Following the freeze, TCP connections died with `A socket error occurred during the download test` and the connection was dropped.
2. **Periodic 5 GHz Drops**:
   * Dynamic WPA2 key re-exchanges (GTK Rekey) timed out (`Event 11006: 0x48005`), causing session terminations (`WLAN-AutoConfig Event 8003: ReasonCode 0`).
3. **Router Dynamic DFS Frequency Hopping**:
   * Default dynamic 5 GHz Channel 60 triggered radar detection frequency hopping, kicking clients offline.
4. **Power Management & Low Power Sleep (LPS)**:
   * Aggressive driver power saving (`bFwCtrlLPS = 1`) and Windows USB Selective Suspend caused idle packet dropouts.
5. **Virtual Adapter (Hamachi) DNS Timeout Cascades**:
   * Stale IPv6 site-local DNS addresses from Hamachi delayed DNS lookups across multi-homed interfaces.

---

## ✅ Verified Solution Steps

### 1. Installation of the Genuine 2026 Microsoft WHQL Driver (Critical)
* **Root Cause**: The driver distributed on vendor websites, despite being stamped with fake 2025 dates in the `.inf`, contains a legacy November 2017 binary (`rtwlanu.sys v1030.29.1102.2017`). This older driver suffers from internal buffer deadlocks under modern NDIS high-throughput transfers.
* **Fix**:
  * The legacy OEM package was purged:
    ```cmd
    pnputil /delete-driver oem49.inf /uninstall /force
    ```
  * The official **January 22, 2026** Realtek RTL8811AU WHQL driver (**v1030.52.1216.2025**) sourced directly from the Microsoft Update Catalog was installed.

### 2. Registry & Driver Stability Tuning
Applied directly to the adapter device class key:
* `USBResetTxHang` = `0` (Disables aggressive bus resets on queue delays).
* `BeamformCap` = `0` (Prevents crashes from Wi-Fi 6 router sounding frames).
* `EnableAdaptivity` = `0` (Eliminates transmission pauses).
* `EnableTxPowerLimit` = `0` (Maintains full RF output power).
* `bFwCtrlLPS` = `0` (Disables low-power state sleep).

### 3. Router Configuration (ZTE ZXHN H3601P)
Configured via web management interface (`http://192.168.1.1`):
* **5 GHz Channel**: Fixed to non-DFS **Channel 36** (`AutoChannelEnabled: 0`).
* **Wireless Mode**: **Mixed (802.11a/n/ac)**.
* **Security & Cipher**: **WPA2-PSK-AES** (Disables PMF / WPA3 frame conflicts).

### 4. Physical Optimization
* Moved adapter from the rear I/O shield (which caused RF attenuation from metal casing and DP cable noise) to a front USB port with antenna oriented towards the router, achieving **100% signal strength**.

### 5. DNS Hygiene
* Disabled Hamachi tunneling engine and virtual adapter to prevent IPv6 DNS timeout cascades.

---

## 📊 Pre-Fix vs. Post-Fix Performance Benchmarks

| Metric / Test | Before Fix | After Fix |
| :--- | :--- | :--- |
| **Driver Version** | v1030.29.1102.2017 (2017 Binary) | **v1030.52.1216.2025 (Jan 22, 2026 WHQL)** ✅ |
| **Speedtest Download** | Froze & Dropped at 168 Mbps | **238.24 Mbps (Smooth & Sustained)** ✅ |
| **Speedtest Upload** | Unstable / Dropping | **250.24 Mbps (Full Capacity)** ✅ |
| **Latency (Ping)** | Packet loss, 20+ ms spikes | **5 ms (0% Loss)** ✅ |
| **Local Gateway Latency** | Inconsistent (10-30 ms) | **1 ms Average (50/50 Packets)** ✅ |
| **Heavy MTU (1400 Byte)** | Timeouts | **4 ms Average (50/50 Packets, 0% Loss)** ✅ |
| **100 MB Continuous Stream** | Socket Error | **14.3 Seconds for 104 MB (HTTP 200)** ✅ |
| **Driver Watchdog Stalls** | 12.4 Second Freeze (`Event 902/903`) | **ZERO (0 ms Stall)** ✅ |
| **WLAN Disconnects (`Event 8003`)**| 5–10 times per day | **ZERO (0 Disconnects)** ✅ |

---

## 🚀 1-Click Installation & Usage

To apply this complete fix on any Windows machine:

1. Clone or download this repository.
2. Right-click **`scripts/install-2026-driver.bat`** and select **Run as administrator**.
3. The script automatically removes broken OEM packages, installs the included 2026 WHQL driver from `driver/`, and applies all registry optimizations.
4. Run `scripts/benchmark-stability.ps1` to verify latency and packet stability.
