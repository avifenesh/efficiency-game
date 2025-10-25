# x86-64 Assembly Log Anomaly Counter
# AT&T syntax (GAS) for macOS/Linux
# Links with C library for file I/O

    .section __DATA,__data
error_str:
    .asciz "ERROR"
warn_str:
    .asciz "WARN"
usage_msg:
    .asciz "Usage: solution <logfile>\n"
file_error_msg:
    .asciz "Error: Cannot open file\n"
json_fmt:
    .asciz "{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n"
read_mode:
    .asciz "r"

    .section __DATA,__bss
    .align 4
errors_count:
    .space 4
warnings_count:
    .space 4
    .align 4
line_buffer:
    .space 4096

    .section __TEXT,__text
    .globl _main

# Check if character is alphanumeric
# Input: %al = character
# Output: ZF set if not alphanumeric
_is_alnum:
    cmpb $'0', %al
    jl .Lnot_alnum
    cmpb $'9', %al
    jle .Lis_alnum
    cmpb $'A', %al
    jl .Lnot_alnum
    cmpb $'Z', %al
    jle .Lis_alnum
    cmpb $'a', %al
    jl .Lnot_alnum
    cmpb $'z', %al
    jle .Lis_alnum
.Lnot_alnum:
    xorl %eax, %eax
    ret
.Lis_alnum:
    orl $1, %eax
    ret

# Check if word exists with word boundaries
# Input: %rdi = line, %rsi = word, %rdx = word length
# Output: %rax = 1 if found, 0 otherwise
_contains_word:
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    pushq %r15

    movq %rdi, %r12        # r12 = line
    movq %rsi, %r13        # r13 = word
    movq %rdx, %r14        # r14 = word length
    xorq %r15, %r15        # r15 = position

.Lsearch_loop:
    movq %r12, %rdi
    addq %r15, %rdi
    movzbl (%r13), %esi    # First char of word

.Lfind_char:
    movzbl (%rdi), %eax
    testb %al, %al
    jz .Lnot_found

    cmpb %sil, %al
    je .Lcheck_word

    incq %rdi
    jmp .Lfind_char

.Lcheck_word:
    movq %rdi, %rbx        # Save position
    movq %r14, %rcx        # Word length
    movq %r13, %rsi        # Word pointer

.Lcheck_loop:
    movzbl (%rdi), %eax
    movzbl (%rsi), %edx
    cmpb %dl, %al
    jne .Lcontinue_search

    incq %rdi
    incq %rsi
    decq %rcx
    jnz .Lcheck_loop

    # Check before boundary
    cmpq %r12, %rbx
    je .Lcheck_after

    movb -1(%rbx), %al
    call _is_alnum
    jnz .Lcontinue_search

.Lcheck_after:
    movzbl (%rdi), %eax
    testb %al, %al
    jz .Lfound

    call _is_alnum
    jnz .Lcontinue_search

.Lfound:
    movq $1, %rax
    jmp .Ldone

.Lcontinue_search:
    incq %rbx
    movq %rbx, %rdi
    jmp .Lfind_char

.Lnot_found:
    xorq %rax, %rax

.Ldone:
    popq %r15
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    ret

# Process line
# Input: %rdi = line pointer
_process_line:
    pushq %rbx
    pushq %r12

    movq %rdi, %r12

    # Quick check for 'E'
    movq %r12, %rdi
.Lcheck_e:
    movzbl (%rdi), %eax
    testb %al, %al
    jz .Lcheck_warn
    cmpb $'E', %al
    je .Lcheck_error_word
    incq %rdi
    jmp .Lcheck_e

.Lcheck_error_word:
    movq %r12, %rdi
    leaq error_str(%rip), %rsi
    movq $5, %rdx
    call _contains_word
    testq %rax, %rax
    jz .Lcheck_warn

    # Increment errors
    movl errors_count(%rip), %eax
    incl %eax
    movl %eax, errors_count(%rip)
    jmp .Lprocess_done

.Lcheck_warn:
    movq %r12, %rdi
.Lcheck_w:
    movzbl (%rdi), %eax
    testb %al, %al
    jz .Lprocess_done
    cmpb $'W', %al
    je .Lcheck_warn_word
    incq %rdi
    jmp .Lcheck_w

.Lcheck_warn_word:
    movq %r12, %rdi
    leaq warn_str(%rip), %rsi
    movq $4, %rdx
    call _contains_word
    testq %rax, %rax
    jz .Lprocess_done

    # Increment warnings
    movl warnings_count(%rip), %eax
    incl %eax
    movl %eax, warnings_count(%rip)

.Lprocess_done:
    popq %r12
    popq %rbx
    ret

_main:
    pushq %rbx
    pushq %r12
    pushq %r13

    # Check argc
    cmpl $2, %edi
    jl .Lusage_error

    # Open file: fopen(argv[1], "r")
    movq 8(%rsi), %rdi     # argv[1]
    leaq read_mode(%rip), %rsi
    call _fopen

    testq %rax, %rax
    jz .Lfile_error

    movq %rax, %r13        # Save file handle

    # Initialize counters
    movl $0, errors_count(%rip)
    movl $0, warnings_count(%rip)

.Lread_loop:
    # fgets(buffer, size, file)
    leaq line_buffer(%rip), %rdi
    movq $4096, %rsi
    movq %r13, %rdx
    call _fgets

    testq %rax, %rax
    jz .Ldone_reading

    # Process line
    leaq line_buffer(%rip), %rdi
    call _process_line

    jmp .Lread_loop

.Ldone_reading:
    # Close file
    movq %r13, %rdi
    call _fclose

    # Print JSON: printf(fmt, errors, warnings, total)
    movl errors_count(%rip), %esi
    movl warnings_count(%rip), %edx
    movl %esi, %ecx
    addl %edx, %ecx
    leaq json_fmt(%rip), %rdi
    xorl %eax, %eax
    call _printf

    # Exit success
    xorl %edi, %edi
    call _exit

.Lusage_error:
    leaq usage_msg(%rip), %rdi
    xorl %eax, %eax
    call _printf
    movl $1, %edi
    call _exit

.Lfile_error:
    leaq file_error_msg(%rip), %rdi
    xorl %eax, %eax
    call _printf
    movl $1, %edi
    call _exit

    .subsections_via_symbols
