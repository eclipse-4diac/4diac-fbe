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

if (WIN32)
	# some ugly hacks for Windows compatibility
	file(WRITE basex-api/src/main/c/err.h [=[
#define warn printf
#define warnx printf
#define err(x,y) do { printf(y); exit(x); } while (0)
#define _POSIX_SOURCE
]=])
	file(WRITE basex-api/src/main/c/netdb.h [=[
#include <ws2tcpip.h>
#ifndef AI_NUMERICSERV
#define AI_NUMERICSERV 0
#endif
]=])
	file(MAKE_DIRECTORY basex-api/src/main/c/sys)
	file(WRITE basex-api/src/main/c/sys/poll.h "")
	file(WRITE basex-api/src/main/c/sys/socket.h "")
endif ()

install(DIRECTORY basex-api/src/main/c/. DESTINATION src/basex)
