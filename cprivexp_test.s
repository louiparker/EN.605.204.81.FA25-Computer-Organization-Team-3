// File: test_main.s
// Author: Jiashu Hu
// Date: November 24, 2025
// Purpose: Interactive test for cprivexp - accepts user input
// This is also an example how to use it
// Inputs: User enters e and φ(n) from keyboard
// Outputs: Prints computed private exponent d

.data
prompt_e:    .asciz "Enter public exponent e: "
prompt_phi:  .asciz "Enter phi(n): "
input_fmt:   .asciz "%d"
result_fmt:  .asciz "Private exponent d = %d\n"
verify_fmt:  .asciz "Verification: e * d mod phi(n) = %d * %d mod %d = %d\n"
error_fmt:   .asciz "Error: No modular inverse exists (gcd != 1)\n"
e_val:       .word 0
phi_val:     .word 0

.text
.global main
main:
    SUB sp, sp, #16
    STR lr, [sp, #0]
    STR r4, [sp, #4]        // Save r4 for e
    STR r5, [sp, #8]        // Save r5 for phi
    STR r6, [sp, #12]       // Save r6 for d

    // Prompt for e
    LDR r0, =prompt_e
    BL printf

    // Read e
    LDR r0, =input_fmt
    LDR r1, =e_val
    BL scanf
    LDR r0, =e_val
    LDR r4, [r0]            // r4 = e

    // Prompt for phi(n)
    LDR r0, =prompt_phi
    BL printf

    // Read phi(n)
    LDR r0, =input_fmt
    LDR r1, =phi_val
    BL scanf
    LDR r0, =phi_val
    LDR r5, [r0]            // r5 = phi(n)

    // Call cprivexp(e, phi)
    MOV r0, r4              // e
    MOV r1, r5              // phi(n)
    BL cprivexp             // r0 = d
    MOV r6, r0              // r6 = d

    // Check if inverse exists
    CMP r6, #0
    BEQ no_inverse

    // Print result
    LDR r0, =result_fmt
    MOV r1, r6
    BL printf

    // Verification: compute (e * d) % phi
    // First compute e * d
    MUL r0, r4, r6          // r0 = e * d
    MOV r1, r5              // r1 = phi(n)
    BL modulo               // r0 = (e * d) % phi

    // Print verification
    STR r0, [sp, #-4]!      // Push result onto stack for printf
    LDR r0, =verify_fmt
    MOV r1, r4              // e
    MOV r2, r6              // d
    MOV r3, r5              // phi
    BL printf
    ADD sp, sp, #4          // Pop stack

    B done

no_inverse:
    LDR r0, =error_fmt
    BL printf

done:
    MOV r0, #0              // return 0
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR lr, [sp, #0]
    ADD sp, sp, #16
    MOV pc, lr
// END main
