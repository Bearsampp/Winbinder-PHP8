param(
    [string]$PhpVersion = "8.3.15",
    [string]$VcVersion = "vs16"
)

$ErrorActionPreference = "Stop"

$archs = @("x64", "x86")
$ts_options = @("1", "0")

$projectRoot = "c:\projects\winbinder"
$buildCache = "c:\build-cache"

foreach ($arch in $archs) {
    foreach ($ts in $ts_options) {
        Write-Host "`n============================================================"
        Write-Host "Building Variant: ARCH=$arch, TS=$ts"
        Write-Host "============================================================`n"

        $ts_part = if ($ts -eq "0") { "-nts" } else { "" }
        $develPackName = "php-devel-pack-$PhpVersion$ts_part-Win32-$VcVersion-$arch.zip"
        $develPackPath = "$buildCache\$develPackName"
        
        $url_releases = "https://windows.php.net/downloads/releases/$develPackName"
        $url_archives = "https://windows.php.net/downloads/releases/archives/$develPackName"

        # 1. Download PHP Development Pack
        if (-not (Test-Path $develPackPath)) {
            Write-Host "Downloading PHP development pack..."
            try {
                Invoke-WebRequest $url_releases -OutFile $develPackPath -UserAgent 'Mozilla/5.0'
            } catch {
                Write-Host "Failed to download from releases, trying archives..."
                Invoke-WebRequest $url_archives -OutFile $develPackPath -UserAgent 'Mozilla/5.0'
            }
        }

        # 2. Extract Devel Pack
        $develDirName = "php-$PhpVersion$ts_part-devel-$VcVersion-$arch"
        $develDirPath = "$buildCache\$develDirName"
        
        # Clean up any potentially conflicting directories first
        $possibleDirNames = @(
            "php-$PhpVersion-devel-$VcVersion-$arch",
            "php-$PhpVersion-nts-devel-$VcVersion-$arch"
        )
        
        foreach ($pDir in $possibleDirNames) {
            $pPath = "$buildCache\$pDir"
            if (Test-Path $pPath) {
                Remove-Item -Recurse -Force $pPath
            }
        }
        
        Write-Host "Extracting $develPackName..."
        & 7z x $develPackPath "-o$buildCache" -y | Out-Null

        # Find which directory was actually extracted
        $foundDir = $null
        foreach ($pDir in $possibleDirNames) {
            $pPath = "$buildCache\$pDir"
            if (Test-Path $pPath) {
                $foundDir = $pPath
                break
            }
        }

        if (-not $foundDir) {
            Write-Host "Extracted directory not found. Checking build cache content..."
            Get-ChildItem $buildCache | ForEach-Object { Write-Host $_.FullName }
            Write-Error "Error: Extracted directory for $develPackName not found."
        }

        Write-Host "Using PHP development pack at: $foundDir"
        $develDirPath = $foundDir
        $phpizePath = Join-Path $develDirPath "phpize.bat"
        if (-not (Test-Path $phpizePath)) {
            Write-Host "phpize.bat not found in $develDirPath. Checking directory content..."
            Get-ChildItem $develDirPath -Recurse | ForEach-Object { Write-Host $_.FullName }
            Write-Error "Error: phpize.bat not found."
        }

        # 3. Prepare Build Environment
        Set-Location $projectRoot
        
        # Explicitly set VS path for PHP SDK
        $env:PHP_SDK_VS16_DIR = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
        $env:PHP_SDK_VC_DIR = "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
        
        # Update PATH
        $oldPath = $env:PATH
        $env:PATH = "$develDirPath\bin;$develDirPath;$oldPath"

        # Create task script
        $taskFile = "$projectRoot\task.bat"
        $conf_cmd = "call configure --with-winbinder=shared --disable-debug 2>&1"
        
        @("cd $projectRoot",
          "set PATH=$develDirPath\bin;$develDirPath;%PATH%",
          "call `"$phpizePath`" 2>&1",
          "if exist configure.bat (call configure.bat --with-winbinder=shared --disable-debug 2>&1) else (echo configure.bat not found & exit 1)",
          "nmake /nologo 2>&1",
          "exit %errorlevel%"
        ) | Out-File -Encoding "ASCII" $taskFile

        # 4. Run Build
        $runner = "$buildCache\php-sdk\phpsdk-$VcVersion-$arch.bat"
        Write-Host "Running build via $runner..."
        & cmd /c "$runner -t $taskFile"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed for ARCH=$arch, TS=$ts with exit code $LASTEXITCODE"
        }

        # 5. Package and Save Artifact
        $ts_label = if ($ts -eq "1") { "ts" } else { "nts" }
        $zipName = "php-winbinder-$PhpVersion-$arch-$ts_label.7z"

        $outputDir = if ($arch -eq "x64") { "$projectRoot\x64" } else { $projectRoot }
        $releaseFolder = if ($ts -eq "1") { "Release_TS" } else { "Release" }
        $outputDir = Join-Path $outputDir $releaseFolder

        $dllPath = Join-Path $outputDir "php_winbinder.dll"

        if (Test-Path $dllPath) {
            Write-Host "DLL found at $dllPath. Creating archive $zipName..."
            & 7z a "$buildCache\$zipName" $dllPath -t7z | Out-Null
            Push-AppveyorArtifact "$buildCache\$zipName"
        } else {
            Write-Error "Error: DLL not found at $dllPath"
        }

        # Cleanup for next variant
        $env:PATH = $oldPath
        Remove-Item $taskFile -ErrorAction SilentlyContinue
        Get-ChildItem -Path $projectRoot -Include "config.h", "config.nice.bat", "config.log", "config.status", "Makefile", "php_winbinder.res" -Recurse | Remove-Item -Force
        Get-ChildItem -Path $projectRoot -Include "*.obj", "*.pdb", "*.exp", "*.lib" -Recurse | Remove-Item -Force
        if (Test-Path "$projectRoot\x64") { Remove-Item -Recurse -Force "$projectRoot\x64" }
        if (Test-Path "$projectRoot\Release") { Remove-Item -Recurse -Force "$projectRoot\Release" }
        if (Test-Path "$projectRoot\Release_TS") { Remove-Item -Recurse -Force "$projectRoot\Release_TS" }
    }
}
