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

PROJECT(openpowerlink C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.4)

set(CFG_X86_DEMO_MN_CONSOLE ON CACHE BOOL "" FORCE)
set(CFG_X86_DEMO_MN_QT OFF CACHE BOOL "" FORCE)
set(CFG_KERNEL_STACK OFF CACHE BOOL "" FORCE)

set(CFG_POWERLINK_MN ON CACHE BOOL "" FORCE) # master node

add_definitions(-D__sched_priority=sched_priority)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${CGET_PREFIX}/lib")

file(READ EplStack/EplTgtConio.c patching)
string(REGEX REPLACE "#include <unistd.h>" "#include <unistd.h>\n#include <sys/select.h>" patching "${patching}")
file(WRITE EplStack/EplTgtConio.c "${patching}")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

install(DIRECTORY Include DESTINATION src/openpowerlink)
install(DIRECTORY SharedBuff DESTINATION src/openpowerlink)
install(DIRECTORY ObjDicts DESTINATION src/openpowerlink)
install(DIRECTORY EplStack DESTINATION src/openpowerlink)
install(DIRECTORY Examples/X86/Generic/powerlink_user_lib
  DESTINATION src/openpowerlink/Examples/X86/Generic)

if (WIN32)
  install(DIRECTORY Target/X86/Windows/WpdPack
	DESTINATION src/openpowerlink/Target/X86/Windows)
endif()
