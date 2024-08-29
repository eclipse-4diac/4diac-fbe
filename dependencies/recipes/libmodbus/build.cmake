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

PROJECT(libmodbus C)
CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

add_library(modbus
  src/modbus.c src/modbus-data.c src/modbus-rtu.c src/modbus-tcp.c)
target_include_directories(modbus PRIVATE . src)

install(TARGETS modbus
  DESTINATION lib)
install(FILES src/modbus.h src/modbus-version.h src/modbus-rtu.h src/modbus-tcp.h
  DESTINATION include)

file(READ src/modbus-version.h.in PATCHING)
string(REGEX REPLACE "@LIBMODBUS_VERSION_MAJOR@" "3" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION_MINOR@" "1" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION_MICRO@" "1" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION@" "3.1.1" PATCHING "${PATCHING}")
file(WRITE src/modbus-version.h "${PATCHING}")

if (APPLE)
  file(WRITE config.h "
#define HAVE_DECL_TIOCM_RTS 1
#define HAVE_STRLCPY 1
")
elseif (UNIX)
  file(WRITE config.h "
#define HAVE_BYTESWAP_H 1
#define HAVE_ACCEPT4 1
#define HAVE_DECL_TIOCM_RTS 1
#define HAVE_DECL_TIOCSRS485 1
#define HAVE_STRLCPY 1
")
else ()
  file(WRITE config.h "
#define HAVE_DECL_TIOCM_RTS 0
#define HAVE_DECL_TIOCSRS485 0
#define HAVE_STRLCPY 1
")
endif ()
