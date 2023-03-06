#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
#
#  This file is part of rhubarb-geek-nz/SQLiteConnection.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by the
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

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VERSION = "1.0.117.0"
$BINDIR = "bin/Release/netstandard2.0"
$RID = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier

trap
{
	throw $PSItem
}

foreach ($Name in "obj", "bin", "runtimes", "SQLiteConnection", "SQLiteConnection.zip")
{
	if (Test-Path "$Name")
	{
		Remove-Item "$Name" -Force -Recurse
	} 
}

dotnet build SQLiteConnection.csproj --configuration Release

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

$SQLZIP = "sqlite-netStandard20-binary-$VERSION.zip"

if (-not(Test-Path "$SQLZIP"))
{
	Invoke-WebRequest -Uri "https://system.data.sqlite.org/blobs/$VERSION/$SQLZIP" -OutFile "$SQLZIP" 
}

Expand-Archive -LiteralPath "$SQLZIP" -DestinationPath "$BINDIR"

foreach ($Name in "dll.config", "pdb", "xml")
{
	Remove-Item -LiteralPath "$BINDIR/System.Data.SQLite.$Name"
}

$WINZIP = "SQLite.Interop-$VERSION-win.zip"

if (-not(Test-Path "$WINZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop-win/releases/download/$VERSION/$WINZIP" -OutFile "$WINZIP" 
}

$LINUXZIP = "SQLite.Interop-$VERSION-debian.11.zip"

if (-not(Test-Path "$LINUXZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download/$VERSION/$LINUXZIP" -OutFile "$LINUXZIP" 
}

$OSXZIP = "SQLite.Interop-$VERSION-osx.13.0.zip"

if (-not(Test-Path "$OSXZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download/$VERSION/$OSXZIP" -OutFile "$OSXZIP" 
}

foreach ($ZIP in "$WINZIP", "$LINUXZIP", "$OSXZIP")
{
	Expand-Archive -LiteralPath "$ZIP" -DestinationPath "."
}

foreach ($A in "osx-x64", "osx-arm64")
{
	$null = New-Item -Path "$BINDIR" -Name "$A" -ItemType "directory"
}

$SQLINTEROP = "SQLite.Interop.dll"

foreach ($A in "x64", "arm64", "x86", "arm")
{
	if (Test-Path "runtimes/debian.11-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path "$BINDIR" -Name "linux-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/debian.11-$A/native/$SQLINTEROP" -Destination "$BINDIR/linux-$A/$SQLINTEROP.so"
	}

	if (Test-Path "runtimes/win-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path "$BINDIR" -Name "win-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/win-$A/native/$SQLINTEROP" -Destination "$BINDIR/win-$A/$SQLINTEROP.dll"
	}
}

if ($RID.StartsWith("osx."))
{
	lipo -info "runtimes/osx.13.0/native/$SQLINTEROP"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	lipo "runtimes/osx.13.0/native/$SQLINTEROP" -extract x86_64 -output "$BINDIR/osx-x64/$SQLINTEROP.dylib"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	lipo "runtimes/osx.13.0/native/$SQLINTEROP" -extract arm64 -output "$BINDIR/osx-arm64/$SQLINTEROP.dylib"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}
else
{
	foreach ($A in "x64", "arm64")
	{
		$null = Copy-Item -Path "runtimes/osx.13.0/native/$SQLINTEROP" -Destination "$BINDIR/osx-$A/$SQLINTEROP.dylib"
	}
}

Copy-Item -Path "$BINDIR" -Destination "SQLiteConnection" -Recurse

Compress-Archive -Path "SQLiteConnection" -DestinationPath "SQLiteConnection.zip"
