# NASM Logic — Laboratorio Didáctico de Ensamblador x86 (32 bits)

Este repositorio contiene ejemplos prácticos y didácticos diseñados para comprender los fundamentos del ensamblador **NASM** (*Netwide Assembler*) en entornos Linux de 32 bits (`x86`).

El propósito es estudiar el modelo mental del procesador, la interacción directa con el kernel mediante llamadas al sistema (*syscalls*), la gestión de memoria por segmentos, la aritmética de punteros, el control de flujo y la mecánica del stack con subrutinas.

---

## 🧠 Conceptos Clave de la Arquitectura x86 (32 bits)

### 1. Secciones de Memoria

Un binario ELF estructurado en NASM divide el programa en segmentos esenciales:

- **`.data`**: Datos estáticos inicializados (strings, constantes numéricas). Ocupan espacio directo en el binario final.
- **`.bss`** (*Block Started by Symbol*): Variables no inicializadas o buffers en memoria dinámica. Se reservan con directivas como `resb` (bytes) y no aumentan el peso del archivo binario en disco.
- **`.text`**: Código ejecutable (instrucciones máquina de sólo lectura). Aquí reside el punto de entrada `_start`.

### 2. Convención de Llamadas al Sistema (`int 0x80`)

En Linux x86 (32 bits), la comunicación con el kernel se realiza mediante la interrupción de software `0x80`:

| Registro | Rol en la Syscall |
|---|---|
| `EAX` | Número identificador de la llamada al sistema |
| `EBX` | Primer argumento (descriptor de archivo, código de retorno, etc.) |
| `ECX` | Segundo argumento (puntero a buffer o estructura) |
| `EDX` | Tercer argumento (longitud o tamaño en bytes) |
| `ESI` | Cuarto argumento (si aplica) |
| `EDI` | Quinto argumento (si aplica) |

#### Syscalls utilizadas en este repositorio:

| Syscall | Código (`EAX`) | Parámetros | Propósito |
|---|---|---|---|
| `sys_exit` | `1` | `EBX` = exit status | Terminar el proceso ordenadamente |
| `sys_read` | `3` | `EBX` = fd (`0` stdin), `ECX` = buffer, `EDX` = max bytes | Leer bytes desde entrada estándar |
| `sys_write` | `4` | `EBX` = fd (`1` stdout), `ECX` = buffer, `EDX` = bytes a escribir | Escribir bytes en salida estándar |

### 3. Idiomática y Buenas Prácticas en NASM

- **Cálculo de longitud en tiempo de ensamblado**:  
  En lugar de contar caracteres manualmente o usar números mágicos propensos a errores, se usa:
  ```nasm
  mensaje db "Texto de prueba", 10
  mensaje_len equ $ - mensaje
  ```
  `$` representa la dirección de memoria inmediatamente posterior a la variable, permitiendo que el ensamblador reste ambas direcciones y determine la cantidad exacta de bytes.

- **Puesta a cero con `xor`**:  
  Para inicializar un registro en `0`, se prefiere `xor reg, reg` sobre `mov reg, 0` debido a que genera un opcode más compacto (2 bytes vs 5 bytes) y el pipeline del procesador lo reconoce como un reseteo de dependencia.

- **Registros índices para punteros (`ESI` y `EDI`)**:  
  - `ESI` (*Extended Source Index*): Empleado por convención como puntero lector / origen.
  - `EDI` (*Extended Destination Index*): Empleado por convención como puntero escritor / destino.
  - La sintaxis `byte [esi]` desreferencia el puntero para leer el contenido del byte apuntado en memoria.

### 4. Control de Flujo y Banderas (`EFLAGS`)

Las bifurcaciones y bucles en ensamblador se basan en la inspección de banderas de estado:

- **Instrucción `cmp a, b`**: Realiza una resta interna `a - b` sin guardar el resultado, únicamente actualizando el registro de banderas `EFLAGS`:
  - `ZF` (*Zero Flag*): Se enciende si el resultado es `0` (indica igualdad `a == b`).
  - `SF` (*Sign Flag*): Se enciende si el resultado es negativo (`a < b`).
  - `CF` (*Carry Flag*): Bandera de acarreo para aritmética sin signo.
- **Instrucción `test a, b`**: Realiza una operación lógica `AND` bit a bit sin alterar los registros, ideal para comprobar bits específicos (como paridad probando el bit menos significativo con `test reg, 1`).
- **Saltos condicionales**:
  - `je` / `jz`: Salta si es igual o cero (`ZF = 1`).
  - `jne` / `jnz`: Salta si no es igual o no cero (`ZF = 0`).
  - `jg` / `jl`: Salta si mayor / menor con signo.
  - `jge` / `jle`: Salta si mayor o igual / menor o igual con signo.

