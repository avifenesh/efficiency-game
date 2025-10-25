; x86-64 Assembly Log Anomaly Counter
; NASM syntax for macOS/Linux
; Links with C library for file I/O and threading

section .data
    error_str: db "ERROR", 0
    error_len: equ $ - error_str - 1
    warn_str: db "WARN", 0
    warn_len: equ $ - warn_str - 1

    usage_msg: db "Usage: solution <logfile>", 10, 0
    file_error_msg: db "Error: Cannot open file", 10, 0
    json_fmt: db '{"errors": %d, "warnings": %d, "total": %d}', 10, 0
    read_mode: db "r", 0

    newline: db 10, 0

section .bss
    line_buffer: resb 4096
    errors_count: resd 1
    warnings_count: resd 1

section .text
    global main
    extern fopen, fclose, fgets, printf, exit, strlen

; Check if character is alphanumeric
; Input: al = character
; Output: zf = 1 if not alphanumeric, zf = 0 if alphanumeric
is_alnum:
    cmp al, '0'
    jl .not_alnum
    cmp al, '9'
    jle .is_alnum
    cmp al, 'A'
    jl .not_alnum
    cmp al, 'Z'
    jle .is_alnum
    cmp al, 'a'
    jl .not_alnum
    cmp al, 'z'
    jle .is_alnum
.not_alnum:
    xor eax, eax  ; Set ZF
    ret
.is_alnum:
    or eax, 1     ; Clear ZF
    ret

; Check if word exists with word boundaries
; Input: rdi = line pointer, rsi = word pointer, rdx = word length
; Output: rax = 1 if found, 0 if not found
contains_word:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi          ; r12 = line pointer
    mov r13, rsi          ; r13 = word pointer
    mov r14, rdx          ; r14 = word length
    xor r15, r15          ; r15 = search position

.search_loop:
    ; Find first character of word
    mov rdi, r12
    add rdi, r15
    movzx rsi, byte [r13] ; First char of word

    ; Manual search for character
.find_char:
    movzx rax, byte [rdi]
    test al, al
    jz .not_found         ; End of string

    cmp al, sil
    je .check_word

    inc rdi
    jmp .find_char

.check_word:
    ; Found first character, check full word
    mov rbx, rdi          ; Save position
    mov rcx, r14          ; Word length
    mov rsi, r13          ; Word pointer

.check_loop:
    movzx rax, byte [rdi]
    movzx rdx, byte [rsi]
    cmp al, dl
    jne .continue_search

    inc rdi
    inc rsi
    dec rcx
    jnz .check_loop

    ; Found word, check boundaries
    ; Check before
    cmp rbx, r12
    je .check_after       ; At start, before is OK

    mov al, byte [rbx - 1]
    call is_alnum
    jnz .continue_search  ; Before is alnum, not a word boundary

.check_after:
    movzx rax, byte [rdi]
    test al, al
    jz .found             ; At end, after is OK

    call is_alnum
    jnz .continue_search  ; After is alnum, not a word boundary

.found:
    mov rax, 1
    jmp .done

.continue_search:
    inc rbx
    mov rdi, rbx
    jmp .find_char

.not_found:
    xor rax, rax

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Process a line
; Input: rdi = line pointer
process_line:
    push rbx
    push r12

    mov r12, rdi          ; Save line pointer

    ; Check for 'E' in line (quick filter)
    mov rdi, r12
.check_e:
    movzx rax, byte [rdi]
    test al, al
    jz .check_warn
    cmp al, 'E'
    je .check_error
    inc rdi
    jmp .check_e

.check_error:
    ; Found 'E', check for "ERROR" with boundaries
    mov rdi, r12
    lea rsi, [rel error_str]
    mov rdx, error_len
    call contains_word
    test rax, rax
    jz .check_warn

    ; Increment error count
    mov eax, [rel errors_count]
    inc eax
    mov [rel errors_count], eax
    jmp .done

.check_warn:
    ; Check for 'W' in line
    mov rdi, r12
.check_w:
    movzx rax, byte [rdi]
    test al, al
    jz .done
    cmp al, 'W'
    je .check_warning
    inc rdi
    jmp .check_w

.check_warning:
    ; Found 'W', check for "WARN" with boundaries
    mov rdi, r12
    lea rsi, [rel warn_str]
    mov rdx, warn_len
    call contains_word
    test rax, rax
    jz .done

    ; Increment warning count
    mov eax, [rel warnings_count]
    inc eax
    mov [rel warnings_count], eax

.done:
    pop r12
    pop rbx
    ret

main:
    push rbx
    push r12
    push r13

    ; Check argument count
    cmp rdi, 2
    jl .usage_error

    ; Get filename from argv[1]
    mov r12, rsi          ; Save argv
    mov rdi, [r12 + 8]    ; argv[1]
    lea rsi, [rel read_mode]
    call fopen

    test rax, rax
    jz .file_error

    mov r13, rax          ; Save file pointer

    ; Initialize counters
    mov dword [rel errors_count], 0
    mov dword [rel warnings_count], 0

.read_loop:
    ; Read line
    lea rdi, [rel line_buffer]
    mov rsi, 4096
    mov rdx, r13
    call fgets

    test rax, rax
    jz .done_reading

    ; Process line
    lea rdi, [rel line_buffer]
    call process_line

    jmp .read_loop

.done_reading:
    ; Close file
    mov rdi, r13
    call fclose

    ; Calculate total
    mov eax, [rel errors_count]
    mov ebx, [rel warnings_count]
    add eax, ebx
    mov ecx, eax          ; total in ecx

    ; Print JSON output
    lea rdi, [rel json_fmt]
    mov esi, [rel errors_count]
    mov edx, [rel warnings_count]
    ; ecx already has total
    xor eax, eax
    call printf

    ; Exit success
    xor rdi, rdi
    call exit

.usage_error:
    lea rdi, [rel usage_msg]
    xor eax, eax
    call printf
    mov rdi, 1
    call exit

.file_error:
    lea rdi, [rel file_error_msg]
    xor eax, eax
    call printf
    mov rdi, 1
    call exit
