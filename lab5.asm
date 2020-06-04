.model small
.stack 100h
.data

res_handle dw 0
handle dw 0
 
filename db 50 DUP(0)
filepath db 50 DUP(0)
filename_size db 0

is_end db 0
symbol db 0
extension_flag db 1

line_begining_dx dw 0
line_begining_ax dw 0

string db 201;allowed
       db ?;data entered
       db 201 dup('$');can be entered
same_string db 201 dup('$')
should_write db 0

error_sizemsg db "Wrong or no command promt arguments", 10, 13, '$'
enter_msg db "enter string: ", 10, 13, '$'
find_err db "Can't find file!", 10, 13, 0, '$'
path_err db "Can't find file path!", 10, 13, 0, '$' 
toomany_err db "To many opened file!", 10, 13, 0, '$'
accessdenied_err db "Access denied!", 10, 13, 0, '$'
incorrectacces_err db "Incorrect access mode!", 10, 13, 0, '$'
string_err_msg db "Size of string is 0, reenter string!", 10, 13, 0, '$'

.code
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
changeOffset MACRO min, newOffset
    local cnt_change, cnt_changeoffset
    mov ah, 42h
    mov al, 1
    mov bx, handle
    mov dx, newOffset
    mov cl, 0
    cmp cl, min
    je cnt_change
    
    neg dx
    mov cx, 0FFFFh
    jmp cnt_changeoffset
    
    cnt_change:
    mov cx, 0
    
    cnt_changeoffset:
    int 21h
 ENDM
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
print MACRO str
    push ax 
    push dx
    mov dx, offset str
    mov ah, 09h
    int 21h
    pop dx
    pop ax
 ENDM
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
check_extension PROC
    mov al, [di]
    cmp al, '.'
    jne wrong_extension
    inc di

    mov al, [di]
    cmp al, 't'
    jne wrong_extension
    inc di

    mov al, [di]
    cmp al, 'x'
    jne wrong_extension
    inc di

    mov al, [di]
    cmp al, 't'
    jne wrong_extension
    ret
    wrong_extension:
        mov extension_flag, 0
        ret
check_extension ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
newline PROC   
    mov ah, 0Eh   
    mov al,0Dh
    int 10h                      
    mov ah, 0Eh   
    mov al,0Ah
    int 10h  
    ret
newline ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
openFile PROC
    jmp openFile_start 
    
    cant_find_error:
    print find_err
    mov is_end, 1
    jmp openFile_fin
    
    path_error:
    print path_err
    mov is_end, 1
    jmp openFile_fin
    
    toomany_error:
    print toomany_err
    mov is_end, 1
    jmp openFile_fin
    
    access_error:
    print accessdenied_err
    mov is_end, 1
    jmp openFile_fin
    
    accessmode_error:
    print incorrectacces_err
    mov is_end, 1
    jmp openFile_fin
    
    openFile_start:
    mov dx, offset filepath
    mov al, 2h ;openfile(rw)
    mov ah, 3Dh
    int 21h
    jc openFile_fin_err ;if error, terminate
    mov bx, ax ;handler to bx
    mov handle, bx
    jmp openFile_fin
    
    openFile_fin_err:
    cmp ax, 02h
    je cant_find_error
    cmp ax, 03h
    je path_error
    cmp ax, 04h
    je toomany_error
    cmp ax, 05h
    je access_error
    cmp ax, 0Ch
    je accessmode_error
    
    openFile_fin:
    ret
openFile ENDP 
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
createFile PROC
    jmp createFile_start 
    
    cant_find_error_1:
    print find_err
    mov is_end, 1
    jmp createFile_fin
    
    path_error_1:
    print path_err
    mov is_end, 1
    jmp createFile_fin
    
    toomany_error_1:
    print toomany_err
    mov is_end, 1
    jmp createFile_fin
    
    access_error_1:
    print accessdenied_err
    mov is_end, 1
    jmp createFile_fin
    
    accessmode_error_1:
    print incorrectacces_err
    mov is_end, 1
    jmp createFile_fin
    
    createFile_start:
    mov dx, offset filename ;address of file to dx
    mov ah, 3Ch
    mov al, 00h
    mov cx, 0000h
    int 21h ;call the interupt
    jc createFile_fin_err ;if error occurs, terminate program
    mov bx, ax ;put handler to file in bx
    mov res_handle, bx
    jmp createFile_fin
    
    createFile_fin_err:
    cmp ax, 02h
    je cant_find_error_1
    cmp ax, 03h
    je path_error_1
    cmp ax, 04h
    je toomany_error_1
    cmp ax, 05h
    je access_error_1
    cmp ax, 0Ch
    je accessmode_error_1
    
    createFile_fin:
    ret
createFile ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
writeLine PROC
    jmp writeLine_start

    writeLine_start:
    ;seting pos to chosen coord
    mov ah, 42h
    mov al, 0
    mov bx, handle
    mov cx, line_begining_dx
    mov dx, line_begining_ax
    int 21h

    writeLineFor:
        mov bx,handle
        mov cx,1 ;read one symbol
        mov ah,3Fh ;read from the opened file (its handler in bx)
        mov dx,offset symbol;where to read
        int 21h

        cmp ax,0
        je writeLineEnd
        mov al,10
        cmp al,symbol
        je writeLineEnd
        mov al,13
        cmp al,symbol
        je writeLineEnd

        mov bx,res_handle
        mov cx,1
        mov ah,40h               ;write ro result.txt
        mov dx,offset symbol
        int 21h
    jmp writeLineFor

    set_end_file_0_fin:
    mov is_end,1
    jmp writeLine_fin

    writeLineEnd:

    mov symbol,13;/r
    mov bx,res_handle
    mov cx,1
    mov ah,40h
    mov dx,offset symbol
    int 21h
    
    mov symbol,10;/n
    mov bx,res_handle
    mov cx,1
    mov ah,40h 
    mov dx,offset symbol
    int 21h

    call skip_eol
    writeLine_fin:
    ret
