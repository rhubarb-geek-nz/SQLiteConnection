#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLiteConnection.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

param(
	$ModuleName = "SQLiteConnection"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

$env:SOURCEDIR="$ModuleName"
$env:SQLITEVERS=( Import-PowerShellDataFile "$ModuleName/$ModuleName.psd1" ).ModuleVersion

foreach ($List in @(
	@("no","59D933B8-122F-4A31-B9FE-AD899267B381","win-x86","x86","ProgramFilesFolder","x86"),
	@("yes","673E89C5-DA86-4B4D-B305-8280B7E0185C","win-x64","x64","ProgramFiles64Folder","x64"),
	@("yes","673E89C5-DA86-4B4D-B305-8280B7E0185C","win-arm64","x64","ProgramFiles64Folder","arm64")
))
{
	$env:SQLITEISWIN64=$List[0]
	$env:SQLITEUPGRADECODE=$List[1]
	$env:SQLITERID=$List[2]
	$env:SQLITEPLATFORM=$List[3]
	$env:SQLITEPROGRAMFILES=$List[4]
	$env:SQLITECPU=$List[5]

	$MSINAME = "$ModuleName-$env:SQLITEVERS-$env:SQLITECPU.msi"

	foreach ($Name in "$MSINAME")
	{
		if (Test-Path "$Name")
		{
			Remove-Item "$Name"
		} 
	}

	Copy-Item -Path "$ModuleName\$env:SQLITERID\SQLite.Interop.dll.dll" -Destination "$ModuleName\SQLite.Interop.dll"

	& "${env:WIX}bin\candle.exe" -nologo "$ModuleName.wxs"

	if ($LastExitCode -ne 0)
	{
		exit $LastExitCode
	}

	& "${env:WIX}bin\light.exe" -nologo -cultures:null -out "$MSINAME" "$ModuleName.wixobj"

	if ($LastExitCode -ne 0)
	{
		exit $LastExitCode
	}
}
