# SQLiteConnection

Very simple PowerShell module for creating a connection to an SQLite database.

The module contains the native shared libraries containing the SQLite implementation.

```
% unzip -l SQLiteConnection.zip
Archive:  SQLiteConnection.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
     3145  03-05-2023 02:48   SQLiteConnection/SQLiteConnection.deps.json
    12512  03-05-2023 16:56   SQLiteConnection/SQLiteConnection.dll
     7904  03-05-2023 02:48   SQLiteConnection/SQLiteConnection.pdb
    10937  03-05-2023 16:56   SQLiteConnection/SQLiteConnection.psd1
   370688  11-25-2022 14:09   SQLiteConnection/System.Data.SQLite.dll
  1115200  12-03-2022 19:10   SQLiteConnection/linux-arm/SQLite.Interop.dll.so
  1733680  12-03-2022 19:11   SQLiteConnection/linux-arm64/SQLite.Interop.dll.so
  1651120  12-03-2022 19:08   SQLiteConnection/linux-x64/SQLite.Interop.dll.so
  2158576  03-05-2023 16:35   SQLiteConnection/osx-arm64/SQLite.Interop.dll.dylib
  2092864  03-05-2023 16:35   SQLiteConnection/osx-x64/SQLite.Interop.dll.dylib
  1336544  12-03-2022 08:38   SQLiteConnection/win-arm/SQLite.Interop.dll.dll
  1919200  12-03-2022 08:38   SQLiteConnection/win-arm64/SQLite.Interop.dll.dll
  1871072  12-03-2022 08:38   SQLiteConnection/win-x64/SQLite.Interop.dll.dll
  1454304  12-03-2022 08:38   SQLiteConnection/win-x86/SQLite.Interop.dll.dll
---------                     -------
 15737746                     14 files
 ```

[Writing Portable Modules](https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/writing-portable-modules?view=powershell-7.3)
