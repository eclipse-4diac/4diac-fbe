#!/bin/sh
echo \" <<'__________________________' >/dev/null ">NUL "
@echo off
REM ********************************************************************************
REM  Copyright (c) 2018, 2025 OFFIS e.V.
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
rem CMD.EXE Batch File
cls

setlocal
set scripts=%~dp0\scripts
%scripts%\run-in-shell.cmd %scripts%\%~n0.sh %*
exit /b
__________________________
# Shell Script
scripts="$(dirname "$0")/scripts"
exec "$scripts/run-in-shell.cmd" "$scripts/$(basename -s .cmd "$0").sh" "$@"
