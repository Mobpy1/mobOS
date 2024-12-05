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
    mov ax, 0                                   ; Clear the data segment register
    mov ds, ax
    mov es, ax

    ; Setup stack
    mov ss, ax
    mov sp, 0x7C00                              ; Set stack pointer to the base of the bootloader

    ; read something from disk
    ; BIOS should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1                                   ; LBA=1, second sector of disk
    mov cl, 1                                   ; 1 sector to read
    mov bx, 0x7E00                              ; data should be after the bootloader
    call disk_read


    ; Print message
    lea si, [msg_hello]                         ; Load the address of msg_hello into SI
    call puts                                   ; Call the puts function to print the message

    hlt                                         ; Halt the CPU

;
;   Error Handlers
;

floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_reboot

wait_key_reboot:
    mov ah,0
    int 16h                                     ; wait for keypress
    jmp 0xFFFF:0                                 ; jump to beggining of BIOS, should reboot
    


.halt:
    cli                                         ; disable interrupts SO CPU can get out of 'halt' state
    hlt       


;
;   Disk routines
;

;
; Converts LBA address to CHS adress
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector num
;   - cx [bits 6-15]: cylinder
;

lba_to_chs:

    push ax
    push dx

    xor dx, dx                                          ; dx = 0
    div word [bdb_sectors_per_track]                    ; ax = LBA / SectorsPerTrack
                                                        ; dx = LBA % SectorsPerTrack
    
    inc dx                                              ; dx = (LBA % SectorsPerTrack + 1 ) = Sector
    mov cx , dx                                         ; cx = sector

    xor dx, dx                                          ; dx = 0
    div word [bdb_heads]                                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                                        ; dx = (LBA / SectorsPerTrack) % Heads = cylinder
    mov dh, dl                                          ; dh = head
    mov ch, al                                          ; ch = cylinder(lower 8 bits)
    shl ah, 6
    or  cl, ah                                          ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                                          ; restore DL
    pop ax
    ret


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: num of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

    ; save registers we wil modify
    push ax                                             
    push bx
    push cx
    push dx
    push di

    push cx                                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                                     ; compute CHS
    pop ax                                              ; AL = number of sectors to read

    mov ah, 02h
    mov di, 3                                           ; retry count
    int 13h

.retry:
    pusha                                               ; save all registers, we dk what bios modifies
    stc                                                 ; set carry flag 
    int 13h                                             ; carry flag cleared = success
    jnc .done                                           ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; after all attemps are exhausted
    jmp floppy_error


.done:
    popa

    ; restore registers we modified
    push di
    push dx                                           
    push cx
    push bx
    push ax
    ret



;
; Reset disk controller
; Parameters:
;   - dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg_hello:                  db 'Hello World!', ENDL, 0  
msg_read_failed:            db 'Read From Disk Failed!', ENDL, 0 


times 510-($-$$) db 0  ; Pad the remaining space to 510 bytes
dw 0xAA55             ; Bootloader signature (0xAA55)
