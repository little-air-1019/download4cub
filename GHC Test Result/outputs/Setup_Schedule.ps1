#Requires -RunAsAdministrator
<#
.SYNOPSIS
    建立 Windows 工作排程，於 2026/04/17 每 30 分鐘執行一次驗測
.DESCRIPTION
    時段：14:00, 14:30, 15:00, 15:30, 16:00, 16:30, 17:00, 17:30（共 8 次）
    請以「系統管理員」身分執行此腳本。
#>

$TaskName   = "LoanAPI_驗測批次"
$TaskDesc   = "客戶貸款資格API驗測 - 每30分鐘自動執行"
$ScriptDir  = "D:\DEVTOOLS\Projects\DevDept\GHC 使用能力快篩\驗測"
$BatPath    = Join-Path $ScriptDir "Run_Test.bat"

# 定義 8 個觸發時間點
$times = @(
    "2026-04-17 14:00:00",
    "2026-04-17 14:30:00",
    "2026-04-17 15:00:00",
    "2026-04-17 15:30:00",
    "2026-04-17 16:00:00",
    "2026-04-17 16:30:00",
    "2026-04-17 17:00:00",
    "2026-04-17 17:30:00"
)

# 建立觸發器陣列
$triggers = @()
foreach ($t in $times) {
    $triggers += New-ScheduledTaskTrigger -Once -At $t
}

# 建立動作：執行 bat 檔
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$BatPath`"" -WorkingDirectory $ScriptDir

# 設定：允許電池模式、不要在閒置時停止
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

# 移除舊排程（若存在）
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

# 註冊新排程
Register-ScheduledTask `
    -TaskName $TaskName `
    -Description $TaskDesc `
    -Trigger $triggers `
    -Action $action `
    -Settings $settings `
    -Force

Write-Host ""
Write-Host "排程建立成功！" -ForegroundColor Green
Write-Host "工作名稱：$TaskName" -ForegroundColor Cyan
Write-Host "執行時間：" -ForegroundColor Cyan
foreach ($t in $times) {
    Write-Host "  - $t"
}
Write-Host ""
Write-Host "可在「工作排程器」(taskschd.msc) 中確認。" -ForegroundColor Yellow
Write-Host "若需手動執行一次測試：直接雙擊 Run_Test.bat" -ForegroundColor Yellow
