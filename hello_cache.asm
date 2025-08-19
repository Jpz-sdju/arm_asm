//------------------------------------------------------------------------------
// The confidential and proprietary information contained in this file may
// only be used by a person authorised under and to the extent permitted
// by a subsisting licensing agreement from Arm Limited or its affiliates.
//
//            (C) COPYRIGHT 2022 Arm Limited or its affiliates.
//                ALL RIGHTS RESERVED
//
// This entire notice must be reproduced on all copies of this file
// and copies of this file may only be made by a person if such person is
// permitted to do so under the terms of a subsisting license agreement
// from Arm Limited or its affiliates.
//
//            Release Information : THEODUL-MP108-r4p0-00rel0
//
//------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
// Description:
//
//   L3 typical power test
//   This tests generates a sequence of accesses that gives similar power to a
//   typical single threaded workload

//`ifdef ARM_INTERNAL
//   This tests attempts to replicate average benchmark performances by reaching the
//   following  metrics:
//              MODEL   TYPCTEST
//   WRITE   :   40%     ~35%
//   READ    :   35%     ~40%
//   STASH   :   20%     ~20%
//   HITRATE :   35%     ~35%
//   ACTIVE_I:   3%     ~ 2%
//`endif
//-------------------------------------------------------------------------------

                .section .text, "ax", %progbits
                .global test_start

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

.equ DEST_ARRAY,        0x05000000     // Pointer to the first-level page table - points to shared memory
.equ STORE_LOOP_SIZE,   1*1024         // Size of consecutive store loop
.equ N_OPS,             120            // Number of operations
.equ MEM_LATENCY,       78             // Memory latency
.equ TRICKBOX_LAT,      0x13000040     // Base address of the trickbox latency register

// Sequence of operations, spread over every 4 iterations
.equ SEQ0, 3
.equ SEQ1, 2
.equ SEQ2, 1
.equ SEQ3, 0

.equ MAX_CHAINS_LOG2, 3
.equ MAX_CHAINS,      (1<<MAX_CHAINS_LOG2)  // Number of chains of operations in different sequences

.ifdef ITERATIONS
  .equ NUM_ITERATIONS, ITERATIONS      // Number of Iterations of the power loop.
.else
  .equ NUM_ITERATIONS, 16
.endif

//------------------------------------------------------------------------------
// Macros
//------------------------------------------------------------------------------

// Macro: MISS_ADDR
// Calculates an address for a chain that starts off with a cache miss
.macro MISS_ADDR xDst, xIter, Sequence, xSrc, Chain
                // Perform a check of the Lower 64 bits
                add     \xDst, \xIter, #\Sequence
                and     \xDst, \xDst, #3
                add     \xDst, \xDst, #\Chain*MAX_CHAINS
                lsl     \xDst, \xDst, #6
                add     \xDst, \xDst, \xSrc
.endm

// Macro: HIT_ADDR
// Calculates an address for a chain that starts off with an L3 cache hit
.macro HIT_ADDR xDst, xIter, Sequence, xSrc, Chain
                lsl     \xDst, \xIter, #6+MAX_CHAINS_LOG2
                add     \xDst, \xDst, #(\Sequence*MAX_CHAINS)<<6
                add     \xDst, \xDst, #(\Chain)<<6
                add     \xDst, \xDst, \xSrc
.endm

//------------------------------------------------------------------------------
// Main test code
//------------------------------------------------------------------------------

aa_ptr: .quad 0xAAAAAAAAAAAAAAAA
prfm_src_data_ptr: .quad test_data

// Entry point
.type test_start, %function
test_start:



jpz_store_storm:
                ldr x5, prfm_src_data_ptr

                mov x1,x5
                add x2, x5 , #131072 

                ldr x3, aa_ptr

store_loop:
                str x3, [x1]
                add x1,x1 , #8


                cmp x1, x2
                b.lt store_loop



                // bl      print

                bl      end_test


//-------------------------------------------------------------------------------
// Subroutines
//-------------------------------------------------------------------------------

                // Routine to stimulate random operations
.type rand_ops, %function
rand_ops:
                mov      w0, #N_OPS
rand_ops_i:
                add      x1, x1, x1
                subs     w0, w0, #0x1
                b.ne     rand_ops_i
                sdiv     x1, x1, x0
                ret


//-------------------------------------------------------------------------------
// Data pool
//-------------------------------------------------------------------------------

                .section .data, "aw", %progbits

                .balign 4
banner_msg:     .asciz "Start L3 typical power test"
end_msg:        .asciz "End  L3 typical power test"
dc_msg:         .asciz "Direct Connect present"
pass_msg:       .asciz "** TEST PASSED OK **\n"
skip_msg:       .asciz "** TEST SKIPPED **\n"

                .balign 4
core_sync:      .word 0
                .balign 8
core_sync1:     .word 0
                .balign 8
core_sync2:     .word 0


.balign 4096
test_data:
    .align 8 
    .rept 512
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678

    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678

    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678


    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678
    .word 0x12345678,0x12345678,0x12345678,0x12345678

    .endr


                .end
