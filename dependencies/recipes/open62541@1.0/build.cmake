cmake_minimum_required(VERSION 3.10)

set(UA_ENABLE_AMALGAMATION ON CACHE BOOL "")
set(UA_ENABLE_NONSTANDARD_STATELESS ON CACHE BOOL "")
set(UA_ENABLE_NONSTANDARD_UDP ON CACHE BOOL "")

set(UA_ENABLE_PUBSUB ON CACHE BOOL "")
if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
  set(UA_ENABLE_PUBSUB_ETH_UADP ON CACHE BOOL "")
endif()
set(UA_ENABLE_PUBSUB_INFORMATIONMODEL ON CACHE BOOL "")
set(UA_ENABLE_PUBSUB_INFORMATIONMODEL_METHODS ON CACHE BOOL "")

set(UA_ENABLE_DETERMINISTIC_RNG ON CACHE BOOL "")

# FIXME: UA_THREAD_LOCAL fails on Win32. FORTE does not need threads, disable it
add_definitions("-D_Thread_local=")
add_definitions("-Dthread_local=")
add_definitions("-D__thread=")
add_definitions("-Wno-error")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})
