
.data
num_buf: .space 12
output_file: .asciiz "lista_ordenada.txt"
comma: .asciiz ","
input_file:   .asciiz "lista.txt"
buffer:       .space 1024
array:        .space 400
err_open:     .asciiz "Error al abrir archivo\n"
msg_out:      .asciiz "Contenido del archivo:\n"
msg_count:    .asciiz "Total numeros: "
newline:      .asciiz "\n"

.text
.globl main

main:
    # Abrir archivo en modo lectura (flags = 0)
    li $v0, 13
    la $a0, input_file
    li $a1, 0
    syscall
    bltz $v0, error_open
    move $s0, $v0

    # Leer contenido del archivo
    li $v0, 14
    move $a0, $s0
    la $a1, buffer
    li $a2, 1024
    syscall

    # Mostrar mensaje
    li $v0, 4
    la $a0, msg_out
    syscall

    # Mostrar contenido leído
    li $v0, 4
    la $a0, buffer
    syscall

    # Cerrar archivo
    li $v0, 16
    move $a0, $s0
    syscall

    # Parsear números
    jal parse_numbers

    # Guardar array base y cantidad en registros estables
    la $s0, array
    andi $s0, $s0, 0xFFFFFFFC  # asegurar alineación
    move $s1, $t2

    # Ordenar con combsort
    jal combsort

    # Mostrar cantidad de números
    li $v0, 4
    la $a0, msg_count
    syscall
    move $a0, $s1
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    jal print_sorted
jal save_to_file
li $v0, 10
    syscall

error_open:
    li $v0, 4
    la $a0, err_open
    syscall
    jal print_sorted
jal save_to_file
li $v0, 10
    syscall

parse_numbers:
    la $t0, buffer
    la $t1, array
    andi $t1, $t1, 0xFFFFFFFC  # forzar alineación
    andi $t1, $t1, 0xFFFFFFFC  # asegurar alineación
    li $t2, 0

parse_loop:
    lb $t3, 0($t0)
    beqz $t3, end_parse
    li $t4, 0

parse_digit:
    blt $t3, 48, end_digit
    bgt $t3, 57, end_digit
    mul $t4, $t4, 10
    addi $t3, $t3, -48
    add $t4, $t4, $t3
    addi $t0, $t0, 1
    lb $t3, 0($t0)
    j parse_digit

end_digit:
    sw $t4, 0($t1)
    addi $t1, $t1, 4
    addi $t2, $t2, 1
    beqz $t3, end_parse
    addi $t0, $t0, 1
    j parse_loop

end_parse:
    jr $ra

combsort:
    move $t0, $s1     # t0 = n
    li $t1, 1         # swapped = 1
    li $t2, 0         # gap

comb_loop:
    li $t3, 10
    mul $t0, $t0, $t3
    li $t4, 13
    div $t0, $t4
    mflo $t0
    ble $t0, 1, set_gap
    j do_pass

set_gap:
    li $t0, 1

do_pass:
    li $t1, 0     # swapped = 0
    li $t5, 0     # i = 0

pass_loop:
    add $t6, $t5, $t0
    bge $t6, $s1, comb_check

    sll $t7, $t5, 2
    add $t8, $s0, $t7
    lw $t9, 0($t8)

    sll $t7, $t6, 2
    add $t8, $s0, $t7
    lw $t4, 0($t8)

    ble $t9, $t4, skip_swap

    # swap
    sll $t7, $t5, 2
    add $t8, $s0, $t7
    sw $t4, 0($t8)

    sll $t7, $t6, 2
    add $t8, $s0, $t7
    sw $t9, 0($t8)

    li $t1, 1

skip_swap:
    addi $t5, $t5, 1
    j pass_loop

comb_check:
    bgt $t0, 1, comb_loop
    beq $t1, 1, comb_loop
    jr $ra


#############################
# Mostrar arreglo ordenado
#############################
print_sorted:
    li $t0, 0          # índice
    la $t1, array
    andi $t1, $t1, 0xFFFFFFFC  # forzar alineación
    move $t2, $t2      # cantidad ya está en $t2

print_loop:
    bge $t0, $s1, end_print

    sll $t3, $t0, 2
    add $t4, $t1, $t3
    lw $a0, 0($t4)

    li $v0, 1          # imprimir número
    syscall

    li $v0, 4          # salto de línea
    la $a0, newline
    syscall

    addi $t0, $t0, 1
    j print_loop

end_print:
    jr $ra

#############################
# Guardar en archivo ordenado.txt
#############################

save_to_file:
    # Abrir archivo para escritura (flags = 1)
    li $v0, 13
    la $a0, output_file
    li $a1, 1
    syscall
    bltz $v0, error_open
    move $s3, $v0   # fd escritura

    li $t0, 0
    la $t1, array
    andi $t1, $t1, 0xFFFFFFFC  # forzar alineación


save_loop:
    # convertir número a string (decimal)
    sll $t2, $t0, 2
    add $t3, $t1, $t2
    lw $t4, 0($t3)

    # preparar para conversión manual a string decimal
    li $t5, 10
    li $t6, 0
    la $t7, num_buf + 10     # puntero al final del buffer
    li $t8, 0                # contador de dígitos

conv_loop:
    beqz $t4, conv_done
    divu $t4, $t5
    mfhi $t9
    addi $t9, $t9, 48
    subi $t7, $t7, 1
    sb $t9, 0($t7)
    mflo $t4
    addi $t8, $t8, 1
    j conv_loop

conv_done:
    beq $t8, 0, store_zero
    j write_number

store_zero:
    subi $t7, $t7, 1
    li $t9, 48
    sb $t9, 0($t7)
    li $t8, 1

write_number:
    li $v0, 15
    move $a0, $s3
    move $a1, $t7
    move $a2, $t8
    syscall

    # Escribir coma si no es el último
    addi $t0, $t0, 1
    bge $t0, $s1, close_file
    li $v0, 15
    move $a0, $s3
    la $a1, comma
    li $a2, 1
    syscall

    j save_loop
    bge $t0, $s1, close_file

    sll $t2, $t0, 2
    add $t3, $t1, $t2
    lw $t4, 0($t3)

    # Convertir entero a string manualmente (muy simple)
    li $v0, 1
    move $a0, $t4
    syscall

    # Imprimir separador
    li $v0, 4
    la $a0, comma
    syscall

    addi $t0, $t0, 1
    j save_loop

close_file:
    li $v0, 16
    move $a0, $s3
    syscall
    jr $ra
