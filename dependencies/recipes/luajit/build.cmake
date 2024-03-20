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

PROJECT(luajit C)
cmake_minimum_required(VERSION 3.5)

set(HOST_CC gcc)
if (CMAKE_CROSSCOMPILING)
  # When crosscompiling, LuaJIT needs the same bit width for the host compiler
  # as for the target compiler
  set(TARGET_BITS 32)
  if (${CMAKE_SYSTEM_PROCESSOR} MATCHES "(x86_64|aarch64|riscv64)")
    set(TARGET_BITS 64)
  endif()

  file(READ "${TOOLCHAINS_ROOT}/native-toolchain.cmake" native)
  string(REGEX REPLACE ".*/([^-]*)-[^.]*.cmake.*" "\\1" cpu "${native}")
  string(REGEX REPLACE ".*/[^-]*-([^.]*).cmake.*" "\\1" sys "${native}")

  if (${cpu} MATCHES "(x86_64|i686)")
    if (TARGET_BITS EQUAL 32)
      set(host_arch "i686-${sys}")
    else()
      set(host_arch "x86_64-${sys}")
    endif()
  elseif (${CMAKE_SYSTEM_PROCESSOR} MATCHES "(aarch64|arm)")
    if (TARGET_BITS EQUAL 32)
      set(host_arch "arm-${sys}")
    else()
      set(host_arch "aarch64-${sys}")
    endif()
  else ()
    message(FATAL_ERROR "Don't know how to determine appropriate host compiler for this platform")
  endif()
  string(REGEX REPLACE "hf$" "" host_arch "${host_arch}")
  string(REGEX REPLACE "eabi$" "" host_arch "${host_arch}")
  string(REGEX REPLACE "-gnu$" "-musl" host_arch "${host_arch}")
  string(REGEX REPLACE "^arm-linux-musl$" "arm-linux-musleabi" host_arch "${host_arch}")

  set(HOST_CC "${TOOLCHAINS_ROOT}/${host_arch}/bin/${host_arch}-gcc${CMAKE_EXECUTABLE_SUFFIX}")
  if (NOT EXISTS "${HOST_CC}")
    execute_process(COMMAND "${TOOLCHAINS_ROOT}/bin/sh${CMAKE_EXECUTABLE_SUFFIX}" "${TOOLCHAINS_ROOT}/install-crosscompiler.sh" "${host_arch}")
  endif()
  if (NOT EXISTS "${HOST_CC}")
    message(FATAL_ERROR "LUAJit needs a ${host_arch} crosscompiler, which could not be found.")
  endif()
endif()


add_custom_target(build-all ALL
  VERBATIM
  COMMAND make -C src "HOST_CC=${HOST_CC} -static" "PREFIX=${CMAKE_INSTALL_PREFIX}" "TARGET_SYS=${CMAKE_SYSTEM_NAME}" "STATIC_CC=${CMAKE_C_COMPILER}" "TARGET_LD=${CMAKE_C_COMPILER}" "TARGET_AR=${CMAKE_AR} rcus" "TARGET_STRIP=${CMAKE_STRIP}" "CCOPT=${CMAKE_C_FLAGS}" "BUILDMODE=static" "XCFLAGS=-DLUAJIT_DISABLE_FFI"
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

install(DIRECTORY src/jit DESTINATION lib/luajit-2.1 PATTERN *.lua)
install(FILES src/lua.h src/lualib.h src/lauxlib.h src/luaconf.h src/lua.hpp src/luajit.h DESTINATION include)
install(FILES src/libluajit.a DESTINATION lib)
