@@REM ********************************************************************************
@@REM  Copyright (c) 2018, 2024 OFFIS e.V.
@@REM 
@@REM  This program and the accompanying materials are made available under the
@@REM  terms of the Eclipse Public License 2.0 which is available at
@@REM  http://www.eclipse.org/legal/epl-2.0.
@@REM 
@@REM  SPDX-License-Identifier: EPL-2.0
@@REM  
@@REM  Contributors:
@@REM     Jörg Walter - initial implementation
@@REM  *******************************************************************************
@@REM 
@@cd %~dp0 & %WINDIR%\system32\windowspowershell\v1.0\powershell.exe -Command Invoke-Expression $([String]::Join(';',(Get-Content 'install.cmd') -notmatch '^^@@.*$')) & goto :EOF

"Checking installation..."

if (Test-Path "compile.cmd") {
	"This is already installed."
	Read-Host -Prompt "Press Enter to exit"
	exit
}

$curdir = "" + (Get-Location)
if ($curdir -like "* *") {
	""
	"======================================================================"
	""
	"ERROR: You cannot install this in a path that contains a space character."
	"       Please use a different path."
	""
	"======================================================================"
	""
	Read-Host -Prompt "Press Enter to exit"
	exit
}

if ($curdir.Length -gt (256-170)) {
	""
	"======================================================================"
	""
	"WARNING: Some systems can't run this from a deeply nested path."
	"         If you get errors later on, please use a shorter installation path."
	""
	"======================================================================"
	""
	Read-Host -Prompt "Press Ctrl-C to exit, or press Enter to continue at your own risk"
}


if (-not (Test-Path runtime-20*-*-*_*.*.zip)) {
	""
	"======================================================================"
	""
	"ERROR: Copy all runtime files and the Windows subdirectory to an empty folder"
	"       and run this script again."
	""
	"======================================================================"
	""
	Read-Host -Prompt "Press Enter to exit"
	exit
}

if (-not (Test-Path "Windows\Windows-toolchain-x86_64-w64-mingw32.zip")) {
	""
	"======================================================================"
	""
	"ERROR: You need a base toolchain archive to install. You should get it"
	"       wherever you got this file.  The file you need is called"
	"       Windows\Windows-toolchain-x86_64-w64-mingw32.zip"
	""
	"======================================================================"
	""
	Read-Host -Prompt "Press Enter to exit"
	exit
}

"Extracting runtime build environment..."
$fn = Get-ChildItem runtime-20*-*-*_*.*.zip
$arch = [System.IO.Path]::Combine($PWD, $fn)
$shap = New-Object -com Shell.Application
$src = $shap.NameSpace($arch)
$dest = $shap.NameSpace("$PWD\")
$dest.CopyHere($src.Items(), 24)

Move-Item -Path .\Windows\* -Destination .\toolchains
Remove-Item -Path Windows
Start-Process "toolchains\install-toolchain.cmd" -ArgumentList "`"`"" -Wait -NoNewWindow

"Finishing installation..."
Copy-Item -Path scripts\compile.cmd -Destination .
Start-Process "compile.cmd" -ArgumentList "`"`"" -Wait -NoNewWindow

""
""
Read-Host -Prompt "Press Enter to exit"
