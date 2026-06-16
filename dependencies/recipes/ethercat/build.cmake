#********************************************************************************
# Copyright (c) 2026 Sichuan Qunyuan Technology Co., Ltd.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#    Sichuan Qunyuan Technology Co., Ltd. - initial implementation
# *******************************************************************************/
#
# IgH EtherCAT Master — userspace only (no kernel modules). Uses
# --disable-kernel so no Linux kernel tree is required.
#
# Upstream: https://gitlab.com/etherlab.org/ethercat
#
# package.txt downloads the Git tag 1.6.7 archive (not v1.6.7 — see tags page).
# That archive has configure.ac but no pre-generated configure; we run
# ./bootstrap (autoreconf) before configure. Host needs bash, autoconf,
# automake, libtool (e.g. Debian: autoconf automake libtool pkg-config).
#
# To build from a local tree
# instead, replace the first line of package.txt with the absolute path to
# that directory, for example:
#   /path/to/ethercat -X build.cmake
#
# Optional: add a checksum to package.txt after downloading once, e.g.
#   ... -H sha256:<sha256 of the .tar.bz2>
#********************************************************************************

cmake_minimum_required(VERSION 3.10)
project(ethercat C CXX)

set(_ec_prefix "${CMAKE_INSTALL_PREFIX}")

set(AUTOTOOLS_CONFIGURE_OPTIONS
  "--disable-kernel"
  "--disable-initd"
  "--with-systemdsystemunitdir=no"
  "--sysconfdir=${_ec_prefix}/etc"
  "--enable-static"
  "--enable-shared"
)
set(AUTOTOOLS_TARGET "install")

install(DIRECTORY "${CMAKE_INSTALL_PREFIX}/lib/" DESTINATION lib
  USE_SOURCE_PERMISSIONS
  OPTIONAL
  PATTERN "*.la" EXCLUDE
)
install(DIRECTORY "${CMAKE_INSTALL_PREFIX}/include/" DESTINATION include
  USE_SOURCE_PERMISSIONS
  OPTIONAL
)
install(DIRECTORY "${CMAKE_INSTALL_PREFIX}/bin/" DESTINATION bin
  USE_SOURCE_PERMISSIONS
  OPTIONAL
)
install(DIRECTORY "${CMAKE_INSTALL_PREFIX}/sbin/" DESTINATION sbin
  USE_SOURCE_PERMISSIONS
  OPTIONAL
)

include(autotools-build)

find_program(BASH bash REQUIRED)
# compile.sh uses a minimal PATH; autoreconf must come from the host (not the FBE bundle).
if(UNIX AND NOT APPLE)
  set(_ec_hostpath "${TOOLCHAINS_ROOT}/bin:/usr/bin:/bin:/usr/local/bin")
elseif(APPLE)
  set(_ec_hostpath "${TOOLCHAINS_ROOT}/bin:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin")
else()
  set(_ec_hostpath "$ENV{PATH}")
endif()
add_custom_target(ethercat-bootstrap
  COMMAND ${CMAKE_COMMAND} -E env "PATH=${_ec_hostpath}"
    ${BASH} ${CMAKE_CURRENT_SOURCE_DIR}/bootstrap
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMENT "EtherCAT bootstrap (autoreconf)"
  VERBATIM
  USES_TERMINAL
)
add_dependencies(autotools-build ethercat-bootstrap)
