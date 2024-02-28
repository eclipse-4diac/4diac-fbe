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

CMAKE_MINIMUM_REQUIRED(VERSION 2.8.11)

install(FILES tinyxml.cpp tinyxml.h tinyxmlerror.cpp tinyxmlparser.cpp
  tinystr.cpp tinystr.h DESTINATION src/tinyxml)
