#Requires -Version 5.1
<#
.SYNOPSIS
    客戶貸款資格 API 驗測批次腳本
.DESCRIPTION
    每次執行時，對所有尚未通過的同仁發送 P（個人貸款）與 C（企業貸款）兩個測試情境，
    比對回應 TRANRS 區塊。兩情境皆正確才算通過，已通過者不會被覆寫。
    結果輸出至 Excel（需 ImportExcel 模組，若無則自動降級為 CSV）。
.NOTES
    Author : Claude AI
    Date   : 2026-04-16
#>

[CmdletBinding()]
param(
    [string]$InputDir  = "D:\DEVTOOLS\Projects\DevDept\GHC 使用能力快篩\驗測\讀取資料",
    [string]$OutputDir = "D:\DEVTOOLS\Projects\DevDept\GHC 使用能力快篩\驗測\驗測結果"
)

# ============================================================
#  基本設定
# ============================================================
$ApiPath    = "/api/loan/queryLoanEligibilit"
$Port       = 8080
$TimeoutSec = 15
$BatchLabel = (Get-Date).ToString("HH:mm")
$RunDate    = (Get-Date).ToString("yyyy-MM-dd")

# 檔案路徑
$ContestantsFile = Join-Path $InputDir "Contestants.csv"
$RequestPFile    = Join-Path $InputDir "request_P.json"
$RequestCFile    = Join-Path $InputDir "request_C.json"
$ResponsePFile   = Join-Path $InputDir "response_P.json"
$ResponseCFile   = Join-Path $InputDir "response_C.json"
$StateFile       = Join-Path $OutputDir "result_state.json"
$ExcelFile       = Join-Path $OutputDir "驗測結果.xlsx"
$LogFile         = Join-Path $OutputDir "test_log_$RunDate.txt"

# ============================================================
#  工具函式：將物件轉為排序後的標準化 JSON 字串（用於比對）
# ============================================================
function ConvertTo-CanonicalJson {
    param($Obj)

    # null
    if ($null -eq $Obj) { return "null" }

    # 陣列（含空陣列）
    if ($Obj -is [System.Object[]] -or $Obj -is [System.Collections.ArrayList]) {
        if ($Obj.Count -eq 0) { return "[]" }
        $items = @()
        foreach ($item in $Obj) {
            $items += (ConvertTo-CanonicalJson $item)
        }
        return "[" + ($items -join ",") + "]"
    }

    # PSCustomObject（JSON 物件）
    if ($Obj -is [PSCustomObject]) {
        $sortedProps = $Obj.PSObject.Properties | Sort-Object Name
        $pairs = @()
        foreach ($prop in $sortedProps) {
            $escapedKey = $prop.Name -replace '\\', '\\' -replace '"', '\"'
            $val = ConvertTo-CanonicalJson $prop.Value
            $pairs += ('"' + $escapedKey + '":' + $val)
        }
        return "{" + ($pairs -join ",") + "}"
    }

    # 布林
    if ($Obj -is [bool]) {
        if ($Obj) { return "true" } else { return "false" }
    }

    # 數值（int / long / double）
    if ($Obj -is [int] -or $Obj -is [long] -or $Obj -is [double] -or $Obj -is [decimal]) {
        return [string]$Obj
    }

    # 字串
    $str = [string]$Obj
    $str = $str -replace '\\', '\\' -replace '"', '\"' -replace "`r", '' -replace "`n", '\n' -replace "`t", '\t'
    return '"' + $str + '"'
}

