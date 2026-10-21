; ==============================================================================
; control_flow.asm - Control de Flujo, Banderas (EFLAGS) y Bucles en x86 (32 bits)
; ------------------------------------------------------------------------------
; Conceptos didácticos:
; 1. El registro EFLAGS:
;    - Instrucciones como 'cmp a, b' realizan internamente una resta (a - b)
;      sin alterar el valor de los operandos; únicamente actualizan EFLAGS.
;    - ZF (Zero Flag): Se activa si el resultado es 0 (indica igualdad: a == b).
;    - SF (Sign Flag): Se activa si el resultado es negativo.
;    - CF (Carry Flag): Indica desbordamiento o acarreo sin signo.
; 2. Saltos condicionales comunes:
;    - je / jz  : Salta si es igual / si ZF = 1
;    - jne / jnz: Salta si no es igual / si ZF = 0
;    - jg / jl  : Salta si mayor / menor (con signo)
;    - jge / jle: Salta si mayor o igual / menor o igual (con signo)
; 3. Bucles en Ensamblador:
;    - Un bucle es un bloque de instrucciones con un contador y un salto
;      condicional que evalúa la condición de permanencia o salida.
; ==============================================================================

section .data
    msg_start       db "[1] Iniciando bucle: sumando del 1 al 5...", 10
    len_start       equ $ - msg_start

    msg_loop_done   db "[2] Bucle completado con exito.", 10
    len_loop_done   equ $ - msg_loop_done

    msg_sum_ge      db "[3] Evaluacion: La suma acumulada es >= 15.", 10
    len_sum_ge      equ $ - msg_sum_ge

    msg_sum_lt      db "[3] Evaluacion: La suma acumulada es < 15.", 10
    len_sum_lt      equ $ - msg_sum_lt

    msg_even        db "[4] Paridad: El numero final es PAR.", 10
    len_even        equ $ - msg_even

    msg_odd         db "[4] Paridad: El numero final es IMPAR.", 10
    len_odd         equ $ - msg_odd

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; 1. Imprimir mensaje de inicio del bucle
    ; --------------------------------------------------------------------------
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, msg_start
    mov edx, len_start
    int 0x80

    ; --------------------------------------------------------------------------
    ; 2. Bucle de suma: 1 + 2 + 3 + 4 + 5 = 15
    ;    Registros:
    ;      ecx: contador (1 a 5)
    ;      eax: acumulador de suma
    ; --------------------------------------------------------------------------
    xor eax, eax                ; eax = 0 (acumulador)
    mov ecx, 1                  ; ecx = 1 (contador inicial)

sum_loop:
    add eax, ecx                ; eax += ecx
    inc ecx                     ; ecx++

    cmp ecx, 5                  ; Compara contador con el límite 5
    jle sum_loop                ; Si ecx <= 5, continúa el ciclo

    ; Guardamos el total de la suma en esi para no perderlo con las syscalls
    mov esi, eax

    ; --------------------------------------------------------------------------
    ; 3. Imprimir confirmación de bucle completado
    ; --------------------------------------------------------------------------
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, msg_loop_done
    mov edx, len_loop_done
    int 0x80

    ; --------------------------------------------------------------------------
    ; 4. Bifurcación condicional: Comparar resultado acumulado con 15
    ; --------------------------------------------------------------------------
    cmp esi, 15                 ; Resta interna (esi - 15) para setear EFLAGS
    jge branch_greater_equal    ; Salta si esi >= 15

branch_less:
    mov ecx, msg_sum_lt
    mov edx, len_sum_lt
    jmp print_comparison

branch_greater_equal:
    mov ecx, msg_sum_ge
    mov edx, len_sum_ge

print_comparison:
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    int 0x80

    ; --------------------------------------------------------------------------
    ; 5. Evaluación de paridad utilizando 'test'
    ;    'test' realiza un AND bitwise sin modificar el registro.
    ;    Si el bit menos significativo (LSB) es 0 -> número PAR (ZF = 1).
    ;    Si el bit menos significativo (LSB) es 1 -> número IMPAR (ZF = 0).
    ; --------------------------------------------------------------------------
    test esi, 1                 ; ¿El bit 0 está encendido?
    jz branch_is_even           ; Si el resultado es cero (ZF = 1) -> es par

branch_is_odd:
    mov ecx, msg_odd
    mov edx, len_odd
    jmp print_parity

branch_is_even:
    mov ecx, msg_even
    mov edx, len_even

print_parity:
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    int 0x80

    ; --------------------------------------------------------------------------
    ; 6. Salir limpiamente
    ; --------------------------------------------------------------------------
    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; código 0
    int 0x80
