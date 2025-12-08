// File: JHID_team3_RSA.s
// Course: EN.605.204 Computer Organization
// Team 3
// Author: Noah Schroeder
//
// Main program that calls our RSA library functions.
// Shows the user a simple menu:
// 1. Generate RSA keys
// 2. Encrypt a message and write to encrypted.txt
// 3. Decrypts encrypted.txt and writes to plaintext.txt
// 4. Exit the program
//
// Register Dictionary:
// r0-r3 : arguments and return values
// r4 : p or e or temp
// r5 : q or n or temp
// r6 : n
// r7 : phi(n)
// r8 : file pointer for encrypted.txt
// r9 : file pointer for plaintext.txt
//
// Program loops until user selects "4" to exit.
//

.global main
.text

// MAIN MENU

main:
    sub sp, sp, #4
    str lr, [sp]

menu_start:
    ldr r0, =menu_text
    bl  printf

    ldr r0, =fmt_d
    ldr r1, =menu_choice
    bl  scanf

    ldr r1, =menu_choice
    ldr r1, [r1]

    cmp r1, #1
    beq do_keys

    cmp r1, #2
    beq do_encrypt

    cmp r1, #3
    beq do_decrypt

    cmp r1, #4
    beq exit_program

    b   menu_start


// GENERATE KEYS

do_keys:

    @ ask for p
    ldr r0, =ask_p
    bl printf
    ldr r0, =fmt_d
    ldr r1, =p_val
    bl scanf

    @ ask for q
    ldr r0, =ask_q
    bl printf
    ldr r0, =fmt_d
    ldr r1, =q_val
    bl scanf

    @ load p and q
    ldr r4, =p_val
    ldr r4, [r4]

    ldr r5, =q_val
    ldr r5, [r5]

    @ check prime p
    mov r0, r4
    bl PrimeCheck
    cmp r0, #0
    beq not_prime_error

    @ check prime q
    mov r0, r5
    bl PrimeCheck
    cmp r0, #0
    beq not_prime_error

    @ n = p*q
    mul r6, r4, r5
    ldr r0, =n_val
    str r6, [r0]

    @ phi = (p-1)*(q-1)
    sub r4, r4, #1
    sub r5, r5, #1
    mul r7, r4, r5
    ldr r0, =phi_val
    str r7, [r0]


get_e_loop:
    @ ask for e
    ldr r0, =ask_e
    bl printf

    ldr r0, =fmt_d
    ldr r1, =e_val
    bl scanf

    @ validate e
    @ r0 = phi(n), r1 = e

    ldr r0, =phi_val     @ load phi(n) address
    ldr r0, [r0]         @ r0 = phi(n)

    ldr r1, =e_val       @ load e address
    ldr r1, [r1]         @ r1 = e

    bl cpubexp           @ returns 1 if e is valid


    cmp r0, #1
    bne bad_e

    @ compute d
    ldr r0, =e_val
    ldr r0, [r0]

    ldr r1, =phi_val
    ldr r1, [r1]

    bl cprivexp

    ldr r1, =d_val
    str r0, [r1]

    @ done
    ldr r0, =keys_ok
    bl printf
    b menu_start


not_prime_error:
    ldr r0, =prime_error
    bl printf
    b menu_start


bad_e:
    ldr r0, =bad_e_msg
    bl printf
    b get_e_loop

// ENCRYPT MESSAGE

do_encrypt:
    ldr r0, =ask_msg
    bl  printf

    ldr r0, =fmt_msg
    ldr r1, =msg_buf
    bl  scanf

    ldr r0, =enc_file
    ldr r1, =mode_w
    bl  fopen
    mov r8, r0

    cmp r8, #0
    beq encrypt_done

    ldr r4, =e_val
    ldr r4, [r4]

    ldr r5, =n_val
    ldr r5, [r5]

    ldr r6, =msg_buf

encrypt_loop:
    ldrb r7, [r6]
    cmp  r7, #0
    beq  encrypt_done

    mov r0, r7
    mov r1, r4
    mov r2, r5
    bl  encrypt

    mov r2, r0
    mov r0, r8
    ldr r1, =fmt_cipher
    bl  fprintf

    add r6, r6, #1
    b   encrypt_loop

encrypt_done:
    cmp r8, #0
    beq enc_skip_close
    mov r0, r8
    bl  fclose

enc_skip_close:
    ldr r0, =enc_done_msg
    bl  printf

    b menu_start


// DECRYPT MESSAGE

do_decrypt:
    @ open encrypted.txt (read)
    ldr r0, =enc_file
    ldr r1, =mode_r
    bl fopen
    mov r8, r0          @ file handle (encrypted)

    @ load d and n
    ldr r4, =d_val
    ldr r4, [r4]
    ldr r5, =n_val
    ldr r5, [r5]

    @ open plaintext.txt (write)
    ldr r0, =plain_file
    ldr r1, =mode_w
    bl fopen
    mov r9, r0          @ file handle (plaintext)

decrypt_loop:
    @ read one ciphertext integer: fscanf(enc, "%d", &cipher_temp)
    ldr r0, =fmt_cipher
    ldr r1, =cipher_temp
    mov r2, r8
    bl fscanf

    @ stop if fscanf did not read 1 integer
    cmp r0, #1
    bne decrypt_done

    @ load ciphertext value, decrypt it
    ldr r0, =cipher_temp
    ldr r0, [r0]
    mov r1, r4          @ d
    mov r2, r5          @ n
    bl decrypt          @ returns plaintext char in r0

    @ write plaintext char to file
    mov r0, r9
    ldr r1, =fmt_char
    mov r2, r0
    bl fprintf

    b decrypt_loop

decrypt_done:
    @ close both files
    mov r0, r8
    bl fclose
    mov r0, r9
    bl fclose

    @ print "Decrypted."
    ldr r0, =dec_done_msg
    bl printf

    b menu_start


// EXIT HANDLER

exit_program:
    ldr lr, [sp]
    add sp, sp, #4
    mov r0, #0
    bx lr

// FLUSH FOR SCANF

flush_stdin:
    mov r0, #0
flush_loop:
    bl getchar
    cmp r0, #10
    beq flush_end
    cmp r0, #-1
    beq flush_end
    b flush_loop

flush_end:
    mov pc, lr

// DATA

.data

menu_text:     .asciz "\n1) Generate Keys\n2) Encrypt Message\n3) Decrypt Message\n4) Exit\nChoice: "
fmt_d:         .asciz "%d"
menu_choice:   .word 0

ask_p:         .asciz "Enter p: "
ask_q:         .asciz "Enter q: "
ask_e:         .asciz "Enter e: "
prime_error:   .asciz "Not prime.\n"
bad_e_msg:     .asciz "Invalid e.\n"
keys_ok:       .asciz "Keys generated.\n"

ask_msg:       .asciz "Enter message: "
fmt_msg:       .asciz "%127s"
msg_buf:       .space 128

p_val:   .word 0
q_val:   .word 0
e_val:   .word 0
phi_val: .word 0
n_val:   .word 0
d_val:   .word 0

enc_file:    .asciz "encrypted.txt"
plain_file:  .asciz "plaintext.txt"
mode_w:      .asciz "w"
mode_r:      .asciz "r"

fmt_cipher:  .asciz "%d "
cipher_temp: .word 0
fmt_char:    .asciz "%c"

enc_done_msg: .asciz "Encrypted.\n"
dec_done_msg: .asciz "Decrypted.\n"

msg_val:     .word 0      @ stores plaintext integer m
enc_val:     .word 0      @ stores ciphertext integer c
