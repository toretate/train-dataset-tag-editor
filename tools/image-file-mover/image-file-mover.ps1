param (
    [Parameter(Mandatory = $true)]
    [string]$ParentDir
)

# SOURCE_DIR の定義
$Source = "only_official"
$Normal = $Source + "_default"
$Real = $Source + "_real"
$All = $Source + "_all"

$SourceDir = Join-Path -Path $ParentDir -ChildPath $Source
$DestNormal = Join-Path -Path $ParentDir -ChildPath $Normal
$DestReal = Join-Path -Path $ParentDir -ChildPath $Real
$DestAll = Join-Path -Path $ParentDir -ChildPath $All

# 画像
$ImageExtensions = @("png", "jpg", "jpeg", "webp")

# SOURCE_DIR の存在確認
if (-Not (Test-Path -Path $SourceDir)) {
    Write-Host "Error: $SourceDir does not exist." -ForegroundColor Red
    exit 1
}

# 必要なフォルダを削除して再作成
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $DestAll, $DestNormal, $DestReal
New-Item -ItemType Directory -Path $DestAll, $DestNormal, $DestReal | Out-Null

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

        # 画像とテキストファイルをコピー
        foreach ($Ext in $ImageExtensions + "txt") {
            Copy-Item -Path "$FolderPath\*.$Ext" -Destination $DestRealFolder -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Copied to REAL: $($_.FullName)" -ForegroundColor Green
            }
            Copy-Item -Path "$FolderPath\*.$Ext" -Destination $DestAllFolder -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Copied to ALL: $($_.FullName)" -ForegroundColor Green
            }
        }
    }
    # ノーマル側フォルダ (数値_* だが *_real_* を除く)
    elseif ($FolderName -like "*_*" -and $FolderName -notlike "*_real*") {
        $DestDefaultFolder = Join-Path -Path $DestNormal -ChildPath $FolderName
        $DestAllFolder = Join-Path -Path $DestAll -ChildPath $FolderName
        New-Item -ItemType Directory -Path $DestDefaultFolder, $DestAllFolder | Out-Null

        # 画像とテキストファイルをコピー
        foreach ($Ext in $ImageExtensions + "txt") {
            Copy-Item -Path "$FolderPath\*.$Ext" -Destination $DestDefaultFolder -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Copied to DEFAULT: $($_.FullName)" -ForegroundColor Green
            }
            Copy-Item -Path "$FolderPath\*.$Ext" -Destination $DestAllFolder -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "Copied to ALL: $($_.FullName)" -ForegroundColor Green
            }
        }
    }
}

# テキストファイルと同名の画像ファイルのみを残す
$Destinations = @($DestAll, $DestNormal, $DestReal)
foreach ($Dest in $Destinations) {
    Get-ChildItem -Path $Dest -Recurse -Filter "*.txt" | ForEach-Object {
        $BaseName = $_.BaseName
        $Dir = $_.DirectoryName
        Get-ChildItem -Path $Dir -Filter "*.*" | Where-Object {
            $_.Name -notlike "$BaseName.*" -and $_.Extension -in $ImageExtensions
        } | Remove-Item -Force
    }
}

Write-Host "Processing complete." -ForegroundColor Green