#********************************************************************************
# Copyright (c) 2026 Sichuan Qunyuan Technology Co., Ltd.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#    Sichuan Qunyuan Technology Co., Ltd. - initial implementation
# *******************************************************************************/
#
# {fmt} — https://github.com/fmtlib/fmt
#
# Upstream uses project(FMT CXX); cget expects the recipe folder name to match
# CMAKE_PROJECT_NAME, so we keep project(fmt) and strip the duplicate from the
# vendored CMakeLists.
#********************************************************************************

cmake_minimum_required(VERSION 3.10)
project(fmt CXX)

include(toolchain-utils)

set(FMT_MASTER_PROJECT ON CACHE BOOL "")
set(FMT_DOC OFF CACHE BOOL "")
set(FMT_TEST OFF CACHE BOOL "")
set(FMT_INSTALL ON CACHE BOOL "")
set(FMT_MODULE OFF CACHE BOOL "")
set(FMT_FUZZ OFF CACHE BOOL "")

patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "^cmake_minimum_required\\([^)]*\\)\r?\n" "")
patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "\nproject\\(FMT[ ]+CXX\\)\\s*\r?\n" "\n")
include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
