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

project(open62541 C CXX)
cmake_minimum_required(VERSION 2.8.11)

include(toolchain-utils)

set(Python3_EXECUTABLE ${TOOLCHAINS_ROOT}/bin/python)

# general configuration
set(UA_ENABLE_AMALGAMATION ON CACHE BOOL "")
set(UA_ENABLE_NONSTANDARD_STATELESS ON CACHE BOOL "")
set(UA_ENABLE_NONSTANDARD_UDP ON CACHE BOOL "")

set(UA_ENABLE_PUBSUB ON CACHE BOOL "")
if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(UA_ENABLE_PUBSUB_ETH_UADP ON CACHE BOOL "")
elseif (APPLE)
  add_definitions("-DIPV6_ADD_MEMBERSHIP=IPV6_JOIN_GROUP")
  add_definitions("-DIPV6_DROP_MEMBERSHIP=IPV6_LEAVE_GROUP")
endif()
set(UA_ENABLE_PUBSUB_INFORMATIONMODEL ON CACHE BOOL "")
set(UA_ENABLE_PUBSUB_INFORMATIONMODEL_METHODS ON CACHE BOOL "")

set(UA_ENABLE_DETERMINISTIC_RNG ON CACHE BOOL "")
set(UA_ENABLE_ENCRYPTION_OPENSSL ON CACHE BOOL "")

# add mDNS auto-discovery support
# FIXME: somehow the mdnsd commit doesn't contain the required files
# set(UA_ENABLE_DISCOVERY ON CACHE BOOL "")
# set(UA_ENABLE_DISCOVERY_MULTICAST ON CACHE BOOL "")
# add_source(${CMAKE_CURRENT_SOURCE_DIR}/deps/mdnsd mdnsd.zip
#   https://github.com/Pro/mdnsd/archive/3151afe5899dba5125dffa9f4cf3ae1fe2edc0f0.zip
#   f3dd2232c3660b45d9a0a0dbce7433b1bfc48dbf51470793035ca067691ba099)

# build system and code fixes
if (WIN32)
  # # FIXME: UA_THREAD_LOCAL fails on Win32. FORTE does not need UA threads, disable it
  # add_definitions("-D_Thread_local=")
  # add_definitions("-Dthread_local=")
  # add_definitions("-D__thread=")
  add_definitions("-Wno-error")

  # Windows XP compatibility
  patch(arch/win32/ua_architecture.h "_WIN32_WINNT" "_disabled_WIN32_WINNT")
  add_compile_definitions(_WIN32_WINNT=0x0501)
  set(UA_ARCHITECTURE "wec7" CACHE STRING "")

  file(COPY ${CGET_RECIPE_DIR}/inet_pton.h DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/src)
  add_compile_options(-include inet_pton.h -Wno-unused-function)
  # win64 mingw somehow mixes up the exception models
  add_compile_options(-fno-exceptions)
endif()

# intentional omission in libressl API, will be fixed in future open62541 version
add_definitions("\"-DX509_STORE_CTX_get_check_issued(storeCtx)=FIXME_get_check_issued\"")
add_definitions("\"-DFIXME_get_check_issued(storeCtx,a,b)=(X509_check_issued(a,b)==X509_V_OK)\"")

# prevent open62541 trying to be too smart
patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "check_add_cc_flag\\(\"-Werror\"\\)" "")
patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "check_add_cc_flag\\(\"-Wno-static-in-inline\"\\)" "")
patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "CMAKE_INTERPROCEDURAL_OPTIMIZATION" "disabled_CMAKE_INTERPROCEDURAL_OPTIMIZATION")
patch(${CGET_CMAKE_ORIGINAL_SOURCE_FILE} "SANITIZER_FLAGS \"[^\"]*\"" "SANITIZER_FLAGS \"\"")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
