#********************************************************************************
# Copyright (c) 2018, 2023 OFFIS e.V.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#    Jörg Walter - initial implementation
# *******************************************************************************/

cmake_minimum_required(VERSION 3.13)
project(zlib LANGUAGES C VERSION 1.2.11)

option(ZLIB_BUILD_TESTING "Enable Zlib Examples as tests" OFF)
option(ZLIB_BUILD_SHARED "Enable building zlib shared library" OFF)
option(ZLIB_BUILD_STATIC "Enable building zlib static library" ON)
option(ZLIB_INSTALL "Enable installation of zlib" OFF)

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

# use our own install logic to minimize zlib
set_target_properties(zlibstatic PROPERTIES OUTPUT_NAME z)
install(TARGETS zlibstatic EXPORT ${CMAKE_PROJECT_NAME} DESTINATION lib)
install(FILES zlib.h ${CMAKE_CURRENT_BINARY_DIR}/zconf.h DESTINATION include)

include(toolchain-utils)
install_export_config()
