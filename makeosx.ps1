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

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

$ModuleName = "SQLiteConnection"
$Version = ( Import-PowerShellDataFile "$ModuleName/$ModuleName.psd1" ).ModuleVersion
$Identifier = "rhubarb.geek.nz.$ModuleName"
$FullName = "$ModuleName-$Version-osx.pkg"
$ModulesPath = "usr/local/share/powershell/Modules"

If ( -not( $Env:PSModulePath.Split(":").Contains("/$ModulesPath") ) )
{
	throw "$Env:PSModulePath does not contain /$ModulesPath"
}

$null = New-Item -Path "." -Name "root/$ModulesPath/$ModuleName" -ItemType "directory"

try
{
	foreach ($Name in "$ModuleName.psd1", "$ModuleName.dll", "System.Data.SQLite.dll")
	{
		Copy-Item -Path "$ModuleName/$Name" -Destination "root/$ModulesPath/$ModuleName/$Name"
	}

	lipo -create "$ModuleName/osx-x64/SQLite.Interop.dll.dylib" "$ModuleName/osx-arm64/SQLite.Interop.dll.dylib" -output "root/$ModulesPath/$ModuleName/SQLite.Interop.dll"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

	& pkgbuild --identifier "$Identifier" --version "$Version" --root "root" --install-location "/" --sign "Developer ID Installer: $Env:APPLE_DEVELOPER" "$ModuleName.pkg"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}

@"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<installer-gui-script minSpecVersion=`"1`">
    <pkg-ref id=`"$Identifier`"/>
    <options customize=`"never`" require-scripts=`"false`" hostArchitectures=`"arm64,x86_64`"/>
    <choices-outline>
        <line choice=`"default`">
            <line choice=`"$Identifier`"/>
        </line>
    </choices-outline>
    <choice id=`"default`"/>
    <choice id=`"$Identifier`" visible=`"false`">
        <pkg-ref id=`"$Identifier`"/>
    </choice>
    <pkg-ref id=`"$Identifier`" version=`"$Version`" onConclusion=`"none`">$ModuleName.pkg</pkg-ref>
    <title>SQLiteConnection - $Version</title>
</installer-gui-script>
"@ | Set-Content -Path "./distribution.xml"

@'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>arch</key>
        <array>
                <string>arm64</string>
                <string>x86_64</string>
        </array>
</dict>
</plist>
'@ | Set-Content -Path "./requirements.plist"

	& productbuild --distribution ./distribution.xml --product requirements.plist --package-path . "$FullName" --sign "Developer ID Installer: $Env:APPLE_DEVELOPER"

	If ( $LastExitCode -ne 0 )
	{
		Exit $LastExitCode
	}
}
finally
{
	foreach ($Name in "root", "$ModuleName.pkg", "distribution.xml", "requirements.plist")
	{
		if (Test-Path "$Name")
		{
			Remove-Item "$Name" -Recurse
		}
	}
}
