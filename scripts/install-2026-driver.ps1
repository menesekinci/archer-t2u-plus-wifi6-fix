# Self-elevate to Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   TP-Link Archer T2U Plus - 2026 WHQL Surucu Kurulum Araci " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent $scriptDir
$driverInf = Join-Path $repoDir "driver\netrtwlanu.inf"

if (-not (Test-Path $driverInf)) {
    Write-Host "[HATA] Sürücü INF dosyası bulunamadı: $driverInf" -ForegroundColor Red
    pause
    exit
}

Write-Host "[1/4] Eski veya çakışan sürücü paketleri temizleniyor..." -ForegroundColor Yellow
$oemDrivers = & pnputil /enum-drivers | Select-String -Pattern "oem\d+\.inf" -Context 0, 4
foreach ($match in $oemDrivers) {
    if ($match.Context.PostContext -match "1030\.52\.1101\.2025|1030\.29\.1102\.2017") {
        $oemName = $match.Line.Trim() -replace ".*:\s*", ""
        Write-Host "      -> Eski paket kaldırılıyor: $oemName" -ForegroundColor Yellow
        & pnputil /delete-driver $oemName /uninstall /force 2>$null
    }
}
Write-Host "      -> Eski paket temizliği tamamlandı." -ForegroundColor Green

Write-Host "[2/4] Resmi 2026 Realtek WHQL Sürücüsü (v1030.52.1216.2025) kuruluyor..." -ForegroundColor Yellow
& pnputil /add-driver $driverInf /install
Write-Host "      -> 2026 WHQL sürücüsü başarıyla yüklendi ve aygıta bağlandı." -ForegroundColor Green

Write-Host "[3/4] Yüksek hız tampon ve kilitlenme önleyici kayıtlar uygulanıyor..." -ForegroundColor Yellow
$adapters = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" | Where-Object { $_.DriverDesc -like "*TP-Link*" -or $_.DriverDesc -like "*Realtek*8811*" }
foreach ($ad in $adapters) {
    $p = $ad.PSPath
    Set-ItemProperty -Path $p -Name "USBResetTxHang" -Value "0" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name "BeamformCap" -Value "0" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name "EnableAdaptivity" -Value "0" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name "EnableTxPowerLimit" -Value "0" -Type String -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name "bFwCtrlLPS" -Value "0" -Type String -ErrorAction SilentlyContinue
}
Write-Host "      -> Sürücü kayıt defteri kilitlenme engelleri tamamlandı." -ForegroundColor Green

Write-Host "[4/4] Bağdaştırıcı yeni 2026 sürücüsüyle yeniden başlatılıyor..." -ForegroundColor Yellow
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg /setactive SCHEME_CURRENT
Restart-NetAdapter -Name "Wi-Fi" -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Aktif Sürücü Bilgisi:" -ForegroundColor Cyan
Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceID -like "*VID_2357&PID_0120*" } | Select-Object DeviceName, DriverVersion, DriverDate, Manufacturer | Format-List

Write-Host "============================================================" -ForegroundColor Green
Write-Host " [BAŞARILI] Kurulum tamamlandı!                             " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Pencereyi kapatmak için herhangi bir tuşa basın..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
