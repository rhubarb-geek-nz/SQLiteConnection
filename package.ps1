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

function Get-SingleNodeValue([System.Xml.XmlDocument]$doc,[string]$path)
{
	return $doc.SelectSingleNode($path).FirstChild.Value
}

function FirstAndLast
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

function NoComment
{
	process
	{
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
	}
}

function Cleanup
{
	foreach ($Name in "obj", "bin", "runtimes", "$ModuleId.psd1")
	{
		if (Test-Path "$Name")
		{
			Remove-Item "$Name" -Force -Recurse
		} 
	}
}

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ModuleName.nuspec")

$Version = Get-SingleNodeValue $xmlDoc "/package/metadata/version"
$ModuleId = Get-SingleNodeValue $xmlDoc "/package/metadata/id"
$ProjectUri = Get-SingleNodeValue $xmlDoc "/package/metadata/projectUrl"
$Description = Get-SingleNodeValue $xmlDoc "/package/metadata/description"
$Author = Get-SingleNodeValue $xmlDoc "/package/metadata/authors"
$Copyright = Get-SingleNodeValue $xmlDoc "/package/metadata/copyright"

Cleanup

if (Test-Path "$ModuleId")
{
	Remove-Item "$ModuleId" -Force -Recurse
}
 
dotnet build $ModuleName.csproj --configuration Release

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

$SQLZIP = "sqlite-netStandard20-binary-$Version.zip"
$WINZIP = "SQLite.Interop-$Version-win.zip"
$LINUXZIP = "SQLite.Interop-$Version-$LinuxRID.zip"
$OSXZIP = "SQLite.Interop-$Version-$OsxRID.zip"
$SQLINTEROP = "SQLite.Interop.dll"

$SQLURL = "https://system.data.sqlite.org/blobs"
$WINURL = "https://github.com/rhubarb-geek-nz/SQLite.Interop-win/releases/download"
$OSXURL = "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download"

foreach ($SRC in @($SQLZIP, $SQLURL, $BINDIR), @($WINZIP, $WINURL, '.'), @($OSXZIP, $OSXURL, '.'),@($LINUXZIP, $OSXURL, '.'))
{
	$ZIP = $SRC[0]
	$URL = $SRC[1]
	$DEST = $SRC[2]

	if (-not(Test-Path $ZIP))
	{
		Invoke-WebRequest -Uri "$URL/$Version/$ZIP" -OutFile $ZIP
	}

	Expand-Archive -LiteralPath $ZIP -DestinationPath $DEST
}

foreach ($SRC in $('System.Data.SQLite', $('dll.config', 'pdb', 'xml')), $($ModuleName, $('deps.json', 'pdb')))
{
	$NAME = $SRC[0]

	foreach ($EXT in $SRC[1])
	{
		Remove-Item -LiteralPath "$BINDIR/$NAME.$EXT"
	}
}

foreach ($A in 'x64', 'arm64', 'x86', 'arm')
{
	foreach ($B in @($LinuxRID, 'linux', 'so'), @($OsxRID, 'osx', 'dylib'), @('win', 'win', 'dll'))
	{
		$SRC = $B[0]
		$DEST = $B[1]
		$EXT = $B[2]

		if (Test-Path "runtimes/$SRC-$A/native/$SQLINTEROP")
		{
			$null = New-Item -Path $BINDIR -Name "$DEST-$A" -ItemType 'directory'

			$null = Move-Item -Path "runtimes/$SRC-$A/native/$SQLINTEROP" -Destination "$BINDIR/$DEST-$A/$SQLINTEROP.$EXT"
		}
	}
}

Move-Item -LiteralPath "$BINDIR" -Destination "$ModuleId"

New-ModuleManifest -Path "$ModuleId.psd1" `
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

Get-Content -LiteralPath "$ModuleId.psd1" | NoComment | FirstAndLast | Set-Content -LiteralPath "$ModuleId/$ModuleId.psd1"

Remove-Item -LiteralPath "$ModuleId.psd1"

Import-PowerShellDataFile -LiteralPath "$ModuleId/$ModuleId.psd1"

(Get-Content "./README.md")[0..2] | Set-Content -Path "$ModuleId/README.md"

Cleanup
