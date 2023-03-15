# SQLiteConnection

Very simple `PowerShell` module for creating a connection to an `SQLite` database.

The module contains the native shared libraries containing the `SQLite` implementation.

```
$ unzip -l SQLiteConnection-1.0.117.0.zip
Archive:  SQLiteConnection-1.0.117.0.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     5120  2023-03-13 02:26   SQLiteConnection/SQLiteConnection.dll
      385  2023-03-13 02:26   SQLiteConnection/SQLiteConnection.psd1
   370688  2022-11-25 14:09   SQLiteConnection/System.Data.SQLite.dll
  1336544  2022-12-03 08:38   SQLiteConnection/win-arm/SQLite.Interop.dll.dll
  2092864  2023-03-13 02:26   SQLiteConnection/osx-x64/SQLite.Interop.dll.dylib
  1115200  2022-12-03 19:10   SQLiteConnection/linux-arm/SQLite.Interop.dll.so
  1733680  2022-12-03 19:11   SQLiteConnection/linux-arm64/SQLite.Interop.dll.so
  1454304  2022-12-03 08:38   SQLiteConnection/win-x86/SQLite.Interop.dll.dll
  2158576  2023-03-13 02:26   SQLiteConnection/osx-arm64/SQLite.Interop.dll.dylib
  1871072  2022-12-03 08:38   SQLiteConnection/win-x64/SQLite.Interop.dll.dll
  1651120  2022-12-03 19:08   SQLiteConnection/linux-x64/SQLite.Interop.dll.so
  1919200  2022-12-03 08:38   SQLiteConnection/win-arm64/SQLite.Interop.dll.dll
---------                     -------
 15708753                     12 files
 ```

Use `package.ps1` to build the zip.

The `win` platform native dlls come from [rhubarb-geek-nz/SQLite.Interop-win](https://github.com/rhubarb-geek-nz/SQLite.Interop-win)

The `linux` and `osx` native dlls come from [rhubarb-geek-nz/SQLite.Interop](https://github.com/rhubarb-geek-nz/SQLite.Interop)

The `System.Data.SQLite.dll` comes from [Precompiled Binaries for the .NET Standard 2.0](https://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki)

The reference for packaging the native dlls is at [Writing Portable Modules](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-modules?view=powershell-7.3)

Install by unzipping into a directory on the [PSModulePath](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_psmodulepath)

Test the package with `test.ps1`, this uses `sqlite3` to create the initial database.

```

CONTENT
-------
Hello World

```
