// 
// Program Name: RSAlib.s
// Date:  11/19/2025
// 

.text

//
// Function: gcd & modulo
// Author: Ching Yi Cho
//



//
// Function: pow
// Author: Thomson Toms
//



//
// Function: cpubexp
// Author: Parker Loui
//



// Function: cprivexp
// Author: Jiashu Hu
// Date: November 24, 2025
// Purpose: RSA Math Library - Private Key Exponent and Helpers
// Functions:
// - extended_gcd: Computes GCD(a,b) and coefficients x,y (a*x + b*y = gcd)
//   Inputs: r0 = a, r1 = b
//   Outputs: r0 = gcd, r1 = x (coeff for a), r2 = y (coeff for b)
// - modulo: Computes a % b (positive remainder)
//   Inputs: r0 = a, r1 = b
//   Outputs: r0 = a % b
// - cprivexp: Computes private exponent d = e^{-1} mod φ(n)
//   Inputs: r0 = e, r1 = φ(n)
//   Outputs: r0 = d (or 0 if no inverse/gcd !=1)
// Alterations: r4-r7 temps; stack for lr/r4-r7 (no push/pop)

// extended_gcd: Iterative Extended Euclidean Algorithm
// Using iterative approach to avoid complex recursive register management
// Inputs: r0 = a, r1 = b (a,b >0 assumed)
// Outputs: r0 = gcd, r1 = x (for a), r2 = y (for b)
// Algorithm: Iterative EEA
//   r0=r0, r1=r1 (remainders)
//   s0=1, s1=0 (x coefficients)
//   t0=0, t1=1 (y coefficients)
//   While r1 != 0:
//     q = r0 / r1
//     (r0, r1) = (r1, r0 - q*r1)
//     (s0, s1) = (s1, s0 - q*s1)
//     (t0, t1) = (t1, t0 - q*t1)
//   Return gcd=r0, x=s0, y=t0
.global extended_gcd
extended_gcd:
    SUB sp, sp, #32         // Stack: lr(0), r4(4), r5(8), r6(12), r7(16), r8(20), r9(24), r10(28)
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]
    STR r7, [sp, #16]
    STR r8, [sp, #20]
    STR r9, [sp, #24]
    STR r10, [sp, #28]

    // r4 = r0 (current remainder 0)
    // r5 = r1 (current remainder 1)
    // r6 = s0 = 1
    // r7 = s1 = 0
    // r8 = t0 = 0
    // r9 = t1 = 1
    MOV r4, r0              // r0_val = a
    MOV r5, r1              // r1_val = b
    MOV r6, #1              // s0 = 1
    MOV r7, #0              // s1 = 0
    MOV r8, #0              // t0 = 0
    MOV r9, #1              // t1 = 1

eea_loop:
    CMP r5, #0              // while r1 != 0
    BEQ eea_loop_done

    // q = r0 / r1
    MOV r0, r4
    MOV r1, r5
    BL __aeabi_idiv         // r0 = q = r4 / r5
    MOV r10, r0             // r10 = q

    // temp_r = r0 % r1 = r4 - q * r5
    MUL r0, r10, r5         // r0 = q * r5
    SUB r0, r4, r0          // r0 = r4 - q*r5 = new r1
    MOV r4, r5              // r0 = old r1
    MOV r5, r0              // r1 = temp_r

    // temp_s = s0 - q * s1
    MUL r0, r10, r7         // r0 = q * s1
    SUB r0, r6, r0          // r0 = s0 - q*s1 = new s1
    MOV r6, r7              // s0 = old s1
    MOV r7, r0              // s1 = temp_s

    // temp_t = t0 - q * t1
    MUL r0, r10, r9         // r0 = q * t1
    SUB r0, r8, r0          // r0 = t0 - q*t1 = new t1
    MOV r8, r9              // t0 = old t1
    MOV r9, r0              // t1 = temp_t

    B eea_loop

eea_loop_done:
    // Return: gcd = r4 (final r0), x = r6 (s0), y = r8 (t0)
    MOV r0, r4              // gcd
    MOV r1, r6              // x
    MOV r2, r8              // y

    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR r7, [sp, #16]
    LDR r8, [sp, #20]
    LDR r9, [sp, #24]
    LDR r10, [sp, #28]
    LDR lr, [sp, #0]
    ADD sp, sp, #32
    MOV pc, lr
// END OF extended_gcd

// modulo: a % b using div (handles signed values)
// Inputs: r0 = a, r1 = b
// Outputs: r0 = a % b (always positive when b > 0)
.global modulo
modulo:
    SUB sp, sp, #16
    STR lr, [sp, #0]
    STR r4, [sp, #4]
    STR r5, [sp, #8]
    STR r6, [sp, #12]

    MOV r4, r0              // Save a
    MOV r5, r1              // Save b
    BL __aeabi_idiv         // r0 = a / b (q), truncates toward zero
    MUL r6, r0, r5          // q * b
    SUB r0, r4, r6          // a - q*b = remainder

    // If remainder < 0 and b > 0, add b to make it positive
    CMP r0, #0
    BGE modulo_done
    CMP r5, #0
    BLE modulo_done
    ADD r0, r0, r5          // remainder += b

modulo_done:
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR r6, [sp, #12]
    LDR lr, [sp, #0]
    ADD sp, sp, #16
    MOV pc, lr
// END OF modulo

// cprivexp: e^{-1} mod φ(n) using EEA
// Inputs: r0 = e, r1 = φ(n)
// Outputs: r0 = d (>0), or 0 if no inverse
.global cprivexp
cprivexp:
    SUB sp, sp, #16
    STR lr, [sp, #0]
    STR r4, [sp, #4]        // Save φ(n)
    STR r5, [sp, #8]        // Save x coefficient

    MOV r4, r1              // φ(n) in r4

    BL extended_gcd         // r0=gcd, r1=x (for e), r2=y (unused)

    CMP r0, #1              // gcd==1?
    BNE no_inv

    // d = ((x % φ(n)) + φ(n)) % φ(n) to ensure positive result
    MOV r5, r1              // Save x
    MOV r0, r5              // x to r0
    MOV r1, r4              // φ(n) to r1
    BL modulo               // r0 = x % φ(n)

    // Result from modulo should already be positive (handled in modulo)
    // But double-check: add φ(n) if still negative, then mod again
    CMP r0, #0
    BGE priv_done
    ADD r0, r0, r4          // Add φ(n) if negative
    B priv_done

no_inv:
    MOV r0, #0

priv_done:
    LDR r4, [sp, #4]
    LDR r5, [sp, #8]
    LDR lr, [sp, #0]
    ADD sp, sp, #16
    MOV pc, lr
// END OF cprivexp

// Draft encrypt: m^e mod n (use team's pow)
// Inputs: r0=m, r1=e, r2=n
// Outputs: r0=c
.global encrypt
encrypt:
    // Placeholder: BL pow (m,e) → r0 = m^e
    // Then BL modulo(r0, n)
    MOV pc, lr  // Stub
// END OF encrypt

// Draft decrypt: c^d mod n
// Inputs: r0=c, r1=d, r2=n
// Outputs: r0=m
.global decrypt
decrypt:
    // Similar stub
    MOV pc, lr
// END OF decrypt



.data


