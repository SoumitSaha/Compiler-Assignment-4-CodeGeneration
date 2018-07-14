.model small
.stack 100h
.data
a2 dw ?
t0 dw ?
a3 dw ?
b3 dw ?
x3 dw ?
t1 dw ?
t2 dw ?
a4 dw ?
b4 dw ?
.code
f proc
push ax
mov ax, 2
mov bx, a2
mul bx
mov t0, ax
mov dx,t0
jmp L0
L0:
pop ax
ret
f endp
g proc
push ax
mov ax, 
add ax, a3
mov t1 , ax
mov ax, t1
add ax, b3
mov t2 , ax
mov ax, 
add ax, a3
mov t1 , ax
mov ax, t1
add ax, b3
mov t2 , ax
mov ax, t2
mov x3, ax
mov dx,x3
jmp L1
L1:
pop ax
ret
g endp
main proc
mov ax, @data
mov ds, ax
mov ax, 1
mov a4, ax
mov ax, 2
mov b4, ax
mov ax, 
mov a4, ax
mov ax, a
call DECIMAL_OUT
mov dx,0
jmp L2
L2:
mov ah, 4ch
mov al, 0
int 21h
main endp

DECIMAL_OUT PROC NEAR
push ax
push bx
push cx
push dx
or ax,ax
jge enddif
push ax
mov dl,'-'
mov ah,2
int 21h
pop ax
neg ax
enddif:
xor cx,cx
mov bx,10d
repeat:
xor dx,dx
div bx
push dx
inc cx
or ax,ax
jne repeat
mov ah,2
print_loop:
pop dx
or dl,30h
int 21h
loop print_loop
pop dx
pop cx
pop bx
pop ax
ret
DECIMAL_OUT ENDP
end main
