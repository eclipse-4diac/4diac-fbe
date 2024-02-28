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
project(freertos LANGUAGES C CXX ASM VERSION 202012.00)
include(toolchain-utils)

###############################################################

set(FREERTOS_CONFIG "" CACHE STRING
  "CMake file containing platform library, absolute or relative to recipe dir")

###############################################################

# helper function that makes working with globs more convenient
function(freertos_autosrc var)
  set(srcs)
  foreach (arg IN LISTS ARGN)
    get_filename_component(absarg "${arg}" ABSOLUTE)
    if (IS_DIRECTORY "${absarg}")
      message(STATUS "- source dir ${arg}")
      file(GLOB files LIST_DIRECTORIES false CONFIGURE_DEPENDS "${absarg}/*.[cS]")
      list(APPEND srcs ${files})
    elseif (EXISTS "${absarg}")
      message(STATUS "- source file ${absarg}")
      list(APPEND srcs ${absarg})
    else ()
      message(STATUS "- source glob ${absarg}")
      file(GLOB files LIST_DIRECTORIES false CONFIGURE_DEPENDS "${absarg}")
      list(APPEND srcs ${files})
    endif()
  endforeach()
  set(${var} ${srcs} PARENT_SCOPE)
endfunction()

if (NOT FREERTOS_CONFIG)
  message(FATAL_ERROR "FREERTOS_CONFIG is unset")
endif()
include("${CGET_RECIPE_DIR}/${FREERTOS_CONFIG}/build-${FREERTOS_CONFIG}.cmake")

freertos_autosrc(freertos-core
  "FreeRTOS/Source"
  "${CGET_RECIPE_DIR}/common/heap_newlib.c"
  )
add_library(freertos-core STATIC ${freertos-core})
target_link_libraries(freertos-core PUBLIC freertos-platform)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Source/include/.
  DESTINATION include/FreeRTOS)


freertos_autosrc(freertos-plus-cli
  "FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI")
add_library(freertos-plus-cli STATIC ${freertos-plus-cli})
target_link_libraries(freertos-plus-cli PUBLIC freertos-core)
target_include_directories(freertos-plus-cli PUBLIC
  "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS>"
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI>")
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI/FreeRTOS_CLI.h
  DESTINATION include/FreeRTOS)

if (TCP)
  freertos_autosrc(freertos-plus-tcp
    "FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP"
    "FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/portable/BufferManagement/BufferAllocation_2.c"
    )
  add_library(freertos-plus-tcp STATIC ${freertos-plus-tcp})
  target_link_libraries(freertos-plus-tcp PUBLIC freertos-core freertos-plus-tcp-platform)
  target_include_directories(freertos-plus-tcp PUBLIC
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/include>")
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/include/.
    DESTINATION include/FreeRTOS)
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS-Plus/Source/FreeRTOS-Plus-TCP/portable/Compiler/GCC/.
    DESTINATION include/FreeRTOS)
  install(TARGETS freertos-plus-tcp EXPORT freertos DESTINATION lib)
endif()

if (LWIP)
  freertos_autosrc(freertos-lwip
    "FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/*/*.c"
    "FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/core/ipv4/*.c")
  add_library(freertos-lwip STATIC ${freertos-lwip})
  target_link_libraries(freertos-lwip PUBLIC freertos-lwip-platform)
  target_include_directories(freertos-lwip PUBLIC
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS/lwip>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_PREFIX}/include/FreeRTOS/lwip/ipv4>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/include>"
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/include/ipv4>")
  install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/Demo/Common/ethernet/lwip-1.4.0/src/include/.
    DESTINATION include/FreeRTOS/lwip)
  install(TARGETS freertos-lwip EXPORT freertos DESTINATION lib)
endif()

install(TARGETS freertos-core freertos-plus-cli EXPORT freertos DESTINATION lib)

include(demoapp)

install_export_config()
