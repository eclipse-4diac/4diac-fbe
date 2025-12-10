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
project(libmodbus C)

include(toolchain-utils)

patch(src/modbus-tcp.c "#ifdef HAVE_NETINET_IN_H" "#include <config.h>\n#ifdef HAVE_NETINET_IN_H")

add_library(modbus
  src/modbus.c src/modbus-data.c src/modbus-rtu.c src/modbus-tcp.c)
target_include_directories(modbus PRIVATE . src)
target_compile_options(modbus PRIVATE -Wno-incompatible-pointer-types)

install(TARGETS modbus
  DESTINATION lib)
install(FILES src/modbus.h src/modbus-version.h src/modbus-rtu.h src/modbus-tcp.h
  DESTINATION include/modbus)

file(READ src/modbus-version.h.in PATCHING)
string(REGEX REPLACE "@LIBMODBUS_VERSION_MAJOR@" "3" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION_MINOR@" "1" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION_MICRO@" "1" PATCHING "${PATCHING}")
string(REGEX REPLACE "@LIBMODBUS_VERSION@" "3.1.1" PATCHING "${PATCHING}")
file(WRITE src/modbus-version.h "${PATCHING}")

if (APPLE)
  file(WRITE config.h "
#define HAVE_ARPA_INET_H 1
#define HAVE_BYTESWAP_H 1
#define HAVE_DECL_TIOCM_RTS 1
//#define HAVE_DECL_TIOCSRS485 1
#define HAVE_DLFCN_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_GAI_STRERROR 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_INET_NTOP 1
#define HAVE_INET_PTON 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LINUX_SERIAL_H 1
#define HAVE_MEMORY_H 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETINET_IP_H 1
#define HAVE_NETINET_TCP_H 1
#define HAVE_SELECT 1
#define HAVE_SOCKET 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRERROR 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_STRLCPY 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_TIME_H 1
#define HAVE_UNISTD_H 1
#define STDC_HEADERS 1
#define _GNU_SOURCE 1
")
elseif (UNIX)
  file(WRITE config.h "
#define HAVE_ARPA_INET_H 1
#define HAVE_BYTESWAP_H 1
#define HAVE_DECL_TIOCM_RTS 1
#define HAVE_DECL_TIOCSRS485 1
#define HAVE_DLFCN_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_GAI_STRERROR 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_INET_NTOP 1
#define HAVE_INET_PTON 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LINUX_SERIAL_H 1
#define HAVE_MEMORY_H 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETINET_IP_H 1
#define HAVE_NETINET_TCP_H 1
#define HAVE_SELECT 1
#define HAVE_SOCKET 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRERROR 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
#define HAVE_STRLCPY 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_TIME_H 1
#define HAVE_UNISTD_H 1
#define STDC_HEADERS 1
#define _GNU_SOURCE 1
")
elseif (WIN32)
  target_compile_options(modbus PRIVATE -include ${CGET_RECIPE_DIR}/inet_pton.h -Wno-unused-function)
  file(WRITE config.h "
#define HAVE_ARPA_INET_H 1
#define HAVE_BYTESWAP_H 1
//#define HAVE_DECL_TIOCM_RTS 1
//#define HAVE_DECL_TIOCSRS485 1
#define HAVE_DLFCN_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_GAI_STRERROR 1
#define HAVE_GETADDRINFO 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_INET_NTOP 1
#define HAVE_INET_PTON 1
#define HAVE_INTTYPES_H 1
#define HAVE_LIMITS_H 1
#define HAVE_LINUX_SERIAL_H 1
#define HAVE_MEMORY_H 1
#define HAVE_NETDB_H 1
#define HAVE_NETINET_IN_H 1
#define HAVE_NETINET_IP_H 1
#define HAVE_NETINET_TCP_H 1
#define HAVE_SELECT 1
#define HAVE_SOCKET 1
#define HAVE_STDINT_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRERROR 1
#define HAVE_STRINGS_H 1
#define HAVE_STRING_H 1
//#define HAVE_STRLCPY 1
#define HAVE_SYS_IOCTL_H 1
#define HAVE_SYS_SOCKET_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_TERMIOS_H 1
#define HAVE_TIME_H 1
#define HAVE_UNISTD_H 1
#define STDC_HEADERS 1
#define _GNU_SOURCE 1
")
endif ()
