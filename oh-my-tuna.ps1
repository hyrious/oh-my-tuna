<#

    .SYNOPSIS
    Keep calm and use TUNA mirrors.

    .DESCRIPTION
    This script is for automating using TUNA mirrors on Windows when applicable.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS C:\> .\oh-my-tuna.ps1
    > ruby
    > gem sources ...

    .NOTES
    Make sure PowerShell 5 (or later, include PowerShell Core) and .NET Framework 4.5 (or later) are installed.

    .LINK
    https://mirrors.tuna.tsinghua.edu.cn
    https://github.com/tuna/oh-my-tuna
    https://github.com/hyrious/oh-my-tuna

#>


param([switch]$Debug)

if ($Debug) { $DebugPreference = "Continue" }
$baseurl = 'https://mirrors.tuna.tsinghua.edu.cn'
$thehost = 'tuna.tsinghua.edu.cn'
$table = @{}
$all = {@()}.Invoke()


# helper functions
function first($a, $b) { if ($a) { return $a } $b }

function which($exe) { (Get-Command $exe -ErrorAction Ignore).Path }

function touch($file) {
    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    } else {
        New-Item $file -ItemType File -Force | Out-Null
    }
}

function register([string[]]$name, [scriptblock]$action) {
    $all.Add($name[0])
    $table.$name = $action
}

function sh([string]$cmd) {
    Write-Host "> $cmd"
    cmd /c "$cmd"
}

function play([string]$name) {
    foreach ($ks in $table.Keys) {
        if ($ks -contains $name) {
            Write-Host "> $name"
            $block = $table.$ks
            Write-Debug "Executing [$ks] -> {$block}"
            try {
                & $block
            } catch {
                Write-Debug $_
            }
        }
    }
}


# data
register @('ruby','rubygems','gem') {
    $url = "$baseurl/rubygems/"
    if (which 'gem') {
        sh "gem sources --add $url --remove https://rubygems.org/"
    }
    if (which 'bundle') {
        sh "bundle config mirror.https://rubygems.org $url"
    }
}

register @('python','pip','pypi') {
    $url = "https://pypi.$thehost/simple"
    if (which 'pip') {
        sh "pip install -i $url pip -U --user"
        sh "pip config set global.index-url $url"
    }
}

register @('tex','latex','ctan') {
    $url = "$baseurl/CTAN/systems/texlive/tlnet"
    if (which 'tlmgr') {
        sh "tlmgr option repository $url"
    }
}

register @('msys2') {
    $regkey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $dir = Get-ChildItem $regkey -Name `
        | foreach { Get-ItemProperty "$regkey\$_" } `
        | where DisplayName -Like 'MSYS2*'
    if ($dir) {
        $loc = $dir.InstallLocation
        if (Test-Path "$loc\usr\bin\msys-2.0.dll") {
            $payload = @{
                mingw32 = "$baseurl/msys2/mingw/i686"
                mingw64 = "$baseurl/msys2/mingw/x86_64"
                msys = "$baseurl/msys2/msys/`$arch"
            }
            foreach ($k in $payload.Keys) {
                $file = "$loc\etc\pacman.d\mirrorlist.$k"
                $str = "Server = $($payload.$k)"
                $content = Get-Content $file
                $exist = $content | Select-String $str -SimpleMatch
                if (!$exist) {
                    $str,$content | Set-Content $file
                }
                Write-Host "Updated $file"
            }
        }
    }
}

register @('stack','stackage') {
    if (which 'stack') {
        $file = "$env:APPDATA\stack\config.yaml"
        touch $file
        "setup-info: `"$baseurl/stackage/stack-setup.yaml`"",
        "urls:",
        "  latest-snapshot: $baseurl/stackage/snapshots.json" | Set-Content $file
        Write-Host "Updated $file"
    }
}

# process
foreach ($x in (first $args $all)) {
    play $x
}
