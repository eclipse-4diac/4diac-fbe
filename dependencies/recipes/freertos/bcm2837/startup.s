/********************************************************************************
# Copyright (c) 2020, 2024 OFFIS e.V.
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
    .eabi_attribute Tag_ABI_align_preserved, 1
    .arm

.extern	system_init
.extern __bss_start
.extern __bss_end
.extern FreeRTOS_IRQ_Handler
.extern FreeRTOS_SWI_Handler
.extern _start
.extern __fiq_stack
.extern __irq_stack
.extern __supervisor_stack
.extern __system_stack

	.section .boot
	.globl _boot
    .globl __vector_table
;;
_boot:
__vector_table:
	;@ All the following instruction should be read as:
	;@ Load the address at symbol into the program counter.
	
	ldr	pc,reset_handler		;@ 	Processor Reset handler 		-- we will have to force this on the raspi!
	;@ Because this is the first instruction executed, of cause it causes an immediate branch into reset!
	
	ldr pc,undefined_handler	;@ 	Undefined instruction handler 	-- processors that don't have thumb can emulate thumb!
    ldr pc,swi_handler			;@ 	Software interrupt / TRAP (SVC) -- system SVC handler for switching to kernel mode.
    ldr pc,prefetch_handler		;@ 	Prefetch/abort handler.
    ldr pc,data_handler			;@ 	Data abort handler/
    ldr pc,unused_handler		;@ 	-- Historical from 26-bit addressing ARMs -- was invalid address handler.
    ldr pc,irq_handler			;@ 	IRQ handler
    ldr pc,fiq_handler			;@ 	Fast interrupt handler.

	;@ Here we create an exception address table! This means that reset/hang/irq can be absolute addresses
reset_handler:      .word reset
undefined_handler:  .word undefined_instruction
swi_handler:        .word FreeRTOS_SWI_Handler
prefetch_handler:   .word prefetch_abort
data_handler:       .word data_abort
unused_handler:     .word unused
irq_handler:        .word FreeRTOS_IRQ_Handler
fiq_handler:        .word fiq

reset:
	/* Disable IRQ & FIQ */
	cpsid if

     /* disable all cores except the first (for qemu; on a real pi the firmware
     /* does this for us) */
 	mrc	p15, 0, r0, c0, c0, 5
 	and	r0, r0, #15
    cmp	r0, #0
 	beq	checkHYP
disableCore:
 	wfi
 	b	disableCore

checkHYP:
	/* Check for HYP mode */
	mrs r0, cpsr_all
	and r0, r0, #0x1F
	mov r8, #0x1A
	cmp r0, r8
	beq overHyped
	b continueBoot

overHyped: /* Get out of HYP mode */
	ldr r1, =continueBoot
	msr ELR_hyp, r1
	mrs r1, cpsr_all
	and r1, r1, #0x1f	;@ CPSR_MODE_MASK
	orr r1, r1, #0x13	;@ CPSR_MODE_SUPERVISOR
	msr SPSR_hyp, r1
	eret

