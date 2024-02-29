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
toolchains\bin\sh.exe compile.sh %*
popd
if %0 == "%~0" pause
