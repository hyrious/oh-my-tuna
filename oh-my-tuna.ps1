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

# TODO: msys2, stack


# process
foreach ($x in (first $args $all)) {
    play $x
}
