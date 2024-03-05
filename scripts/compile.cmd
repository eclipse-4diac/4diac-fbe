@echo off
REM ********************************************************************************
REM  Copyright (c) 2018, 2024 OFFIS e.V.
REM 
REM  This program and the accompanying materials are made available under the
REM  terms of the Eclipse Public License 2.0 which is available at
REM  http://www.eclipse.org/legal/epl-2.0.
REM 
REM  SPDX-License-Identifier: EPL-2.0
REM  
REM  Contributors:
REM     Jörg Walter - initial implementation
REM  *******************************************************************************/
REM 
setlocal
pushd %~dp0
if not exist scripts\compile.sh cd ..
set basedir=%cd%
if exist toolchains\bin\sh.exe goto noinstall
	cd toolchains
	call etc\install-Windows.cmd
	cd ..
:noinstall
popd
%basedir%\toolchains\bin\sh.exe %basedir%\scripts\compile.sh %*
if %0 == "%~0" pause
