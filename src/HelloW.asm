; ==============================================================================
; HelloW.asm - Introducción básica a NASM en Linux x86 (32 bits)
; ------------------------------------------------------------------------------
; Conceptos didácticos:
; 1. Secciones: .data (datos inicializados), .text (código ejecutable).
; 2. Syscalls Linux x86 vía interrupción 0x80:
;    - eax: Número de syscall (4 = sys_write, 1 = sys_exit)
;    - ebx: 1er argumento (fd: 1 = stdout, o código de salida)
;    - ecx: 2do argumento (puntero al buffer en memoria)
;    - edx: 3er argumento (longitud en bytes)
; 3. Directiva 'equ $ - label': calcula la longitud exacta en tiempo de ensamblado.
; ==============================================================================

section .data
    message db 'Hola, mundo!', 10       ; 10 = LF (\n)
    msg_len equ $ - message             ; '$' representa la posición actual; calcula el tamaño exacto

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; Syscall: sys_write (eax = 4)
    ; ssize_t sys_write(unsigned int fd, const char *buf, size_t count);
    ; --------------------------------------------------------------------------
    mov eax, 4          ; syscall 4: sys_write
    mov ebx, 1          ; descriptor de archivo: 1 = stdout
    mov ecx, message    ; dirección de memoria del buffer a imprimir
    mov edx, msg_len    ; cantidad de bytes a escribir
    int 0x80            ; interrupción de software que delega al kernel

    ; --------------------------------------------------------------------------
    ; Syscall: sys_exit (eax = 1)
    ; void sys_exit(int status);
    ; --------------------------------------------------------------------------
    mov eax, 1          ; syscall 1: sys_exit
    xor ebx, ebx        ; código de salida 0 (éxito). 'xor reg, reg' es idiomático y óptimo
    int 0x80            ; termina el proceso limpiamente
