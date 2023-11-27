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

param($ProjectName, $IntermediateOutputPath, $OutDir, $PublishDir, $LinuxRID = 'alpine.3.18')

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
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

$xmlDoc = [System.Xml.XmlDocument](Get-Content "$ProjectName.csproj")

$ModuleId = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageId'
$Version = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Version'
$ProjectUri = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageProjectUrl'
$Description = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Description'
$Author = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Authors'
$Copyright = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Copyright'
$AssemblyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/AssemblyName'
$CompanyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Company'

$SQLZIP = "sqlite-netStandard20-binary-$Version.zip"
$LINUXZIP = "SQLite.Interop-$Version-$LinuxRID.zip"
$SQLINTEROP = "SQLite.Interop.dll"

$SQLURL = "https://system.data.sqlite.org/blobs"
$OSXURL = "https://github.com/rhubarb-geek-nz/SQLite.Interop/releases/download"

foreach ($SRC in @($SQLZIP, $SQLURL, "$PublishDir/sqlite-netStandard20-binary"), @($LINUXZIP, $OSXURL, $PublishDir))
{
	$ZIP = $SRC[0]
	$URL = $SRC[1]
	$DEST = $SRC[2]

	if (-not(Test-Path "$IntermediateOutputPath$ZIP"))
	{
		Invoke-WebRequest -Uri "$URL/$Version/$ZIP" -OutFile "$IntermediateOutputPath$ZIP"
	}

	Expand-Archive -LiteralPath "$IntermediateOutputPath$ZIP" -DestinationPath $DEST
}

foreach ($A in 'x64', 'arm64', 'arm')
{
	if (Test-Path "$PublishDir/runtimes/$LinuxRID-$A/native/$SQLINTEROP")
	{
		$null = New-Item -Path $PublishDir -Name "linux-$A" -ItemType 'directory'

		$null = Move-Item -Path "$PublishDir/runtimes/$LinuxRID-$A/native/$SQLINTEROP" -Destination "$PublishDir/linux-$A/$SQLINTEROP.so"
	}
}

$null = Move-Item -Path "$PublishDir/sqlite-netStandard20-binary/System.Data.SQLite.dll" -Destination $PublishDir

$moduleSettings = @{
	Path = "$OutDir$ModuleId.psd1"
	RootModule = "$AssemblyName.dll"
	ModuleVersion = $Version
	Guid = 'e8e28b5f-a18e-4630-a957-856baefed648'
	Author = $Author
	CompanyName = $CompanyName
	Copyright = $Copyright
	Description = $Description
	PowerShellVersion = $PowerShellVersion
	CompatiblePSEditions = @($compatiblePSEdition)
	FunctionsToExport = @()
	CmdletsToExport = @("New-$ProjectName")
	VariablesToExport = '*'
	AliasesToExport = @()
	ProjectUri = $ProjectUri
}

New-ModuleManifest @moduleSettings

Import-PowerShellDataFile -LiteralPath "$OutDir$ModuleId.psd1" | Export-PowerShellDataFile | Set-Content -LiteralPath "$PublishDir$ModuleId.psd1"

(Get-Content "./README.md")[0..2] | Set-Content -Path "$PublishDir/README.md"
