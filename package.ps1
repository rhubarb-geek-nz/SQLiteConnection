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
	$LinuxRID = 'debian.11',
	$OsxRID = 'osx.11',
	$CompanyName = 'rhubarb-geek-nz'
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$BINDIR = "bin/Release/netstandard2.0"
$RID = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier
$compatiblePSEdition = 'Core'
$PowerShellVersion = '7.2'

trap
{
	throw $PSItem
}

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.nuspec")

$Version = $xmlDoc.SelectSingleNode("/package/metadata/version").FirstChild.Value
$ModuleId = $xmlDoc.SelectSingleNode("/package/metadata/id").FirstChild.Value
$ProjectUri = $xmlDoc.SelectSingleNode("/package/metadata/projectUrl").FirstChild.Value
$Description = $xmlDoc.SelectSingleNode("/package/metadata/description").FirstChild.Value
$Author = $xmlDoc.SelectSingleNode("/package/metadata/authors").FirstChild.Value
$Copyright = $xmlDoc.SelectSingleNode("/package/metadata/copyright").FirstChild.Value

foreach ($Name in "obj", "bin", "runtimes", "$ModuleId")
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
$OSXZIP = "SQLite.Interop-$Version-$OsxRID.zip"

if (-not(Test-Path "$WINZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop-win/releases/download/$Version/$WINZIP" -OutFile "$WINZIP"
}

if (-not(Test-Path "$LINUXZIP"))
{
	Invoke-WebRequest -Uri "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download/$Version/$LINUXZIP" -OutFile "$LINUXZIP"
}

if (-not(Test-Path "$OSXZIP"))
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
	if (Test-Path "runtimes/$LinuxRID-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path "$BINDIR" -Name "linux-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/$LinuxRID-$A/native/$SQLINTEROP" -Destination "$BINDIR/linux-$A/$SQLINTEROP.so"
	}

	if (Test-Path "runtimes/$OsxRID-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path "$BINDIR" -Name "osx-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/$OsxRID-$A/native/$SQLINTEROP" -Destination "$BINDIR/osx-$A/$SQLINTEROP.dylib"
	}

	if (Test-Path "runtimes/win-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path "$BINDIR" -Name "win-$A" -ItemType "directory"

		$null = Move-Item -Path "runtimes/win-$A/native/$SQLINTEROP" -Destination "$BINDIR/win-$A/$SQLINTEROP.dll"
	}
}

Copy-Item -Path "$BINDIR" -Destination "$ModuleId" -Recurse

New-ModuleManifest -Path "$ModuleId/$ModuleId.psd1" `
				-RootModule "$ModuleName.dll" `
				-ModuleVersion $Version `
				-Guid 'e8e28b5f-a18e-4630-a957-856baefed648' `
				-Author $Author `
				-CompanyName $CompanyName `
				-Copyright $Copyright `
				-Description $Description `
				-PowerShellVersion $PowerShellVersion `
				-CompatiblePSEditions @($compatiblePSEdition) `
				-FunctionsToExport @() `
				-CmdletsToExport @("New-$ModuleName") `
				-VariablesToExport '*' `
				-AliasesToExport @() `
				-ProjectUri $ProjectUri

function Justify
{
	begin
	{
		$Count = 0
	}
	process
	{
		if ($Count -eq 1)
		{
			$Next
		}
		if ($Count -gt 1)
		{
			"    $Next"
		}

		$Next = $_
		$Count = $Count + 1
	}
	end
	{
		$Next
	}
}

Get-Content -LiteralPath "$ModuleId/$ModuleId.psd1" | ForEach-Object {
	$T = $_.Trim()
	if ($T)
	{
		if ( -not $T.StartsWith('#') )
		{
			if ($T.StartsWith('} # End of '))
			{
				$_.Substring(0,$_.IndexOf('}')+1)
			}
			else
			{
				$_
			}
		}
	}
} | Justify | Set-Content -LiteralPath "$ModuleId/$ModuleId.psd1.clean"

Remove-Item -LiteralPath "$ModuleId/$ModuleId.psd1"

Move-Item -LiteralPath "$ModuleId/$ModuleId.psd1.clean" -Destination "$ModuleId/$ModuleId.psd1"

Import-PowerShellDataFile -LiteralPath "$ModuleId/$ModuleId.psd1"

(Get-Content "./README.md")[0..2] | Set-Content -Path "$ModuleId/README.md"
