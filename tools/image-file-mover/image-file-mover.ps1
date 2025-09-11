param (
    [Parameter(Mandatory = $true)]
    [string]$ParentDir
)

# SOURCE_DIR の定義
$SourceDir = Join-Path -Path $ParentDir -ChildPath "only_official"
$DestAll = Join-Path -Path $ParentDir -ChildPath "only_official_all"
$DestDefault = Join-Path -Path $ParentDir -ChildPath "only_official_default"
$DestReal = Join-Path -Path $ParentDir -ChildPath "only_official_real"

# SOURCE_DIR の存在確認
if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "Error: $SourceDir does not exist." -ForegroundColor Red
    exit 1
}

# 必要なフォルダを削除して再作成
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $DestAll, $DestDefault, $DestReal
New-Item -ItemType Directory -Path $DestAll, $DestDefault, $DestReal | Out-Null

# フォルダを走査
Get-ChildItem -Path $SourceDir -Directory | ForEach-Object {
    $FolderName = $_.Name
    $FolderPath = $_.FullName

    # 先頭が数値で始まらないフォルダはスキップ
    if ($FolderName -notmatch "^\d") {
        Write-Host "Skipping folder: $FolderName (does not start with a number)" -ForegroundColor Yellow
        return
    }

    # 現実側フォルダ (数値_real_*)
    if ($FolderName -like "*_real*") {
        $DestRealFolder = Join-Path -Path $DestReal -ChildPath $FolderName
        $DestAllFolder = Join-Path -Path $DestAll -ChildPath $FolderName
        New-Item -ItemType Directory -Path $DestRealFolder, $DestAllFolder | Out-Null
        Copy-Item -Path "$FolderPath\*.{png,jpeg,webp,txt}" -Destination $DestRealFolder -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Copied to REAL: $($_.FullName)" -ForegroundColor Green
        }
        Copy-Item -Path "$FolderPath\*.{png,jpeg,webp,txt}" -Destination $DestAllFolder -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Copied to ALL: $($_.FullName)" -ForegroundColor Green
        }
    }
    # アストルム側フォルダ (数値_* だが *_real_* を除く)
    elseif ($FolderName -like "*_*" -and $FolderName -notlike "*_real*") {
        $DestDefaultFolder = Join-Path -Path $DestDefault -ChildPath $FolderName
        $DestAllFolder = Join-Path -Path $DestAll -ChildPath $FolderName
        New-Item -ItemType Directory -Path $DestDefaultFolder, $DestAllFolder | Out-Null
        Copy-Item -Path "$FolderPath\*.{png,jpeg,webp,txt}" -Destination $DestDefaultFolder -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Copied to DEFAULT: $($_.FullName)" -ForegroundColor Green
        }
        Copy-Item -Path "$FolderPath\*.{png,jpeg,webp,txt}" -Destination $DestAllFolder -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "Copied to ALL: $($_.FullName)" -ForegroundColor Green
        }
    }
}

# テキストファイルと同名の画像ファイルのみを残す
$Destinations = @($DestAll, $DestDefault, $DestReal)
foreach ($Dest in $Destinations) {
    Get-ChildItem -Path $Dest -Recurse -Filter "*.txt" | ForEach-Object {
        $BaseName = $_.BaseName
        $Dir = $_.DirectoryName
        Get-ChildItem -Path $Dir -Filter "*.*" | Where-Object {
            $_.Name -notlike "$BaseName.*" -and $_.Extension -in (".png", ".jpeg", ".webp")
        } | Remove-Item -Force
    }
}

Write-Host "Processing complete." -ForegroundColor Green