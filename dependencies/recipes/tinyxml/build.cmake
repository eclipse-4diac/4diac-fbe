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
#    Sichuan Qunyuan Technology Co., Ltd. - extend tinyxml build for ethercat ESI parsing
# *******************************************************************************/
#

cmake_minimum_required(VERSION 3.10)
project(tinyxml CXX)

add_library(tinyxml STATIC
  tinyxml.cpp
  tinyxmlerror.cpp
  tinyxmlparser.cpp
  tinystr.cpp
)

target_include_directories(tinyxml
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<INSTALL_INTERFACE:include>
)

install(TARGETS tinyxml
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
)

install(FILES
  tinyxml.h
  tinystr.h
  DESTINATION include
)

# POWERLINK compiles these sources directly from src/tinyxml/
install(FILES
  tinyxml.cpp
  tinyxml.h
  tinyxmlerror.cpp
  tinyxmlparser.cpp
  tinystr.cpp
  tinystr.h
  DESTINATION src/tinyxml
)
