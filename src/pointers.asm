; ==============================================================================
; pointers.asm - Aritmética de punteros y manejo de strings en NASM x86 (32 bits)
; ------------------------------------------------------------------------------
; Conceptos didácticos:
; 1. Secciones:
;    - .data: Mensajes estáticos y constantes calculadas con 'equ $ - label'.
;    - .bss: Memoria reservada pero no inicializada con 'resb' (Reserve Byte).
; 2. Punteros en x86:
;    - ESI (Extended Source Index): Puntero de lectura / origen.
;    - EDI (Extended Destination Index): Puntero de escritura / destino.
;    - Desreferenciación: 'byte [esi]' accede al contenido de la memoria.
; 3. Syscalls usadas:
;    - sys_read (eax = 3, ebx = 0 para stdin)
;    - sys_write (eax = 4, ebx = 1 para stdout)
;    - sys_exit (eax = 1)
; 4. Delimitadores en consola:
;    - sys_read no agrega un terminador nulo (0), sino un salto de línea (10 / '\n')
;      al pulsar Enter. Se debe validar 10 ('\n'), 32 (' ') y 0 (EOF / nulo).
; ==============================================================================

section .data
    prompt_msg      db "Ingresa una frase: "
    prompt_len      equ $ - prompt_msg

    result_msg      db "Primera palabra obtenida: "
    result_len      equ $ - result_msg

    newline         db 10
    newline_len     equ $ - newline

section .bss
    BUFFER_SIZE     equ 128
    input_buffer    resb BUFFER_SIZE    ; Buffer de entrada (128 bytes)
    output_buffer   resb BUFFER_SIZE    ; Buffer de salida para el token extraído

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; 1. Imprimir mensaje pidiendo la entrada al usuario (sys_write)
    ; --------------------------------------------------------------------------
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, prompt_msg         ; puntero al mensaje de prompt
    mov edx, prompt_len         ; tamaño del prompt
    int 0x80

    ; --------------------------------------------------------------------------
    ; 2. Leer texto desde el teclado (sys_read)
    ;    Retorna en eax la cantidad de bytes efectivamente leídos.
    ; --------------------------------------------------------------------------
    mov eax, 3                  ; sys_read
    mov ebx, 0                  ; stdin (0)
    mov ecx, input_buffer       ; dirección de almacenamiento
    mov edx, BUFFER_SIZE        ; límite máximo de lectura
    int 0x80

    ; Si no se leyó nada o hubo error (eax <= 0), salimos
    cmp eax, 0
    jle exit_program

    ; --------------------------------------------------------------------------
    ; 3. Extracción de la primera palabra mediante punteros ESI y EDI
    ; --------------------------------------------------------------------------
    mov esi, input_buffer       ; ESI apunta al inicio de la cadena origen
    mov edi, output_buffer      ; EDI apunta al inicio del buffer destino

tokenize_loop:
    mov al, byte [esi]          ; Leer 1 byte desde la memoria apuntada por ESI

    ; Validar condiciones de corte del token:
    cmp al, ' '                 ; ¿Es un espacio?
    je finish_token
    cmp al, 10                  ; ¿Es salto de línea '\n' (tecla Enter)?
    je finish_token
    cmp al, 0                   ; ¿Es fin de cadena / nulo?
    je finish_token

    ; Copiar el carácter al buffer destino
    mov byte [edi], al          ; Escribir el byte en la dirección de EDI
    inc esi                     ; Avanzar puntero origen al siguiente carácter
    inc edi                     ; Avanzar puntero destino

    jmp tokenize_loop           ; Repetir el ciclo

finish_token:
    ; --------------------------------------------------------------------------
    ; 4. Calcular tamaño de la palabra extraída:
    ;    (Dirección actual de EDI) - (Dirección base de output_buffer)
    ; --------------------------------------------------------------------------
    mov edx, edi                ; edx = posición actual del puntero destino
    sub edx, output_buffer      ; edx = bytes totales escritos en output_buffer

    ; Si la palabra está vacía (ej. pulsó Enter de entrada), no imprimimos basura
    cmp edx, 0
    je print_newline_only

    ; Guardamos temporalmente la longitud calculada en el stack
    push edx

    ; --------------------------------------------------------------------------
    ; 5. Imprimir prefijo del resultado
    ; --------------------------------------------------------------------------
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, result_msg
    mov edx, result_len
    int 0x80

    ; --------------------------------------------------------------------------
    ; 6. Imprimir el token extraído
    ; --------------------------------------------------------------------------
    pop edx                     ; Recuperar la longitud calculada del token
    mov eax, 4                  ; sys_write
    mov ebx, 1                  ; stdout
    mov ecx, output_buffer      ; buffer con la palabra extraída
    int 0x80

print_newline_only:
    ; --------------------------------------------------------------------------
    ; 7. Imprimir salto de línea final para mantener limpia la terminal
    ; --------------------------------------------------------------------------
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, newline_len
    int 0x80

exit_program:
    ; --------------------------------------------------------------------------
    ; 8. Terminar ejecución limpiamente (sys_exit con código 0)
    ; --------------------------------------------------------------------------
    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; status 0
    int 0x80
