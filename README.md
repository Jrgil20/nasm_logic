# NASM Logic — Laboratorio Didáctico de Ensamblador x86 (32 bits)

Este repositorio contiene ejemplos prácticos y didácticos diseñados para comprender los fundamentos del ensamblador **NASM** (*Netwide Assembler*) en entornos Linux de 32 bits (`x86`).

El propósito es estudiar el modelo mental del procesador, la interacción directa con el kernel mediante llamadas al sistema (*syscalls*), la gestión de memoria por segmentos y la aritmética de punteros sin capas de abstracción.

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
Los binarios ejecutables se generarán en la carpeta `bin/`.

### Ejecutar ejemplos
```bash
# Hola Mundo
make run-hello

# Tokenizador con punteros
make run-pointers
```

### Compilación manual (sin Make)
```bash
# 1. Ensamblar a formato objeto ELF de 32 bits
nasm -f elf32 src/HelloW.asm -o HelloW.o

# 2. Enlazar con emulación i386
ld -m elf_i386 HelloW.o -o HelloW

# 3. Ejecutar
./HelloW
```

### Limpiar binarios generados
```bash
make clean
```
