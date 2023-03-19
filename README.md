# SQLiteConnection

Very simple `PowerShell` module for creating a connection to an `SQLite` database.

The module contains the native shared libraries containing the `SQLite` implementation.

```
% unzip -l rhubarb-geek-nz.SQLiteConnection.Desktop.1.0.117.nupkg
Archive:  rhubarb-geek-nz.SQLiteConnection.Desktop.1.0.117.nupkg
  Length      Date    Time    Name
---------  ---------- -----   ----
      530  03-19-2023 14:28   _rels/.rels
      804  03-19-2023 14:28   rhubarb-geek-nz.SQLiteConnection.Desktop.nuspec
      103  03-19-2023 10:04   README.md
  1871072  12-03-2022 07:38   x64/SQLite.Interop.dll
  1336544  12-03-2022 07:38   arm/SQLite.Interop.dll
   370688  11-25-2022 13:09   System.Data.SQLite.dll
  1454304  12-03-2022 07:38   x86/SQLite.Interop.dll
  1919200  12-03-2022 07:38   arm64/SQLite.Interop.dll
     5120  03-19-2023 10:04   SQLiteConnection.dll
      559  03-19-2023 10:04   rhubarb-geek-nz.SQLiteConnection.Desktop.psd1
      583  03-19-2023 14:28   [Content_Types].xml
      678  03-19-2023 14:28   package/services/metadata/core-properties/a4d0231dc9bc4e3e8132b098208e905f.psmdcp
---------                     -------
  6960185                     12 files
```

Use `package.ps1` to build the zip.

The `win` platform native dlls come from [rhubarb-geek-nz/SQLite.Interop-win](https://github.com/rhubarb-geek-nz/SQLite.Interop-win)

The `System.Data.SQLite.dll` comes from [Precompiled Binaries for the .NET Standard 2.0](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)

Install by copying into a directory on the [PSModulePath](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath?view=powershell-5.1)

Test the package with `test.ps1`, this uses `sqlite3` to create the initial database.

```

CONTENT
-------
Hello World

```
