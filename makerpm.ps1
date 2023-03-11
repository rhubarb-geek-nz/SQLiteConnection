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
	$ModuleName = "SQLiteConnection"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$RID = [System.Runtime.InteropServices.RuntimeInformation]::RuntimeIdentifier.Split('-')[0]
$ModulesPath = "opt/microsoft/powershell/7/Modules"
$PackageName = "rhubarb-geek-nz-SQLiteConnection"

If ( -not( $Env:PSModulePath.Split(":").Contains("/$ModulesPath") ) )
{
	throw "$Env:PSModulePath does not contain /$ModulesPath"
}

If (-not($Env:MAINTAINER))
{
	throw "MAINTAINER environment not set"
}

trap
{
	throw $PSItem
}

foreach ($Name in "data")
{
	if (Test-Path "$Name")
	{
		Remove-Item "$Name" -Force -Recurse
	} 
}

$Version=( Import-PowerShellDataFile "$ModuleName/$ModuleName.psd1" ).ModuleVersion

$null = New-Item -Path "." -Name "root/$ModulesPath/$ModuleName" -ItemType "directory"
$null = New-Item -Path "." -Name "rpms" -ItemType "directory"

try
{
	foreach ($Name in "$ModuleName.psd1", "$ModuleName.dll", "$ModuleName.deps.json", "System.Data.SQLite.dll")
	{
		Copy-Item -Path "$ModuleName/$Name" -Destination "root/$ModulesPath/$ModuleName/$Name"
	}

	git clone https://github.com/rhubarb-geek-nz/SQLite.Interop.git build

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	try
	{
		Push-Location "build"

		git checkout "$Version"

		If ( $LastExitCode -ne 0 )
		{
			Exit $LastExitCode
		}

		./package.sh

		If ( $LastExitCode -ne 0 )
		{
			Exit $LastExitCode
		}

		./test.sh

		If ( $LastExitCode -ne 0 )
		{
			Exit $LastExitCode
		}

		Get-ChildItem -LiteralPath "." -Filter *.zip | Foreach-Object {
			Expand-Archive -Path $_.FullName -DestinationPath "."
		}
	}
	finally
	{
		Pop-Location
	}

	Get-ChildItem -LiteralPath "build/runtimes" -Filter "SQLite.Interop.dll" -Recurse | Foreach-Object {
		$FileName = $_.Name
		Copy-Item $_.FullName -Destination "root/$ModulesPath/$ModuleName/$FileName"
	}

	@"
Name: $PackageName
Version: $Version
Release: $RID
Requires: powershell
License: LGPL
Summary: PowerShell SQLiteConnection Cmdlet
Prefix: /$ModulesPath

%description
PowerShell Cmdlet for connection to SQLite databases

%files
%defattr(-,root,root)
%dir %attr(555,root,root) /$ModulesPath/SQLiteConnection
%attr(444,root,root)      /$ModulesPath/SQLiteConnection/SQLiteConnection.dll
%attr(444,root,root)      /$ModulesPath/SQLiteConnection/SQLiteConnection.psd1
%attr(444,root,root)      /$ModulesPath/SQLiteConnection/SQLiteConnection.deps.json
%attr(444,root,root)      /$ModulesPath/SQLiteConnection/System.Data.SQLite.dll
%attr(444,root,root)      /$ModulesPath/SQLiteConnection/SQLite.Interop.dll

"@ | Set-Content "rpm.spec"

	rpmbuild --buildroot "$PSScriptRoot/root" --define "_build_id_links none" --define "_rpmdir $PSScriptRoot/rpms" -bb "$PSScriptRoot/rpm.spec"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	Get-ChildItem -LiteralPath "rpms" -Filter "*.rpm" -Recurse | Foreach-Object {
		$FileName = $_.Name
		Copy-Item $_.FullName -Destination "$FileName"
	}
}
finally
{
	foreach ($Name in "root", "build", "rpms")
	{
		if (Test-Path $Name)
		{
			Remove-Item "$Name" -Recurse -Force
		}
	}
}
