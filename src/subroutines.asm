; ==============================================================================
; subroutines.asm - Subrutinas, Pila (Stack) y Convención de Llamada en x86 (32b)
; ------------------------------------------------------------------------------
; Conceptos didácticos:
; 1. La Pila (Stack):
;    - Estructura LIFO (Last-In, First-Out) que crece hacia abajo (direcciones menores).
;    - ESP (Stack Pointer): Apunta a la cima actual de la pila.
;    - EBP (Base Pointer): Punto de referencia fijo dentro de una función para
;      acceder a parámetros y variables locales sin depender de las variaciones de ESP.
; 2. Mecanismo de 'call' y 'ret':
;    - 'call <func>': Empuja automáticamente la dirección de retorno (EIP) a la
;      pila y salta a la subrutina.
;    - 'ret': Extrae la dirección de retorno de la cima de la pila y salta a ella.
; 3. Estructura estándar del Stack Frame (cdecl):
;    - [ebp + 0]  : Antiguo valor de EBP guardado en el prólogo.
;    - [ebp + 4]  : Dirección de retorno (colocada por 'call').
;    - [ebp + 8]  : Primer argumento pasado por la función llamadora.
;    - [ebp + 12] : Segundo argumento.
; 4. Convención de valor de retorno:
;    - Los resultados escalares/enteros se retornan tradicionalmente en el registro EAX.
; ==============================================================================

section .data
    title_msg       db "Demostracion de Subrutinas y Stack Frame (cdecl):", 10
    title_len       equ $ - title_msg

    fn_call_msg     db "-> Ejecutando subrutina modular: calcular_cuadrado(6)...", 10
    fn_call_len     equ $ - fn_call_msg

    success_msg     db "-> Retorno exitoso de la subrutina con resultado en EAX.", 10
    success_len     equ $ - success_msg

section .text
    global _start

_start:
    ; --------------------------------------------------------------------------
    ; 1. Llamar a subrutina modular 'print_msg' para imprimir título
    ;    Paso de parámetros vía stack (de derecha a izquierda según cdecl):
    ;      push longitud
    ;      push puntero_al_buffer
    ; --------------------------------------------------------------------------
    push title_len              ; 2do argumento: longitud
    push title_msg              ; 1er argumento: buffer
    call print_msg              ; Llama a la subrutina
    add esp, 8                  ; Limpieza del stack por el llamador (2 dwords = 8 bytes)

    ; --------------------------------------------------------------------------
    ; 2. Imprimir mensaje de aviso previo al cálculo
    ; --------------------------------------------------------------------------
    push fn_call_len
    push fn_call_msg
    call print_msg
    add esp, 8

    ; --------------------------------------------------------------------------
    ; 3. Invocar subrutina matemática: calcular_cuadrado(6)
    ; --------------------------------------------------------------------------
    push 6                      ; Argumento: n = 6
    call calcular_cuadrado
    add esp, 4                  ; Limpiar argumento (1 dword = 4 bytes)

    ; Al regresar, EAX contiene el resultado (6 * 6 = 36).
    ; Verificamos que el resultado sea 36:
    cmp eax, 36
    jne error_exit

    ; --------------------------------------------------------------------------
    ; 4. Notificar éxito del cálculo
    ; --------------------------------------------------------------------------
    push success_len
    push success_msg
    call print_msg
    add esp, 8

    ; --------------------------------------------------------------------------
    ; 5. Salir del programa limpiamente
    ; --------------------------------------------------------------------------
    mov eax, 1                  ; sys_exit
    xor ebx, ebx                ; código 0
    int 0x80

error_exit:
    mov eax, 1                  ; sys_exit
    mov ebx, 1                  ; código 1 (error)
    int 0x80


; ==============================================================================
; SUBRUTINA: calcular_cuadrado
; Firma: int calcular_cuadrado(int n);
; Entrada: [ebp + 8] = número a elevar al cuadrado
; Salida:  EAX = resultado (n * n)
; ==============================================================================
calcular_cuadrado:
    ; --- Prólogo estándar ---
    push ebp                    ; Salvar el frame pointer del llamador
    mov ebp, esp                ; Establecer nuevo marco de referencia

    ; --- Cuerpo de la función ---
    mov eax, [ebp + 8]          ; Cargar el argumento 'n' en EAX
    imul eax, eax               ; EAX = EAX * EAX

    ; --- Epílogo estándar ---
    mov esp, ebp                ; Restaurar el puntero de pila
    pop ebp                     ; Restaurar el frame pointer anterior
    ret                         ; Retornar al llamador (extrae dirección de retorno)


; ==============================================================================
; SUBRUTINA: print_msg
; Firma: void print_msg(const char *buffer, int length);
; Entrada:
;   [ebp + 8]  = puntero a cadena
;   [ebp + 12] = longitud de la cadena
; ==============================================================================
print_msg:
    ; --- Prólogo ---
    push ebp
    mov ebp, esp

    ; Preservar registros que el llamador espera intactos (callee-saved)
    push ebx

    ; Preparar syscall sys_write (eax=4, ebx=1, ecx=buf, edx=len)
    mov eax, 4
    mov ebx, 1                  ; stdout
    mov ecx, [ebp + 8]          ; buffer
    mov edx, [ebp + 12]         ; length
    int 0x80

    ; Restaurar registros preservados
    pop ebx

    ; --- Epílogo ---
    mov esp, ebp
    pop ebp
    ret
