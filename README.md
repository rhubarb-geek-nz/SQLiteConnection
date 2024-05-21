# SQLiteConnection

Very simple `PowerShell` module for creating a connection to an `SQLite` database.

# Build

Use `dotnet` to build the module directory.

```
dotnet publish SQLiteConnection.csproj --configuration Release
```

The `SQLite` runtime comes from [rhubarb-geek-nz/SQLite.Core.NetStandard](https://github.com/rhubarb-geek-nz/SQLite.Core.NetStandard). This provides native binaries for multiple platforms and architectures.

## Install

Install by copying into a directory on the [PSModulePath](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath)

## Test

Test the package with `test.ps1`, this uses `sqlite3` to create the initial database.

```

CONTENT
-------
Hello World

```

## Notes

Packaging script uses [Export-PowerShellDataFile](https://www.powershellgallery.com/packages/rhubarb-geek-nz.PowerShellDataFile/1.0.0) to format the manifest file.
