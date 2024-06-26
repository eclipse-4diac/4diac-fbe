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
project(freertos-cpp11 LANGUAGES C CXX VERSION 0.0.20210419)

include(toolchain-utils)

find_package(freertos REQUIRED)

add_library(freertos-cpp11
  FreeRTOS/cpp11_gcc/freertos_time.cpp
  FreeRTOS/cpp11_gcc/gthr_key.cpp
  FreeRTOS/cpp11_gcc/thread.cpp

  ${CGET_RECIPE_DIR}/extra.cpp
  )
target_link_libraries(freertos-cpp11 PUBLIC freertos::freertos-core)
target_link_options(freertos-cpp11 INTERFACE  -Wl,--undefined=__override_libstdcpp_hack)
target_compile_definitions(freertos-cpp11 PUBLIC -D_GLIBCXX_HAS_GTHREADS=1)
target_compile_definitions(freertos-cpp11 PUBLIC -DpdTICKS_TO_MS=)
target_include_directories(freertos-cpp11 PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/FreeRTOS/cpp11_gcc)

install(TARGETS freertos-cpp11
  EXPORT freertos-cpp11
  DESTINATION lib)

install_export_config()