continueBoot:
	;@	In the reset handler, we need to copy our interrupt vector table to 0x0000, its currently at 0x8000

	mov r0,#0x8000								;@ Store the source pointer
    mov r1,#0x0000								;@ Store the destination pointer.

	;@	Here we copy the branching instructions
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Load multiple values from indexed address. 		; Auto-increment R0
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Store multiple values from the indexed address.	; Auto-increment R1

	;@	So the branches get the correct address we also need to copy our vector table!
    ldmia r0!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Load from 4*n of regs (8) as R0 is now incremented.
    stmia r1!,{r2,r3,r4,r5,r6,r7,r8,r9}			;@ Store this extra set of data.


	;@	Set up the various STACK pointers for different CPU modes
    ;@ (PSR_IRQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD2
    msr cpsr_c,r0
    ldr sp,=__irq_stack

    ;@ (PSR_FIQ_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD1
    msr cpsr_c,r0
    ldr sp,=__fiq_stack

    ;@ (PSR_SYS_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xDF
    msr cpsr_c,r0
    ldr sp,=__system_stack

    ;@ (PSR_SVC_MODE|PSR_FIQ_DIS|PSR_IRQ_DIS)
    mov r0,#0xD3
    msr cpsr_c,r0
    ldr sp,=__supervisor_stack


    ;@ Set CPACR for access to CP10 and 11
    mrc p15,0,r0,c1,c0,2
    orr r0, #0xf00000
    mcr p15, 0, r0, c1, c0, 2
    ;@ Enable FPU
    mov r0, #0x40000000
    vmsr fpexc, r0

    ;@ enable cache
    mov r0, #0
    mcr p15, 0, r0, c7, c7, 0 ;@ invalidate caches
    mcr p15, 0, r0, c8, c7, 0 ;@ invalidate tlb
    mrc p15, 0, r0, c1, c0, 0
    orr r0,r0,#0x1000 ;@ instruction
    orr r0,r0,#0x0004 ;@ data
    orr r0,r0,#0x0800 ;@ branch prediction
    mcr p15, 0, r0, c1, c0, 0

    blx _start                    ;@ pass control to picolibc
    b unused

.section .text

undefined_instruction:
    cpsid if
    mov r11, #'U'
    b crash

prefetch_abort:
    cpsid if
    mov r11, #'P'
    b crash

data_abort:
    cpsid if
	mov r11, #'D'
    b crash

unused:
    cpsid if
	mov r11, #'N'
	b crash

fiq:
    cpsid if
    mov r11, #'F'
	b crash


/******************************************************************************
 * Debug dump functions
 *****************************************************************************/

    ;@ this assumes that no exception occurs until serial_putc was initialised

.macro PUTCONST value
1:
    movw r12, #0x5000
    movt r12, #0x3f21
    ldr r12, [r12, #0x64]
    tst r12, #2
    beq 1b
    mov r12, #(0x5000+\value)
    movt r12, #0x3f21
    str r12, [r12, #(0x40-\value)]
.endm

.macro PUTC reg
1:
    movw r12, #0x5000
    movt r12, #0x3f21
    ldr r12, [r12, #0x64]
    tst r12, #2
    beq 1b
    movw r12, #0x5000
    movt r12, #0x3f21
    str \reg, [r12, #0x40]
.endm

.macro PUTDIGIT reg, n
    lsr r11, \reg, #\n
    and r11, r11, #0xf
    add r11, r11, #'0'
    cmp r11, #'9'
    it gt
    addgt r11, #7
    PUTC r11
.endm

.macro PRINT_REG reg
    PUTCONST '|'
    PUTDIGIT \reg, 28
    PUTDIGIT \reg, 24
    PUTDIGIT \reg, 20
    PUTDIGIT \reg, 16
    PUTDIGIT \reg, 12
    PUTDIGIT \reg, 8
    PUTDIGIT \reg, 4
    PUTDIGIT \reg, 0
    PUTCONST '\r'
    PUTCONST '\n'
.endm

__print_r0:
    PRINT_REG r0
    mov pc, lr

crash:
    PUTCONST '\r'
    PUTCONST '\n'
    PUTCONST '!'
    PUTC r11
    PUTCONST '!'
    PUTCONST '\r'
    PUTCONST '\n'

    PRINT_REG r14
    PRINT_REG r13
    PRINT_REG r0
    mov r0, r1
    bl __print_r0
    mov r0, r2
    bl __print_r0
    mov r0, r3
    bl __print_r0
    mov r0, r4
    bl __print_r0
    mov r0, r5
    bl __print_r0
    mov r0, r6
    bl __print_r0
    mov r0, r7
    bl __print_r0
    mov r0, r8
    bl __print_r0
    mov r0, r9
    bl __print_r0
    mov r0, r10
    bl __print_r0

    mov r0, #0x18
    movw r1, #0x0026
    movt r1, #0x2
    svc 0x123456

hang:
    wfi
    b hang

