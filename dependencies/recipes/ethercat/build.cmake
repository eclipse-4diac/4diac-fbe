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
# package.txt downloads the official bootstrapped release tarball from the
# GitLab generic package registry (make dist-bzip2 output). It includes a
# pre-generated configure script, so no autoreconf/bootstrap is needed.
#
# To build from a local tree instead, replace the first line of package.txt
# with the absolute path to that directory, for example:
#   /path/to/ethercat -X build.cmake
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
