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

# Copyright (C) 2007-2009 LuaDist.
# Submitted by David Manura
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

cmake_minimum_required(VERSION 3.13)
project(bzip2 LANGUAGES C VERSION 1.0.6)

# Where to install module parts:
set(INSTALL_BIN bin CACHE PATH "Where to install binaries to.")
set(INSTALL_LIB lib CACHE PATH "Where to install libraries to.")
set(INSTALL_INC include CACHE PATH "Where to install headers to.")
set(INSTALL_ETC etc CACHE PATH "Where to store configuration files")
set(INSTALL_DATA share/${PROJECT_NAME} CACHE PATH "Directory the package can store documentation, tests or other data in.")
set(INSTALL_DOC ${INSTALL_DATA}/doc CACHE PATH "Recommended directory to install documentation into.")
set(INSTALL_EXAMPLE ${INSTALL_DATA}/example CACHE PATH "Recommended directory to install examples into.")
set(INSTALL_TEST ${INSTALL_DATA}/test CACHE PATH "Recommended directory to install tests into.")
set(INSTALL_FOO ${INSTALL_DATA}/etc CACHE PATH "Where to install additional files")


# In MSVC, prevent warnings that can occur when using standard libraries.
if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
endif(MSVC)

add_definitions(-D_FILE_OFFSET_BITS=64)

file(READ bzip2.c FDATA)
string(REPLACE "sys\\stat.h" "sys/stat.h" FDATA "${FDATA}")
file(WRITE bzip2.c "${FDATA}")

# Library
set(BZIP2_SRCS blocksort.c huffman.c crctable.c randtable.c
               compress.c decompress.c bzlib.c )

add_library(bz2 ${BZIP2_SRCS})

add_executable(bzip2 bzip2.c)
target_link_libraries(bzip2 bz2)

add_EXECUTABLE(bzip2recover bzip2recover.c)

install(TARGETS bzip2 bzip2recover bz2 EXPORT ${CMAKE_PROJECT_NAME}
  RUNTIME DESTINATION ${INSTALL_BIN} LIBRARY DESTINATION ${INSTALL_LIB} ARCHIVE DESTINATION ${INSTALL_LIB})
install(FILES bzlib.h DESTINATION ${INSTALL_INC})
install(PROGRAMS bzgrep bzmore bzdiff DESTINATION ${INSTALL_BIN}) #~2DO: windows versions?

#TODO: improve with symbolic links
install(PROGRAMS $<TARGET_FILE:bzip2> DESTINATION ${INSTALL_BIN} RENAME bunzip2)
install(PROGRAMS $<TARGET_FILE:bzip2> DESTINATION ${INSTALL_BIN} RENAME bzcat)
install(PROGRAMS bzgrep DESTINATION ${INSTALL_BIN} RENAME bzegrep)
install(PROGRAMS bzgrep DESTINATION ${INSTALL_BIN} RENAME bzfgrep)
install(PROGRAMS bzmore DESTINATION ${INSTALL_BIN} RENAME bzless)
install(PROGRAMS bzdiff DESTINATION ${INSTALL_BIN} RENAME bzcmp)

#TODO? build manual.ps and manual.pdf

include(toolchain-utils)
install_export_config()
