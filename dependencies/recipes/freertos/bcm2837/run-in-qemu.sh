#!/bin/sh
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

qemu-system-arm -M raspi2b -serial null -serial stdio -monitor null -device usb-net,netdev=net0 -netdev user,id=net0,hostfwd=tcp::61499-:61499 -semihosting -nographic -kernel "$@"
