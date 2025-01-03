#!/usr/bin/env pwsh
# Copyright (c) 2024 Roger Brown.
# Licensed under the MIT License.

param($ProjectName, $IntermediateOutputPath, $OutDir, $PublishDir, $Version, $PowerShellVersion)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$compatiblePSEdition = 'Core'

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
$ProjectUri = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageProjectUrl'
$Description = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Description'
$Author = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Authors'
$Copyright = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Copyright'
$AssemblyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/AssemblyName'
$CompanyName = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/Company'
$ReleaseNotes = Get-SingleNodeValue $xmlDoc '/Project/PropertyGroup/PackageReleaseNotes'

$PublishDirLib = "$PublishDir/lib"

if (Test-Path $PublishDirLib)
{
	Remove-Item $PublishDirLib -Recurse
}

$null = Move-Item "$PublishDir/runtimes" $PublishDirLib

Remove-Item "$PublishDirLib/browser-wasm" -Recurse

$null = Move-Item "$PublishDir/Microsoft*.dll" $PublishDirLib
$null = Move-Item "$PublishDir/SQLitePCLRaw*.dll" $PublishDirLib
$null = Move-Item "$PublishDir/$AssemblyName.Alc.dll" $PublishDirLib

Get-ChildItem $PublishDirLib -Directory | ForEach-Object {
	$RuntimeDir = $_.FullName

	Get-ChildItem "$RuntimeDir/native" -Filter '*.dll' | ForEach-Object {
		$null = Move-Item $_.FullName $RuntimeDir
	}

	Get-ChildItem "$RuntimeDir/native" -Filter 'lib*.dylib' | ForEach-Object {
		$null = Move-Item $_.FullName $RuntimeDir
	}

	Get-ChildItem "$RuntimeDir/native" -Filter 'lib*.so' | ForEach-Object {
		$null = Move-Item $_.FullName $RuntimeDir
	}

	Remove-Item "$RuntimeDir/native" -Recurse
}

$moduleSettings = @{
	Path = "$OutDir$ModuleId.psd1"
	RootModule = "$AssemblyName.dll"
	ModuleVersion = $Version
	Guid = '23519034-6db5-4b2f-8f55-1b4e58d14af8'
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
	ReleaseNotes = $ReleaseNotes
}

New-ModuleManifest @moduleSettings

Import-PowerShellDataFile -LiteralPath "$OutDir$ModuleId.psd1" | Export-PowerShellDataFile | Set-Content -LiteralPath "$PublishDir$ModuleId.psd1" -Encoding utf8BOM

(Get-Content "../README.md")[0..2] | Set-Content -Path "$PublishDir/README.md" -Encoding utf8BOM
