org 0x7C00        ; Set the origin address where the bootloader will be loaded in memory
bits 16            ; Set the CPU mode to 16-bit

%define ENDL 0x0D, 0x0A  ; Define newline

;
;   FAT12 Header
;
jmp short start
nop

bdb_oem:                            db 'MSWIN4.1'               ; 8 bytes
bdb_bytes_per_sector:               dw 512
bdb_sectors_per_cluster:            db 1
bdb_reserved_sectors:               dw 1 
bdb_fat_count:                      db 2 
bdb_dir_entries_count:              dw 0E0H
bdb_total_sectors:                  dw 2880                     ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:          db 0F0h                     ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:                dw 9                        ; 9 sectors/fat
bdb_sectors_per_track:              dw 18
bdb_heads:                          dw 2
bdb_hidden_sector_count:            dd 0
bdb_large_sector_count:             dd 0

; extended boot record
ebr_drive_number:                   db 0                        ; 0x00 floppy , 0x80 hdd , use
                                    db 0                        ; reserved
ebr_signature:                      db 29h
ebr_volume_id:                      db 12h, 34h, 56h, 78h
ebr_volume_label:                   db 'mobOS'                  ; 5 bytes
ebr_system_id:                      db 'FAT12   '               ; 8 bytes



;
; Code Here 
;


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