### 5. Pila (*Stack*), Subrutinas y Convención cdecl

El Stack es una estructura LIFO que en la arquitectura x86 crece hacia direcciones menores de memoria:

- **`ESP` (*Stack Pointer*)**: Apunta siempre a la cima actual de la pila.
- **`EBP` (*Base Pointer*)**: Se usa como ancla fija para acceder a parámetros y variables locales.
- **`call` y `ret`**:
  - `call func`: Apila automáticamente la dirección de la siguiente instrucción (*return address*) y salta a la función.
  - `ret`: Desapila la dirección de retorno hacia el puntero de instrucción `EIP` y continúa la ejecución del llamador.
- **Marco de pila (*Stack Frame*)**:
  ```nasm
  mi_subrutina:
      push ebp            ; Salvar EBP del llamador
      mov ebp, esp        ; Fijar base del nuevo marco
      ; [ebp + 8]  -> 1er argumento
      ; [ebp + 12] -> 2do argumento
      mov esp, ebp        ; Restaurar ESP
      pop ebp             ; Restaurar EBP anterior
      ret
  ```
- **Convención `cdecl`**: Los argumentos se apilan de derecha a izquierda, el llamador limpia la pila tras el retorno (`add esp, bytes`) y el valor de retorno entero se devuelve en `EAX`.

---

## 📂 Contenido del Proyecto

- **[`src/HelloW.asm`](src/HelloW.asm)**:
  - Estructura básica de un programa mínimo.
  - Uso de `sys_write` para imprimir en consola y `sys_exit` para retornar al sistema operativo con código `0`.
  - Inclusión de salto de línea (`10` / `\n`) y cálculo dinámico de longitud con `equ $ - message`.

- **[`src/pointers.asm`](src/pointers.asm)**:
  - Demostración práctica de aritmética y desplazamiento de punteros.
  - Lectura interactiva desde consola mediante `sys_read`.
  - Recorrido de memoria carácter por carácter con `ESI` y `EDI` para separar/tokenizar la primera palabra de una frase.
  - Manejo de delimitadores reales: espacio (`' '`), salto de línea (`\n` generado al presionar Enter) y byte nulo (`0`).
  - Cálculo dinámico de la longitud resultante restando punteros de destino: `EDI - output_buffer`.

- **[`src/control_flow.asm`](src/control_flow.asm)**:
  - Bucle aritmético iterativo (suma acumulada del 1 al 5).
  - Bifurcaciones condicionales comparando con umbrales (`cmp` y `jge` / `jl`).
  - Verificación bit a bit de paridad con `test` y saltos según `ZF`.

- **[`src/subroutines.asm`](src/subroutines.asm)**:
  - Modularización con subrutinas y convención de llamadas estándar `cdecl`.
  - Función matemática `calcular_cuadrado` con paso de argumentos vía stack y retorno en `EAX`.
  - Subrutina de impresión genérica `print_msg` con preservación de registros llamadores (*callee-saved registers*).

---

## 🛠️ Requisitos Previos

Si estás en una distribución Linux moderna de 64 bits (x86_64), necesitás el ensamblador `nasm` y las librerías/herramientas de enlace para 32 bits (*multilib*).

### Debian / Ubuntu y derivados
```bash
sudo apt update
sudo apt install nasm build-essential gcc-multilib
```

### Arch Linux / Manjaro
```bash
sudo pacman -S nasm base-devel lib32-glibc
```

### Fedora / Red Hat
```bash
sudo dnf install nasm glibc-devel.i686
```

---

## 🚀 Compilación y Ejecución

Se incluye un `Makefile` para automatizar el ensamblado (`nasm -f elf32`) y el enlace (`ld -m elf_i386`).

### Compilar todos los ejemplos
```bash
make
```
Los binarios ejecutables se generarán automáticamente en la carpeta `bin/`.

### Ejecutar ejemplos
```bash
# Hola Mundo
make run-hello

# Tokenizador con punteros
make run-pointers

# Control de flujo y banderas EFLAGS
make run-control-flow

# Subrutinas y Stack Frame
make run-subroutines
```

### Compilación manual (sin Make)
```bash
# 1. Ensamblar a formato objeto ELF de 32 bits
nasm -f elf32 src/control_flow.asm -o control_flow.o

# 2. Enlazar con emulación i386
ld -m elf_i386 control_flow.o -o control_flow

# 3. Ejecutar
./control_flow
```

### Limpiar binarios generados
```bash
make clean
```
