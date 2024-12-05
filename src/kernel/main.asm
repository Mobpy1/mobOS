org 0x7C00        ; Set the origin address where the bootloader will be loaded in memory
bits 16            ; Set the CPU mode to 16-bit

%define ENDL 0x0D, 0x0A  ; Define newline

start:
    jmp main  ; Jump to main procedure

; Prints a string to the screen
; Params:
;    - ds:si points to the string
puts:
    ; Save registers we modify
    push si
    push ax

.loop:
    lodsb               ; Load the next byte (character) from [ds:si] into AL
    test al, al         ; Check if the character is NULL (0x00)
    jz .done            ; If NULL, exit the loop
    mov ah, 0x0e        ; BIOS teletype function for printing character
    mov bh, 0           ; Page number (0 is the first page)
    int 0x10            ; Call BIOS interrupt to print character

    jmp .loop           ; Repeat for next character

.done:
    pop ax
    pop si
    ret

main:
    ; Setup data segments
    mov ax, 0           ; Clear the data segment register
    mov ds, ax
    mov es, ax

    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00      ; Set stack pointer to the base of the bootloader

    ; Print message
    lea si, [msg_hello] ; Load the address of msg_hello into SI
    call puts           ; Call the puts function to print the message

    hlt                 ; Halt the CPU

.halt:
    jmp .halt           ; Infinite loop to halt the program



msg_hello: 
    db 'Hello World!', ENDL, 0  ; Null-terminated string with newline



times 510-($-$$) db 0  ; Pad the remaining space to 510 bytes
dw 0xAA55             ; Bootloader signature (0xAA55)
