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
$fromargs = $true


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
                    Write-Host "Updated $file"
                }
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
        "  latest-snapshot: $baseurl/stackage/snapshots.json",
        "package-indices:",
        "  - download-prefix: $baseurl/hackage/",
        "    hackage-security:",
        "        keyids:",
        "        - 0a5c7ea47cd1b15f01f5f51a33adda7e655bc0f0b0615baa8e271f4c3351e21d",
        "        - 1ea9ba32c526d1cc91ab5e5bd364ec5e9e8cb67179a471872f6e26f0ae773d42",
        "        - 280b10153a522681163658cb49f632cde3f38d768b736ddbc901d99a1a772833",
        "        - 2a96b1889dc221c17296fcc2bb34b908ca9734376f0f361660200935916ef201",
        "        - 2c6c3627bd6c982990239487f1abd02e08a02e6cf16edb105a8012d444d870c3",
        "        - 51f0161b906011b52c6613376b1ae937670da69322113a246a09f807c62f6921",
        "        - 772e9f4c7db33d251d5c6e357199c819e569d130857dc225549b40845ff0890d",
        "        - aa315286e6ad281ad61182235533c41e806e5a787e0b6d1e7eef3f09d137d2e9",
        "        - fe331502606802feac15e514d9b9ea83fee8b6ffef71335479a2e68d84adc6b0",
        "        key-threshold: 3",
        "        ignore-expiry: no" | Set-Content $file
        Write-Host "Updated $file"
    }
}

register @('conda','anaconda') {
    if (which 'conda') {
        sh "conda config --add channels $baseurl/anaconda/pkgs/free/"
        sh "conda config --add channels $baseurl/anaconda/pkgs/main/"
        sh "conda config --set show_channel_urls yes"
        sh "conda config --add channels $baseurl/anaconda/cloud/conda-forge/"
        sh "conda config --add channels $baseurl/anaconda/cloud/msys2/"
        sh "conda config --add channels $baseurl/anaconda/cloud/bioconda/"
        sh "conda config --add channels $baseurl/anaconda/cloud/menpo/"
        sh "conda config --add channels $baseurl/anaconda/cloud/pytorch/"
    }
}

register @('flutter') {
    # by default flutter is not applied unless specified
    if ($fromargs) {
        $url = "$baseurl/flutter"
        sh "setx FLUTTER_STORAGE_BASE_URL $url"
    } else {
        Write-Host 'Run ".\oh-my-tuna.ps1 flutter" to enable it'
    }
}

register @('rustup') {
    if (which 'rustup') {
        $url = "$baseurl/rustup"
        sh "setx RUSTUP_DIST_SERVER $url"
    }
}


# process
$ks = first $args $all
$fromargs = [string]$ks -ne [string]$all
foreach ($x in $ks) {
    play $x
}
