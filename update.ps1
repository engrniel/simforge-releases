# SimForge installer / updater for Windows.
#
# Students run ONE line in PowerShell (no admin rights needed):
#
#   irm https://raw.githubusercontent.com/engrniel/simforge-releases/main/update.ps1 | iex
#
# It installs SimForge on first run and updates it on every later run:
#   1. reads the latest version from the public simforge-releases repo,
#   2. stops if that version is already installed,
#   3. closes SimForge, downloads the portable build, replaces the files in
#      %LOCALAPPDATA%\Programs\SimForge, and refreshes the Desktop and Start
#      Menu shortcuts.
#
# Downloads use github.com/<repo>/releases/latest/download/<file>, NOT the
# GitHub API: the API allows 60 calls an hour per IP, and a whole classroom
# shares one IP.
#
# Everything sits inside one script block, so `irm | iex` leaves no variables
# behind and an error never closes the student's PowerShell window.

& {
    $ErrorActionPreference = "Stop"
    $ProgressPreference = "SilentlyContinue"   # the progress bar makes downloads 10x slower in PS 5.1
    # Windows PowerShell 5.1 still defaults to TLS 1.0, which GitHub refuses.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $Repo   = "engrniel/simforge-releases"
    $Base   = "https://github.com/$Repo/releases/latest/download"
    $Dir    = Join-Path $env:LOCALAPPDATA "Programs\SimForge"
    $Stamp  = Join-Path $Dir "version.txt"

    Write-Host ""
    Write-Host "SimForge updater" -ForegroundColor Cyan

    try {
        $latest = (Invoke-WebRequest "$Base/version.txt" -UseBasicParsing).Content
        if ($latest -is [byte[]]) { $latest = [Text.Encoding]::UTF8.GetString($latest) }
        $latest = $latest.Trim()
    } catch {
        Write-Host "Could not reach GitHub. Check your internet connection and try again." -ForegroundColor Red
        Write-Host "  ($($_.Exception.Message))"
        return
    }

    $current = if (Test-Path $Stamp) { (Get-Content $Stamp -Raw).Trim() } else { "" }
    $exe = Join-Path $Dir "SimForge.exe"
    if ($current -eq $latest -and (Test-Path $exe) -and -not $env:SIMFORGE_FORCE) {
        Write-Host "SimForge $current is already the latest version." -ForegroundColor Green
        return
    }
    if ($current) { Write-Host "Updating SimForge $current -> $latest" }
    else          { Write-Host "Installing SimForge $latest" }

    $tmp = Join-Path $env:TEMP ("simforge-update-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    try {
        $zip = Join-Path $tmp "SimForge.zip"
        Write-Host "  downloading..."
        Invoke-WebRequest "$Base/SimForge-win-x64.zip" -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath $tmp -Force
        # the zip holds one folder, SimForge-<version>-win-x64
        $src = Get-ChildItem $tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SimForge.exe") } | Select-Object -First 1
        if (-not $src) { throw "the download did not contain SimForge.exe" }

        # Close a running SimForge first, or Windows will not let us replace the .exe.
        $running = Get-Process -Name "SimForge" -ErrorAction SilentlyContinue
        if ($running) {
            Write-Host "  closing SimForge (save your work first next time)..."
            $running | Stop-Process -Force
            Start-Sleep -Seconds 2
        }

        New-Item -ItemType Directory -Path $Dir -Force | Out-Null
        Copy-Item -Path (Join-Path $src.FullName "*") -Destination $Dir -Recurse -Force
        # Files from the internet carry a "downloaded" mark that makes Windows
        # warn on every launch; the student chose to install, so clear it.
        Get-ChildItem $Dir -Recurse -File | Unblock-File
        Set-Content -Path $Stamp -Value $latest -Encoding ASCII
    } catch {
        Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Your previous SimForge (if any) was not removed."
        return
    } finally {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Desktop + Start Menu shortcuts
    $shell = New-Object -ComObject WScript.Shell
    $places = @(
        [Environment]::GetFolderPath("Desktop"),
        (Join-Path ([Environment]::GetFolderPath("StartMenu")) "Programs")
    )
    foreach ($place in $places) {
        if (-not $place -or -not (Test-Path $place)) { continue }
        $lnk = $shell.CreateShortcut((Join-Path $place "SimForge.lnk"))
        $lnk.TargetPath = $exe
        $lnk.WorkingDirectory = $Dir
        $lnk.IconLocation = "$exe,0"
        $lnk.Description = "SimForge - MATLAB IDE for the classroom"
        $lnk.Save()
    }

    Write-Host ""
    Write-Host "SimForge $latest is installed in $Dir" -ForegroundColor Green
    Write-Host "Open it from the Desktop or Start Menu shortcut."

    # SimForge runs its engine on Python 3.9+. Warn now instead of at first Run.
    $py = $false
    foreach ($cmd in @(@("python", "-c", "import sys; sys.exit(sys.version_info < (3, 9))"),
                       @("py", "-3", "-c", "import sys; sys.exit(sys.version_info < (3, 9))"))) {
        try {
            & $cmd[0] $cmd[1..($cmd.Length - 1)] 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $py = $true; break }
        } catch { }
    }
    if (-not $py) {
        Write-Host ""
        Write-Host "Python 3.9 or newer was not found. SimForge needs it to run code:" -ForegroundColor Yellow
        Write-Host "  install it from https://www.python.org/downloads/ and tick 'Add python.exe to PATH'."
    }
}