writeLine ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
nulling_string PROC

    mov di, offset same_string
    mov al, symbol

    for_8:
    mov ah, [di]
    cmp ah, '$'
    je fin_null

    cmp ah, al
    jne cnt_null
    
    mov ah, 0
    mov [di], ah

    cnt_null:
    inc di
    jmp for_8

    fin_null:
    ret
nulling_string ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
cmp_nulling PROC
    mov should_write, 0
    mov di, offset same_string
    jmp for_7

    should_write_set_1:
    mov should_write, 1
    jmp fin_cmp

    for_7:
    mov al, [di]
    cmp al, '$'
    je should_write_set_1

    cmp al, 0
    jne fin_cmp

    inc di
    jmp for_7

    fin_cmp:
    ret
cmp_nulling ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
skip_eol PROC
    jmp skip_start

    set_end_1_:
    mov is_end,1
    jmp fin_skip

    skip_start:
        mov bx,handle
        mov cx,1
        mov ah,3fh
        mov dx,offset symbol
        int 21h

        cmp ax,0
        je set_end_1_
        mov al,13
        cmp al,symbol
        je skip_start
        mov al,10
        cmp al,symbol
        je skip_start
    changeOffset 1,1
    fin_skip:
    ret
skip_eol ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
checkLine PROC
    jmp check_start

    set_should_0_fin:
    mov should_write, 0
    jmp cnt

    set_end_1_fin:
    mov is_end, 1
    jmp cnt 

    check_start:
    call copy_string;copying string to same_string
    mov is_end, 0

    checkLineFor:
        mov bx, handle
        mov cx, 1
        mov ah, 3fh
        mov dx, offset symbol
        int 21h

        cmp ax, 0;eof
        je set_end_1_fin

        mov al, 10; /n
        cmp al, symbol
        je set_should_0_fin

        call nulling_string
        call cmp_nulling
        cmp should_write, 1 
        je cnt                        
    jmp checkLineFor
    cnt_skip:
        mov bx, handle
        mov cx, 1
        mov ah, 3fh
        mov dx, offset symbol
        int 21h

        cmp ax, 0;eof
        je set_end_1_fin

        mov al, 10; /r
        cmp al, symbol
        jne cnt_skip
    cnt:
    ret
checkLine ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
writeToNew PROC
    push ax
    push bx
    push cx
    push dx

    checkingLines:
        ;save pos of line
        changeOffset 0, 1
        mov line_begining_dx, dx
        dec ax
        mov line_begining_ax, ax
        changeOffset 1, 1

        call checkLine

        cmp is_end, 1
        je writetofile

        cmp should_write, 0
        je checkingLines

        call writeLine

    jmp checkingLines
    writetofile:
    ;call writeLine
    writeToNewEnd:
    pop dx 
    pop cx
    pop bx
    pop ax     
    ret
writeToNew ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
copy_string PROC
    ;copying entered string to same string to verify line
    mov di, offset string + 2
    mov si, offset same_string
    for_9:
        mov al, [di]
        cmp al, '$'
        je for_9_end

        mov [si], al
        inc si
        inc di
    jmp for_9

    for_9_end:
    inc si
    mov [si], al

    ret
copy_string ENDP
;\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
start:
mov ax, @data
mov ds, ax

xor cx, cx
mov cl, es:[80h]

cmp cl, 0 ;ci size 0, no parametrs
je terminate_bcsize
cmp cl, 12
jl terminate_bcsize

mov si, 81h ;skip space
xor di,di

inc si ;skip space
dec cl ;skip space

get_parm1:
    mov al, es:si
    cmp al, ' '
    je end_get_param1
    mov [filepath + di], al  ;setting to filepath
    inc di
    dec cx
    inc si
jmp get_parm1
end_get_param1:

inc si
xor di, di
dec cx
cmp cx, 1
je terminate_bcsize
get_parm2:
    mov al, es:si
    mov [filename + di] , al
    inc di
    inc si
    inc filename_size
loop get_parm2               ;while cx not equal 0

mov di, offset filename
xor ax, ax
mov al, filename_size
add di, ax
sub di, 4
call check_extension
cmp extension_flag, 0
je terminate_bcsize
jmp string_input

terminate_bcsize:
    mov ah, 9
    mov dx, offset error_sizemsg
    int 21h
    jmp terminate

string_error:
    call newline
    mov ah, 9
    mov dx, offset string_err_msg
    int 21h
    call newline
    jmp string_input

string_input:
    mov ah, 9
    mov dx, offset enter_msg
    int 21h
    mov ah, 0Ah
    mov dx, offset string
    int 21h                 

    mov si, offset string + 1
    mov cl, [si]
    mov ch, 0
    cmp cx, 0
    je  string_error 
    inc cx
    add si, cx
    mov al, '$'
    mov [si], al

open_file_test:
call openFile
cmp is_end, 1
je terminate

call createFile
cmp is_end, 1
je terminate
;jmp close_file
call writeToNew
    
    close_file:
    mov ah, 3Eh
    mov bx, handle
    int 21h 
    
    mov ah, 3Eh
    mov bx, res_handle
    int 21h
terminate: 

    mov ax, 4C00h
    int 21h
    int 20h
    ends
end start