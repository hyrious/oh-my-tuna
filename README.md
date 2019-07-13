# oh-my-tuna

**oh-my-tuna** is a script for automating using TUNA mirrors on _Windows_
when applicable.

## Usage

Make sure [PowerShell 5](https://aka.ms/wmf5download) (or later, include
PowerShell Core) and [.NET Framework 4.5](https://www.microsoft.com/net/download)
(or later) are installed. Then run in Powershell:

```powershell
wget 'https://hyrious.me/oh-my-tuna/oh-my-tuna.ps1' -o 'oh-my-tuna.ps1'
.\oh-my-tuna.ps1
```

**Note**: if you get an error you might need to change the execution policy (i.e. enable Powershell) with

```powershell
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
```

## Coverage

- CTAN
- PyPI
- MSYS2
- RubyGems
- stackage

## License

GNU General Public License 3.0.
