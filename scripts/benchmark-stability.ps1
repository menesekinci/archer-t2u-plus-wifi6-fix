Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       Wi-Fi Kararlilik ve Gecikme Benchmark Testi          " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Yerel Ag ve Modem Gecikmesi Olculuyor (192.168.1.1)..." -ForegroundColor Yellow
$localPing = ping -n 20 192.168.1.1
$localPing | Select-String "Minimum"

Write-Host ""
Write-Host "[2/3] Buyuk Paket (1400 Byte MTU) Genis Bant Testi (1.1.1.1)..." -ForegroundColor Yellow
$cloudPing = ping -n 20 -l 1400 1.1.1.1
$cloudPing | Select-String "Minimum"

Write-Host ""
Write-Host "[3/3] DNS Cozumleme Sureleri Olculuyor..." -ForegroundColor Yellow
$domains = @("google.com", "cloudflare.com", "youtube.com", "github.com")
foreach ($d in $domains) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $ip = [System.Net.Dns]::GetHostAddresses($d)[0].IPAddressToString
        $sw.Stop()
        Write-Host "      -> $d : $($sw.ElapsedMilliseconds) ms ($ip)" -ForegroundColor Green
    } catch {
        Write-Host "      -> $d : BASARISIZ" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Aktif Baglanti Ozeti:" -ForegroundColor Cyan
netsh wlan show interfaces | Select-String -Pattern "SSID|Radio type|Channel|Receive rate|Signal"
Write-Host ""
Write-Host "Test tamamlandi. Pencereyi kapatmak icin herhangi bir tusa basin..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
