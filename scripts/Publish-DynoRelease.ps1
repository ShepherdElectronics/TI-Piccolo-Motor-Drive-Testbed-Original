$ErrorActionPreference = "Stop"

$repo = "C:\Git\TI-Piccolo-Motor-Drive-Testbed"
$downloads = Join-Path $HOME "Downloads"

$zip = Get-ChildItem $downloads -File |
    Where-Object { $_.Name -like "TI-Piccolo-Dyno-Public-FINAL-v*.zip" } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $zip) { throw "Could not find the release ZIP in $downloads" }
if (-not (Test-Path (Join-Path $repo ".git"))) { throw "Git repository not found at $repo" }

$temp = Join-Path $env:TEMP ("TI-Piccolo-Dyno-" + [guid]::NewGuid())
try {
    New-Item -ItemType Directory -Path $temp | Out-Null
    Expand-Archive -Path $zip.FullName -DestinationPath $temp -Force

    $required = @("README.md", "NOTICE.md", "RELEASE_NOTES.md",
        "embedded-control\custom-firmware\F28069M_ADC_Custom_Config.c",
        "models\simulink\target\C2000_Dual_Motor_CAN_Target.slx", "docs", "hardware", "results")
    foreach ($item in $required) {
        if (-not (Test-Path (Join-Path $temp $item))) { throw "Missing expected item in ZIP: $item" }
    }

    Get-ChildItem $repo -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
    Get-ChildItem $temp -Force | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $repo -Recurse -Force
    }

    Set-Location $repo
    git add -A
    git status --short
    $changes = git status --porcelain
    if ($changes) {
        git commit -m "Publish TI Piccolo dyno public release v1.7"
        git push origin main
    } else {
        Write-Host "No changes detected." -ForegroundColor Yellow
    }
    git status
    git log -1 --oneline
    git remote -v
}
finally {
    if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
}
