# SQLiteConnection

Very simple `PowerShell` module for creating a connection to an `SQLite` database.

The module contains the native shared libraries containing the `SQLite` implementation.

Use `package.ps1` to build the module directory.

The `win` platform native dlls come from [rhubarb-geek-nz/SQLite.Interop-win](https://github.com/rhubarb-geek-nz/SQLite.Interop-win)

The `System.Data.SQLite.dll` comes from [Precompiled Binaries for the .NET Standard 2.0](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)

Install by copying into a directory on the [PSModulePath](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-5.1)

Test the package with `test.ps1`, this uses `sqlite3` to create the initial database.

```

CONTENT
-------
Hello World

```