# ============================================================
#  工具函式：測試單一情境
# ============================================================
function Test-SingleScenario {
    param(
        [string]$IP,
        [string]$RequestBody,
        [string]$ExpectedCanonical,
        [string]$ScenarioName
    )

    $url = "http://${IP}:${Port}${ApiPath}"

    try {
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($RequestBody)
        $resp = Invoke-WebRequest -Uri $url -Method POST `
            -Body $bodyBytes `
            -ContentType "application/json; charset=utf-8" `
            -TimeoutSec $TimeoutSec -UseBasicParsing

        $body = $resp.Content | ConvertFrom-Json
        $actualTRANRS = $body.TRANRS

        if ($null -eq $actualTRANRS) {
            return @{ Pass = $false; Code = "WRONG"; Detail = "${ScenarioName}：回應缺少 TRANRS" }
        }

        $actualCanonical = ConvertTo-CanonicalJson $actualTRANRS

        if ($actualCanonical -eq $ExpectedCanonical) {
            return @{ Pass = $true; Code = "PASS"; Detail = "" }
        }
        else {
            return @{ Pass = $false; Code = "WRONG"; Detail = "${ScenarioName}：TRANRS 內容不符" }
        }
    }
    catch [System.Net.WebException] {
        return @{ Pass = $false; Code = "UNREACHABLE"; Detail = "${ScenarioName}：$($_.Exception.Message)" }
    }
    catch {
        return @{ Pass = $false; Code = "ERROR"; Detail = "${ScenarioName}：$($_.Exception.Message)" }
    }
}

# ============================================================
#  主程式
# ============================================================

# 確保輸出資料夾存在
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Log 標頭
$logHeader = "`n===== [$RunDate $BatchLabel] 開始執行驗測 ====="
Add-Content -Path $LogFile -Value $logHeader -Encoding UTF8
Write-Host $logHeader -ForegroundColor Cyan

# 讀取同仁名單
if (-not (Test-Path $ContestantsFile)) {
    Write-Host "錯誤：找不到同仁名單 $ContestantsFile" -ForegroundColor Red
    exit 1
}
$contestants = Import-Csv $ContestantsFile -Encoding UTF8

# 讀取測試資料並預先計算標準化 JSON
$reqPBody = Get-Content $RequestPFile -Raw -Encoding UTF8
$reqCBody = Get-Content $RequestCFile -Raw -Encoding UTF8

$expectedP_TRANRS = (Get-Content $ResponsePFile -Raw -Encoding UTF8 | ConvertFrom-Json).TRANRS
$expectedC_TRANRS = (Get-Content $ResponseCFile -Raw -Encoding UTF8 | ConvertFrom-Json).TRANRS

$canonicalP = ConvertTo-CanonicalJson $expectedP_TRANRS
$canonicalC = ConvertTo-CanonicalJson $expectedC_TRANRS

Write-Host "預期 P 情境 Canonical 長度: $($canonicalP.Length)" -ForegroundColor DarkGray
Write-Host "預期 C 情境 Canonical 長度: $($canonicalC.Length)" -ForegroundColor DarkGray

# 載入持久化狀態（已通過者紀錄）
$state = @{}
if (Test-Path $StateFile) {
    try {
        $raw = Get-Content $StateFile -Raw -Encoding UTF8
        $stateArray = $raw | ConvertFrom-Json
        # 處理單筆時 PS 5.1 不回傳陣列的問題
        if ($stateArray -isnot [System.Object[]]) {
            $stateArray = @($stateArray)
        }
        foreach ($item in $stateArray) {
            $state[$item.EmpId] = @{
                EmpName  = $item.EmpName
                Result   = $item.Result
                PassTime = $item.PassTime
                Detail   = $item.Detail
            }
        }
    }
    catch {
        Write-Host "警告：狀態檔讀取失敗，將重新建立。$($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# ============================================================
#  逐一測試
# ============================================================
foreach ($c in $contestants) {
    $empId   = $c.'行編'.Trim()
    $empName = $c.'姓名'.Trim()
    $empIP   = $c.'IP'.Trim()

    # ★ 已通過者直接跳過，不再測試
    if ($state.ContainsKey($empId) -and $state[$empId].Result -eq "通過") {
        $skipMsg = "$empId $empName >> 已通過（$($state[$empId].PassTime)），跳過"
        Write-Host $skipMsg -ForegroundColor Green
        Add-Content -Path $LogFile -Value $skipMsg -Encoding UTF8
        continue
    }

    Write-Host "$empId $empName ($empIP) 測試中..." -NoNewline

    # 測試 P 情境（個人貸款）
    $resultP = Test-SingleScenario -IP $empIP -RequestBody $reqPBody `
        -ExpectedCanonical $canonicalP -ScenarioName "P情境"

    # 測試 C 情境（企業貸款）
    $resultC = Test-SingleScenario -IP $empIP -RequestBody $reqCBody `
        -ExpectedCanonical $canonicalC -ScenarioName "C情境"

    # 判定整體結果
    if ($resultP.Pass -and $resultC.Pass) {
        # ✔ 兩個情境都通過
        $state[$empId] = @{
            EmpName  = $empName
            Result   = "通過"
            PassTime = $BatchLabel
            Detail   = ""
        }
        $msg = " >> 通過（$BatchLabel）"
        Write-Host $msg -ForegroundColor Green
    }
    elseif ($resultP.Code -eq "UNREACHABLE" -and $resultC.Code -eq "UNREACHABLE") {
        # ✘ 兩個都連不上 → 尚未打通
        $state[$empId] = @{
            EmpName  = $empName
            Result   = "未通過"
            PassTime = ""
            Detail   = "尚未打通"
        }
        $msg = " >> 未通過（尚未打通）"
        Write-Host $msg -ForegroundColor Red
    }
    else {
        # ✘ 有連上但答案不對（或一邊連上一邊沒連上）
        $failParts = @()
        if (-not $resultP.Pass) { $failParts += $resultP.Detail }
        if (-not $resultC.Pass) { $failParts += $resultC.Detail }
        $detailStr = $failParts -join "；"

        $state[$empId] = @{
            EmpName  = $empName
            Result   = "未通過"
            PassTime = ""
            Detail   = "答案錯誤（$detailStr）"
        }
        $msg = " >> 未通過（答案錯誤）"
        Write-Host $msg -ForegroundColor Yellow
    }

    Add-Content -Path $LogFile -Value "$empId $empName$msg" -Encoding UTF8
}

# ============================================================
#  儲存狀態（JSON 陣列）
# ============================================================
$stateExport = @()
foreach ($key in $state.Keys) {
    $stateExport += [PSCustomObject]@{
        EmpId    = $key
        EmpName  = $state[$key].EmpName
        Result   = $state[$key].Result
        PassTime = $state[$key].PassTime
        Detail   = $state[$key].Detail
    }
}

# 確保輸出為 JSON 陣列（即使只有一筆）
$stateJson = "["
$first = $true
foreach ($item in $stateExport) {
    if (-not $first) { $stateJson += "," }
    $stateJson += ($item | ConvertTo-Json -Depth 5 -Compress)
    $first = $false
}
$stateJson += "]"
[System.IO.File]::WriteAllText($StateFile, $stateJson, [System.Text.Encoding]::UTF8)

# ============================================================
#  產出報表
# ============================================================
$report = @()
foreach ($c in $contestants) {
    $empId = $c.'行編'.Trim()

    if ($state.ContainsKey($empId)) {
        $s = $state[$empId]
        if ($s.Result -eq "通過") {
            $resultText = "通過（$($s.PassTime)）"
        }
        else {
            $resultText = "未通過（$($s.Detail)）"
        }
    }
    else {
        $resultText = "未測試"
    }

    $report += [PSCustomObject]@{
        '行編'     = $empId
        '姓名'     = $c.'姓名'.Trim()
        '驗測結果' = $resultText
    }
}

# 嘗試使用 ImportExcel 匯出 .xlsx
$excelOk = $false
try {
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "首次執行：正在安裝 ImportExcel 模組..." -ForegroundColor Yellow
        Install-Module ImportExcel -Scope CurrentUser -Force -ErrorAction Stop
    }
    Import-Module ImportExcel -ErrorAction Stop

    $report | Export-Excel -Path $ExcelFile `
        -WorksheetName "驗測結果" `
        -AutoSize -FreezeTopRow -BoldTopRow `
        -Force

    $excelOk = $true
    Write-Host "`n Excel 報表已輸出：$ExcelFile" -ForegroundColor Cyan
}
catch {
    Write-Host "`n ImportExcel 模組安裝或使用失敗，改輸出 CSV" -ForegroundColor Yellow
    Write-Host "  錯誤：$($_.Exception.Message)" -ForegroundColor DarkYellow
    Write-Host "  手動安裝方式：Install-Module ImportExcel -Scope CurrentUser" -ForegroundColor DarkYellow

    $csvFile = Join-Path $OutputDir "驗測結果.csv"
    # 以 BOM 寫入 CSV，確保 Excel 開啟時中文不亂碼
    $csvContent = ($report | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
    $bom = [System.Text.Encoding]::UTF8.GetPreamble()
    $bytes = $bom + [System.Text.Encoding]::UTF8.GetBytes($csvContent)
    [System.IO.File]::WriteAllBytes($csvFile, $bytes)
    Write-Host "  CSV 報表已輸出：$csvFile" -ForegroundColor Cyan
}

# 同時輸出一份純文字結果到 console 與 log
Write-Host "`n========== 本批次結果總覽 ==========" -ForegroundColor White
$summaryLines = @("========== [$RunDate $BatchLabel] 結果總覽 ==========")
foreach ($r in $report) {
    $line = "$($r.'行編') $($r.'姓名') >> $($r.'驗測結果')"
    Write-Host $line
    $summaryLines += $line
}
$summaryLines += "====================================="
$summaryLines | ForEach-Object { Add-Content -Path $LogFile -Value $_ -Encoding UTF8 }

$endMsg = "===== [$RunDate $BatchLabel] 驗測完成 ====="
Write-Host $endMsg -ForegroundColor Cyan
Add-Content -Path $LogFile -Value $endMsg -Encoding UTF8
