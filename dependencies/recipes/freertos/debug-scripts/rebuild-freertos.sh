#!/usr/bin/env bash
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


cd "$(dirname "$0")/.."
make -C dependencies/rpi/rooperl-RaspberryPi-FreeRTOS
./toolchains/bin/cget -p cget/freertos-raspi3 remove freertos 2>/dev/null
./toolchains/bin/cget -p cget/freertos-raspi3 remove freertos-cpp11 2>/dev/null
exec ./compile.sh freertos-raspi3
