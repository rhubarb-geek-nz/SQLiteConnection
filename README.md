# SQLiteConnection

Very simple `PowerShell` module for creating a connection to an `SQLite` database.

The module contains the native shared libraries containing the `SQLite` implementation.

# Build

Use `dotnet` to build the module directory.

```
dotnet publish SQLiteConnection.csproj --configuration Release
```

The `win` platform native dlls come from [rhubarb-geek-nz/SQLite.Interop-win](https://github.com/rhubarb-geek-nz/SQLite.Interop-win)

The `linux` and `osx` native dlls come from [rhubarb-geek-nz/SQLite.Interop](https://github.com/rhubarb-geek-nz/SQLite.Interop)

The `System.Data.SQLite.dll` comes from [Precompiled Binaries for the .NET Standard 2.0](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)

The reference for packaging the native dlls is at [Writing Portable Modules](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-modules?view=powershell-7.3)

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

This package is published in the [PowerShell Gallery](https://www.powershellgallery.com/packages/rhubarb-geek-nz.SQLiteConnection/1.0.118.0).
