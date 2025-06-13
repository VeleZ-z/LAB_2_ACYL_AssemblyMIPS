
.data
msg_sorted: .asciiz "Lista ordenada:\n"
.align 2    # Alinea los datos 2^n, en este caso 2^2
input_file:     .asciiz "lista.txt"	# Nombre del archivo de entrada
output_file:    .asciiz "lista_ordenada.txt"	# Nombre del archivo de salida
buffer:         .space 1024	# Nombre del archivo de salida
.align 2
array: .space 400	# Espacio para almacenar los números enteros
msg_out:        .asciiz "Contenido del archivo:\n"
comma:          .asciiz ","	# Separador de números
newline:        .asciiz "\n"	# Nueva línea
num_buf: .space 16	# Buffer para convertir números a string
err_open:       .asciiz "Error al abrir archivo.\n"	# Mensaje de error 

.text
.globl main

main:
    # Abrir archivo de lectura
    li $v0, 13
    la $a0, input_file
    li $a1, 0	# Modo lectura
    syscall
    slt $t9, $v0, $zero   # $t9 = 1 si $v0 < 0
    bne $t9, $zero, open_error	# Si salta al error
    addi $s0, $v0, 0

    # Leer contenido del archivo
    li $v0, 14
    addi $a0, $s0, 0
    la $a1, buffer
    li $a2, 1024
    syscall

    # Imprimir mensaje de contenido
    li $v0, 4
    la $a0, msg_out
    syscall
    li $v0, 4
    la $a0, buffer
    syscall
    li $v0, 4
    la $a0, msg_sorted
    syscall

    # Parsear numeros
    jal parse_numbers
    addi $s1, $t2, 0	# guardar cantidad
    la $s2, array	# Dirección base

    # Ordenar
    jal combsort

    # Mostrar lista ordenada
    li $v0, 4
    syscall
    jal print_sorted

    # Guardar en archivo
    jal save_to_file

    li $v0, 10
    syscall


# Error si no se puede abrir
open_error:
    li $v0, 4
    la $a0, err_open
    syscall
    li $v0, 10
    syscall

# Función: parse_numbers
# Convierte el buffer leído a números
parse_numbers:
    la $t0, buffer
    la $t1, array
    andi $t1, $t1, 0xFFFFFFFC
    li $t2, 0

parse_loop:
    lb $t3, 0($t0)
    li $t8, 0
    beq $t3, $t8, end_parse
    li $t4, 0

parse_digit:
    li $at, 48         # Cargar el valor 48 en un registro temporal ($at)
    slt $at, $t3, $at  # $at = ($t3 < 48) ? 1 : 0
    bne $at, $zero, end_digit
    li $at, 57
    slt $at, $at, $t3
    bne $at, $zero, end_digit
    addi $t5, $zero, 10
    mult $t4, $t5
    mflo $t4
    addi $t3, $t3, -48
    add $t4, $t4, $t3
    addi $t0, $t0, 1
    lb $t3, 0($t0)
    j parse_digit

end_digit:
    sw $t4, 0($t1)
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    li $t8, 0
    beq $t3, $t8, end_parse
    addi $t0, $t0, 1
    j parse_loop

end_parse:
    jr $ra

# Función: combsort
# Ordena el arreglo usando CombSort
combsort:
    li $t0, 1
    addi $t1, $s1, 0
    li $t2, 0       

comb_loop:
    li $t3, 10
    mult $t1, $t3
    mflo $t1
    li $t4, 13
    div $t1, $t4
    mflo $t1
    li $t9, 2
    slt $t9, $t1, $t9
    bne $t9, $zero, set_gap
    j do_pass

set_gap:
    li $t1, 1

do_pass:
    li $t0, 0
    li $t5, 0

pass_loop:
    add $t6, $t5, $t1
    slt $t8, $t6, $s1   # $t8 = 1 si $t6 < $s1
    beq $t8, $zero, comb_check
    sll $t7, $t5, 2
    add $t8, $s2, $t7
    lw $t9, 0($t8)
    sll $t7, $t6, 2
    add $t8, $s2, $t7
    lw $t4, 0($t8)
    slt $t8, $t4, $t9
    beq $t8, $zero, skip_swap

    sll $t7, $t5, 2
    add $t8, $s2, $t7
    sw $t4, 0($t8)
    sll $t7, $t6, 2
    add $t8, $s2, $t7
    sw $t9, 0($t8)
    li $t0, 1

skip_swap:
    addi $t5, $t5, 1
    j pass_loop

comb_check:
    li $at, 1
    slt $at, $at, $t1
    bne $at, $zero, comb_loop
    beq $t0, 1, comb_loop
    jr $ra

# Función: print_sorted
# Imprime los números ordenados
print_sorted:
    li $t0, 0
print_loop:
    slt $t8, $t0, $s1
    beq $t8, $zero, end_print
    sll $t1, $t0, 2
    add $t2, $s2, $t1
    lw $a0, 0($t2)
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall
    addi $t0, $t0, 1
    j print_loop
end_print:
    jr $ra

# Función: save_to_file
# Guarda la lista ordenada en archivo
save_to_file:
    li $v0, 13
    la $a0, output_file
    li $a1, 1
    syscall
    slt $t9, $v0, $zero
    bne $t9, $zero, save_end
    addi $s3, $v0, 0

    li $t0, 0
save_loop:
    slt $t8, $t0, $s1
    beq $t8, $zero, close_file
    sll $t1, $t0, 2
    add $t2, $s2, $t1
    lw $t3, 0($t2)

    li $t4, 10
    li $t5, 0
    la $t6, num_buf
    addi $t6, $t6, 11
    li $t7, 0

conv_loop:
    li $t8, 0
    beq $t3, $t8, conv_done
    divu $t3, $t4
    mfhi $t8
    addi $t8, $t8, 48
    addi $t6, $t6, -1
    sb $t8, 0($t6)
    mflo $t3
    addi $t7, $t7, 1
    j conv_loop

conv_done:
    beq $t7, 0, store_zero
    j write_number

store_zero:
    addi $t6, $t6, -1
    li $t8, 48
    sb $t8, 0($t6)
    li $t7, 1

write_number:
    li $v0, 15
    addi $a0, $s3, 0
    addi $a1, $t6, 0
    addi $a2, $t7, 0
    syscall

    addi $t0, $t0, 1
    slt $t8, $t0, $s1
    beq $t8, $zero, close_file
    li $v0, 15
    addi $a0, $s3, 0
    la $a1, comma
    li $a2, 1
    syscall
    j save_loop

close_file:
    li $v0, 16
    addi $a0, $s3, 0
    syscall
    
save_end:
    jr $ra
