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

cmake_minimum_required(VERSION 3.13)
project(picolibc LANGUAGES C VERSION 1.5.1)

include(toolchain-utils)

# Provide dummy sys/reent.h, overriding a potentially installed version from
# newlib. Unfortunately, <cstdlib> from libstdc++ requires this (indirectly). In
# that case, there are no negative consequences as long as it doesn't pick up a
# reent.h from newlib (as shipped with a typical *-none-* toolchain).
file(WRITE reent.h
  "#pragma message \"Someone tried to include <sys/reent.h>. picolibc does not use or provide struct reent. Things may break.\"\n")

# eliminate dummy locking code, because it is difficult to override
file(WRITE newlib/libc/stdlib/mlock.c "")
file(WRITE newlib/libc/misc/lock.c "")

patch(picolibc.specs.in "/%M/" "/") # do not look in multilib subdir for crt0.o
patch(picolibc.specs.in " %{!T:-T@PICOLIBC_LD@} " " ") # do not add liker script
patch(picocrt/crt0.h "memcpy" "(void)") # remove flash->ram data intialisation

# malloc bugfix and some compatibility changes
execute_process(
  COMMAND patch -p1 -i "${CGET_RECIPE_DIR}/bugfix.diff"
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
  RESULT_VARIABLE RC)
if (NOT RC EQUAL 0)
  message(FATAL_ERROR "patch failed")
endif()

add_library(picolibc INTERFACE)
target_link_options(picolibc INTERFACE --specs=picolibc.specs -B${CMAKE_INSTALL_PREFIX}/lib/picolibc)
target_compile_options(picolibc INTERFACE -isystem ${CMAKE_INSTALL_PREFIX}/include/picolibc)

set(MESON_CONFIGURE_OPTIONS -Dspecsdir=lib/picolibc -Dlibdir=lib/picolibc -Dincludedir=include/picolibc -Dtinystdio=true -Dmultilib=false -Dposix-io=false)
include(meson-build)


install(TARGETS picolibc EXPORT picolibc)

install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/install/${CMAKE_INSTALL_PREFIX}/. DESTINATION .)
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/reent.h DESTINATION include/picolibc/sys)

install_export_config()
