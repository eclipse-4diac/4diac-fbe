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

PROJECT(libpcap C)
CMAKE_MINIMUM_REQUIRED(VERSION 2.8.8)

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libpcap.a DESTINATION lib)
install(FILES pcap.h DESTINATION include)
install(FILES pcap/pcap.h DESTINATION include/pcap)
install(FILES ${PROJECT_SOURCE_LIST_H} DESTINATION include/pcap)
