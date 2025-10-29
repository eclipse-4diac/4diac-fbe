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
project(boost)

include(toolchain-utils)
patch(libs/stacktrace/include/boost/stacktrace/detail/addr_base_msvc.hpp "std::uintptr_t" "uintptr_t")

include(${CGET_CMAKE_ORIGINAL_SOURCE_FILE})

