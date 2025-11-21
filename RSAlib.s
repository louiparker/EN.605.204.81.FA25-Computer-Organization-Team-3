# 
# Program Name: RSAlib.s
# Date:  11/19/2025
# 

.text

#
# Function: gcd & modulo
# Author: Ching Yi Cho
#



#
# Function: pow
# Author: Thomson Toms
#



#
# Function: cpubexp
# Author: Parker Loui
# Purpose: calculate and validate public key exponent e
# Requirements:
#	e must be positive integer
#	1 < e < phi(n)
#	gcd( e, phi(n) = 1 ( e and phi(n) are coprime)
# Input: r0 = phi(n) (Euler's totient function result), r1 = e (public exponent)
# Output: r0 = 1 if e is valid, 0 if e is invalid
#

cpubexp:
	# push stack
	SUB sp, sp, #12
	STR r4, [sp, #0]
	STR r5, [sp, #4]
	STR lr, [sp, #8]

	# r4 = phi(n)
	MOV r4, r0

	# r5 = e (proposed exponent)
	MOV r5, r1

	# e must be positive
	CMP r5, #0
	BLE invalid_e

	# e > 1
	CMP r5, #1
	BLE invalid_e

	# e < phi(n)
	CMP r5, r4
	BGE invalid_e

	# gcd( e, phi(n)) must = 1, no common factors (coprime)
	MOV r0, r5
	MOV r1, r4
	BL gcd

	# check if gcd is 1
	CMP r0, #1
	BNE invalid_e

	# all requirement satisfied
	MOV r0, #1
	B end_cpubexp


invalid_e:
	# return false
	MOV r0, #0

end_cpubexp:
	# pop stack for cpubexp
	LDR r4, [sp, #0]
	LDR r5, [sp, #4]
	LDR lr, [sp, #8]
	ADD sp, sp, #12
	MOV pc, lr




#
# Function: cprivexp
# Author: Jiashu Hu
#




.data


