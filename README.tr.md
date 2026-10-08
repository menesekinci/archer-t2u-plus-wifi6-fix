# TP-Link Archer T2U Plus (Realtek RTL8811AU) - Wi-Fi 5 GHz Kopma ve Yüksek Hızda Kilitlenme Çözüm Rehberi

<p align="center">
  <img src="assets/story.jpg" alt="Wi-Fi Dönüşüm Hikayesi" width="600" />
</p>

Bu depo; **TP-Link Archer T2U Plus** USB Wi-Fi adaptörünün modern Wi-Fi 6 router'lar ile 5 GHz bandında çalışırken yaşadığı periyodik kopma, yüksek bant genişliğinde (150+ Mbps) donma ve soket zaman aşımı sorunlarının **kesin ve doğrulanmış çözümünü** içerir.

---

## 📌 Donanım ve Sistem Bilgileri

* **Ağ Bağdaştırıcısı**: TP-Link Archer T2U Plus (AC600 High Gain Wireless Dual Band USB Adapter)
* **Yonga Seti (Chipset)**: Realtek RTL8811AU Wireless LAN 802.11ac USB 2.0
* **Donanım Kimliği (Hardware ID)**: `USB\VID_2357&PID_0120`
* **Modem / Router**: ZTE ZXHN H3601P V9.0 (Wi-Fi 6 AX3000 / TurkNet Fiber)
* **Anakart & İşlemci**: Gigabyte B550 GAMING X / AMD Ryzen 5 5600X
* **İşletim Sistemi**: Windows 10 / Windows 11 x64

---

## ❌ Çözüm Öncesi Yaşanan Sorunlar

1. **Yüksek Veri Akışında Kilitlenme ve Soket Hatası**:
   * Hız testi (Speedtest) veya yüksek boyutlu dosya indirme sırasında bant genişliği **150–170 Mbps** seviyesine ulaştığında adaptör aniden yanıt vermeyi kesmekteydi.
   * Windows Olay Günlüğünde sürücünün tam **12.4 saniye boyunca kilitlendiği** (`Microsoft-Windows-Kernel-PnP/Driver Watchdog Event 902/903: Service RtlWlanu, Total run time: 12375 ms`) ve ardından Speedtest'in `A socket error occurred during the download test` hatası vererek bağlantıyı düşürdüğü tespit edildi.
2. **Aralıklı 5 GHz Kopmaları**:
   * Modem periyodik olarak dinamik anahtar yenilemesi (GTK Rekey) yaptığında sürücünün zaman aşımına uğraması (`Event 11006: 0x48005`) ve oturumu kapatması (`WLAN-AutoConfig Event 8003: ReasonCode 0`).
3. **Modem Radar (DFS) Sıçraması**:
   * Modemin 5 GHz kanalının dinamik Kanal 60 (DFS) üzerinde çalışması nedeniyle çevrede radar taraması algılandığında frekans sıçraması yaparak bağlantıyı düşürmesi.
4. **Güç Tasarrufu ve Düşük Güç Durumu (LPS)**:
   * Sürücünün `bFwCtrlLPS = 1` parametresi ve Windows USB Seçmeli Askıya Alma özelliği nedeniyle boşta kalan adaptörün uykuya geçmesi ve modem kontrol çerçevelerini kaçırması.
5. **Sanal Ağ (Hamachi) DNS Gecikmeleri**:
   * LogMeIn Hamachi'nin geçersiz IPv6 site-local DNS adresleri tanımlaması nedeniyle ağ bağlantısı yenilendiğinde Windows DNS çözümlemesinin dakikalarca kilitlenmesi.

---

## ✅ Uygulanan Kesin Çözüm Adımları

### 1. Resmi 2026 Microsoft WHQL Sürücüsünün Yüklenmesi (En Kritik Adım)
* **Kök Neden**: TP-Link'in web sitesinde dağıtılan sürücü paketi dosya tarihi olarak 2025 damgası taşısa da içerisindeki asıl ikili (`rtwlanu.sys`) Kasım 2017 derlemesidir. Bu eski derleme, yüksek hızlı veri akışında NDIS tampon bellek taşması yaşamakta ve 12 saniye kilitlenmektedir.
* **Müdahale**:
  * Sahte 2025 etiketli paket Windows'tan tamamen silindi:
    ```cmd
    pnputil /delete-driver oem49.inf /uninstall /force
    ```
  * Microsoft Update Catalog resmi sunucularından temin edilen **22 Ocak 2026** tarihli gerçek **Realtek RTL8811AU WHQL Sürücüsü (v1030.52.1216.2025)** sisteme yüklendi.

