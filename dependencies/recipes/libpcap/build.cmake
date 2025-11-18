#********************************************************************************
# Copyright (c) 2018, 2024 OFFIS e.V.
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
#

cmake_minimum_required(VERSION 3.10)
project(libpcap C)

include(toolchain-utils)

patch(grammar.y.in "YYBYACC" "NO_YYBYACC")
patch(grammar.y.in "YYPATCH" "NO_YYPATCH")
set(YACC_EXECUTABLE ${TOOLCHAINS_ROOT}/bin/byacc)

if (CMAKE_SYSTEM_PROCESSOR STREQUAL aarch64)
    set(CMAKE_OSX_ARCHITECTURES arm64)
else ()
    set(CMAKE_OSX_ARCHITECTURES x86_64)
endif ()

if (WIN32)
  # libpcap is a dependency for openpowerlink. On Win32, openpowerlink does
  # not use libpcap, it accesses WinPCap directly instead. Nothing to do
  # here. It would fail to build anyways.
  return()
endif ()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libpcap.a DESTINATION lib)
install(FILES pcap.h DESTINATION include)
install(FILES pcap/pcap.h DESTINATION include/pcap)
install(FILES ${PROJECT_SOURCE_LIST_H} DESTINATION include/pcap)
