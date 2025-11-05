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

cmake_minimum_required(VERSION 3.10)
project(openpowerlink C)

include(toolchain-utils)

if (WIN32)
  patch(Include/global.h "__GNUC__" "__DISABLED_GNUC__")
  patch(SharedBuff/ShbIpc-Win32.c "sharedbuff\\.h" "SharedBuff.h")
  patch(SharedBuff/ShbIpc-Win32.c "shbipc\\.h" "ShbIpc.h")
  add_compile_definitions("QWORD=long long int")
  add_compile_definitions(TARGET_SYSTEM=_WIN32_)
  add_compile_definitions(DEV_SYSTEM=_DEV_WIN32_)
  set(CFG_X86_WINDOWS_DLL OFF CACHE BOOL "" FORCE)
elseif (APPLE)
  # not supported on APPLE, and 4diac FORTE doesn't use this on APPLE, so just
  # pretend this is installed
  message(WARNING "Not supported on APPLE, not building or installing anything")
  return()
endif ()

set(CFG_X86_DEMO_CN_CONSOLE OFF CACHE BOOL "" FORCE)
set(CFG_X86_DEMO_MN_CONSOLE OFF CACHE BOOL "" FORCE)
set(CFG_X86_DEMO_MN_QT OFF CACHE BOOL "" FORCE)
set(CFG_KERNEL_STACK OFF CACHE BOOL "" FORCE)

set(CFG_POWERLINK_MN ON CACHE BOOL "" FORCE) # master node

add_definitions(-D__sched_priority=sched_priority)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L${CGET_PREFIX}/lib")

patch(EplStack/EplTgtConio.c "#include <unistd.h>" "#include <unistd.h>\n#include <sys/select.h>")

set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
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
