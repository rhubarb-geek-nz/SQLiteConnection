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

param(
	$ModuleName = 'SQLiteConnection',
	$Version = '1.0.117.0',
	$LinuxRID = 'debian.11',
	$AddLinux = $true,
	$AddWin = $true,
	$AddOSX = $true,
	$ZipFile = "$ModuleName-$Version.zip"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$BINDIR = "bin/Release/netstandard2.0"
$RID = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier

trap
{
	throw $PSItem
}

foreach ($Name in "obj", "bin", "runtimes", "$ModuleName", "$ZipFile")
{
	if (Test-Path "$Name")
	{
		Remove-Item "$Name" -Force -Recurse
	} 
}

dotnet build $ModuleName.csproj --configuration Release

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

$SQLZIP = "sqlite-netStandard20-binary-$Version.zip"

if (-not(Test-Path "$SQLZIP"))
{
	Invoke-WebRequest -Uri "https://system.data.sqlite.org/blobs/$Version/$SQLZIP" -OutFile "$SQLZIP"
}

Expand-Archive -LiteralPath "$SQLZIP" -DestinationPath "$BINDIR"

foreach ($Name in "dll.config", "pdb", "xml")
{
	Remove-Item -LiteralPath "$BINDIR/System.Data.SQLite.$Name"
}

foreach ($Name in "deps.json", "pdb")
{
	Remove-Item -LiteralPath "$BINDIR/$ModuleName.$Name"
}

$WINZIP = "SQLite.Interop-$Version-win.zip"
$LINUXZIP = "SQLite.Interop-$Version-$LinuxRID.zip"
$OSXZIP = "SQLite.Interop-$Version-osx.13.0.zip"

if ($AddWin -and -not(Test-Path "$WINZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop-win/releases/download/$Version/$WINZIP" -OutFile "$WINZIP"
}

if ($AddLinux -and -not(Test-Path "$LINUXZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download/$Version/$LINUXZIP" -OutFile "$LINUXZIP"
}

if ($AddOSX -and -not(Test-Path "$OSXZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download/$Version/$OSXZIP" -OutFile "$OSXZIP"
}

foreach ($ZIP in "$WINZIP", "$LINUXZIP", "$OSXZIP")
{
	if (Test-Path $ZIP)
	{
		Expand-Archive -LiteralPath "$ZIP" -DestinationPath "."
	}
}

$SQLINTEROP = "SQLite.Interop.dll"

foreach ($A in "x64", "arm64", "x86", "arm")
{
	if ($AddLinux -and (Test-Path "runtimes/$LinuxRID-$A/native/$SQLINTEROP"))
	{
		$null = New-Item -Path "$BINDIR" -Name "linux-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/$LinuxRID-$A/native/$SQLINTEROP" -Destination "$BINDIR/linux-$A/$SQLINTEROP.so"
	}

	if ($AddWin -and (Test-Path "runtimes/win-$A/native/$SQLINTEROP"))
	{
		$null = New-Item -Path "$BINDIR" -Name "win-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/win-$A/native/$SQLINTEROP" -Destination "$BINDIR/win-$A/$SQLINTEROP.dll"
	}
}

if ($AddOSX)
{
	foreach ($A in "osx-x64", "osx-arm64")
	{
		$null = New-Item -Path "$BINDIR" -Name "$A" -ItemType "directory"
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
}

Copy-Item -Path "$BINDIR" -Destination "$ModuleName" -Recurse

@"
@{
	RootModule = '$ModuleName.dll'
	ModuleVersion = '$Version'
	GUID = 'e8e28b5f-a18e-4630-a957-856baefed648'
	Author = 'Roger Brown'
	CompanyName = 'rhubarb-geek-nz'
	Copyright = '(c) Roger Brown. All rights reserved.'
	FunctionsToExport = @()
	CmdletsToExport = @('New-$ModuleName')
	VariablesToExport = '*'
	AliasesToExport = @()
	PrivateData = @{
		PSData = @{
		}
	}
}
"@ | Set-Content -Path "$ModuleName/$ModuleName.psd1"

Compress-Archive -Path "$ModuleName" -DestinationPath "$ZipFile"
