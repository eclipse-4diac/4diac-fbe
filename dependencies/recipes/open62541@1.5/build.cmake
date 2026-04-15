#********************************************************************************
# Copyright (c) 2018, 2026 OFFIS e.V., Primetals Technologies Austria GmbH
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
# 
# Contributors:
#    Jörg Walter - initial implementation
#    Markus Meingast - add support for OPC UA Alarms & Conditions
# *******************************************************************************/
#

cmake_minimum_required(VERSION 3.10)
project(open62541 C CXX)

include(toolchain-utils)

set(Python3_EXECUTABLE ${TOOLCHAINS_ROOT}/bin/python)
# something breaks when running this find_package multiple times
patch(tools/cmake/open62541Macros.cmake "find_package.Python3 REQUIRED." "")


# general configuration
set(UA_ENABLE_AMALGAMATION OFF CACHE BOOL "")
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
  add_definitions("-Wno-error")
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

if (UA_NAMESPACE_ZERO STREQUAL "FULL" OR UA_ENABLE_ALARM_CONDITIONS)
  set(NODESET_DIR "${CMAKE_CURRENT_SOURCE_DIR}/deps/ua-nodeset")
  if (NOT EXISTS "${NODESET_DIR}/Schema/Opc.Ua.NodeSet2.xml")
    message(STATUS "UA_NAMESPACE_ZERO is FULL. Fetching missing UA-Nodeset submodule...")
    set(NODESET_VERSION "UA-1.05.06-2025-11-08") 
    set(NODESET_HASH "c09ba6f1d6b3b293f068417feb8c3f510eaf2d4cb6468d6569bde628bc61f153")
    set(CACHE_DIR "${TOOLCHAINS_ROOT}/download-cache/sha256-${NODESET_HASH}")

    include(toolchain-utils)
    message(STATUS "Downloading extra source...")
    download_extra_source(ua-nodeset ua-nodeset.tar.gz https://github.com/OPCFoundation/UA-Nodeset/archive/refs/tags/${NODESET_VERSION}.tar.gz
    ${NODESET_HASH})

    message(STATUS "Extracting UA-Nodeset...")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E tar xf "${CACHE_DIR}/ua-nodeset.tar.gz"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/deps"
      RESULT_VARIABLE EXTRACT_RESULT
    )

    if(NOT EXTRACT_RESULT EQUAL 0)
      message(FATAL_ERROR "Failed to extract UA-Nodeset!")
    endif()
    file(REMOVE_RECURSE "${NODESET_DIR}")
    file(RENAME "${CMAKE_CURRENT_SOURCE_DIR}/deps/UA-Nodeset-${NODESET_VERSION}" "${NODESET_DIR}")    
    message(STATUS "Successfully extracted UA-Nodeset to ${NODESET_DIR}")
  endif()
endif()

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

install(CODE [=[
  file(GLOB_RECURSE headers
    RELATIVE "${CMAKE_INSTALL_PREFIX}/include"
    LIST_DIRECTORIES FALSE
    "${CMAKE_INSTALL_PREFIX}/include/open62541/*.h")
  list(JOIN headers "\"\n#include \"" header)
  file(WRITE ${CMAKE_INSTALL_PREFIX}/include/open62541.h "#include \"${header}\"")
]=])