### 2. Sürücü ve Kayıt Defteri Kararlılık Parametreleri
Sürücünün yüksek yük altında bağlantıyı zorla sıfırlamasını engellemek için şu parametreler uygulandı:
* `USBResetTxHang` = `0` (Kuyruk gecikmesinde agresif USB sıfırlamasını kapatır).
* `BeamformCap` = `0` (Wi-Fi 6 router'ların gönderdiği sounding hüzmeleme çerçevelerinden kaynaklı kilitlenmeyi önler).
* `EnableAdaptivity` = `0` (İletim duraklamalarını engeller).
* `EnableTxPowerLimit` = `0` (RF çıkış gücünü maksimumda tutar).
* `bFwCtrlLPS` = `0` (Düşük güç uyku modunu devre dışı bırakır).

### 3. Modem / Router Optimizasyonu (ZTE ZXHN H3601P)
Modem yönetim arayüzünden (`http://192.168.1.1`):
* **5 GHz Kanalı**: Radar frekanslarından etkilenmeyen standart **Kanal 36**'ya (veya 40, 44, 48) sabitlendi (`AutoChannelEnabled: 0`).
* **Kablosuz Modu**: **Karışık (802.11a/n/ac)** olarak ayarlandı.
* **Güvenlik & Şifreleme**: **WPA2-PSK-AES** seçildi (PMF / WPA3 çerçeve uyumsuzlukları devre dışı bırakıldı).

### 4. Fiziksel Konum ve USB Portu
* Adaptör, kasanın arkasındaki metal perdeleme ve ekran kartı DisplayPort kablolarından yayılan yüksek frekanslı RF gürültüsünden uzaklaştırılarak ön USB portuna taşındı ve anteni doğrudan modeme yönlendirildi (Sinyal seviyesi **%100**'e ulaştı).

### 5. DNS Çakışmasının Giderilmesi
* Hamachi servisi ve bağdaştırıcısı devre dışı bırakılarak geçersiz IPv6 DNS zaman aşımları ortadan kaldırıldı.

---

## 📊 Çözüm Öncesi vs. Çözüm Sonrası Performans Tablosu

| Metrik / Test | Çözüm Öncesi | Çözüm Sonrası |
| :--- | :--- | :--- |
| **Sürücü Sürümü** | v1030.29.1102.2017 (2017 Çekirdeği) | **v1030.52.1216.2025 (22 Ocak 2026 WHQL)** ✅ |
| **Speedtest İndirme (Download)** | 168 Mbps'de Donup Çöküyordu | **238.24 Mbps (Kesintisiz & Akıcı)** ✅ |
| **Speedtest Yükleme (Upload)** | Dalgalı / Kopmalı | **250.24 Mbps (Tam Kapasite)** ✅ |
| **Gecikme (Ping)** | Paket kayıpları & 20+ ms | **5 ms (0% Kayıp)** ✅ |
| **Yerel Ağ (Gateway) Gecikmesi** | Dalgalı (10-30 ms) | **1 ms Ortalama (50/50 Paket Başarılı)** ✅ |
| **Büyük Paket (1400 Byte MTU)** | Zaman aşımları | **4 ms Ortalama (50/50 Paket Başarılı)** ✅ |
| **100 MB Sürekli Dosya İndirme** | Soket Hatası (Socket Error) | **14.3 Saniyede 104 MB (Tam Akış)** ✅ |
| **Kernel Watchdog Kilitlenmesi** | 12.4 Saniye Felç (`Event 902/903`) | **SIFIR (0 ms Gecikme)** ✅ |
| **WLAN Sürücü Düşmesi (`Event 8003`)**| Günde 5-10 kez | **SIFIR (0 Kopma)** ✅ |

---

## 🚀 1-Tık Kurulum ve Kullanım

Bu depodaki çözümü kendi bilgisayarınızda tek adımda uygulamak için:

1. Bu depoyu indirin veya klonlayın.
2. `scripts/` klasöründeki **`install-2026-driver.bat`** dosyasına sağ tıklayıp **Yönetici olarak çalıştır**'a tıklayın.
3. Script otomatik olarak eski paketleri temizleyecek, `driver/` dizinindeki 2026 resmi WHQL sürücüsünü kuracak ve kayıt defteri parametrelerini uygulayacaktır.
4. Ağ stabilitesini test etmek için `scripts/benchmark-stability.ps1` dosyasını çalıştırabilirsiniz.
