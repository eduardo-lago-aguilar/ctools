;*****************************************************************************;
;    - CTOOLS.ASM version 1.1 (c) 1997 Eduardo Lago & Jos‚ H Cifuentes -      ;
;  Low level routines to access video memory and control some PC functions    ;
;                                                                             ;
;    Note: Ctools must be used only with CGA's 320x200-4 color mode OR        ;
;                                        CGA's 640x200-2 color mode ...       ;
;    TinoSoft (C) 1997                                                        ;
;*****************************************************************************;

.model tpascal

  LOCALS @@

  dimx        equ 20
  dimy        equ 20
  numpoint    equ dimx * dimy
  yloopbnd    equ 200 div dimy-1
  xloopbnd    equ 320 div dimx
  binc        equ dimx div 4
  _Escape     equ 1
  _BackSpc    equ 14
  _Tab        equ 15
  _Ent        equ 28
  _Ctrl       equ 29
  _ShiftLeft  equ 42
  _ShiftRight equ 54
  _Alt        equ 56
  _Space      equ 57
  _F1         equ 59
  _F2         equ 60
  _F3         equ 61
  _F4         equ 62
  _F5         equ 63
  _F6         equ 64
  _F7         equ 65
  _F8         equ 66
  _F9         equ 67
  _F10        equ 68
  _UpLeft     equ 71
  _Up         equ 72
  _UpRight    equ 73
  _Left       equ 75
  _Center     equ 76
  _Right      equ 77
  _DownLeft   equ 79
  _Down       equ 80
  _DownRight  equ 81

; Graphic Screen Tools (FAST ACCESS!)

  public ppixel
  public gpixel
  public hline
  public vline
  public line
  public rect
  public box
  public pbox
  public getimage
  public putimage
  public movimage
  public imgsize
  public showimg
  public putspr
  public sprsize
  public freespr
  public sprDX
  public sprDY
  public fillscr
  public getscr
  public freescr
  public setscr
  public shiftr
  public shiftl
  public setmode

; Control routines

  public savevec
  public loadvec
  public getvec
  public setvec
  public clrbuffer
  public keyON
  public keyOFF
  public keyint
  public initscan
  public initkeyboard
  public reskeyboard
  public clockint
  public initclock
  public resclock
  public progtimer0
  public timerfreq
  public waittime
  public waittimeOK
  public seconds
  public minutes
  public syncro

; Another auxiliar routines

  public datseg
  public csegadds
  public initcode
  public version

; Macro declarations

kon MACRO scancode, value
local @@cont
  cmp al, value
  jne @@cont
  mov scancode, 1
  jmp @@contaddr
@@cont:
endm

koff MACRO scancode, value
local @@cont
  cmp al, value
  jne @@cont
  mov scancode, 0
  jmp @@contaddr2
@@cont:
endm

addrvector MACRO
  xor ax, ax
  mov es, ax
  mov ax, vectorcode
  shl ax, 1
  shl ax, 1
  mov si, ax
endm

jaFAR MACRO dest
local @@cont
  jna @@cont
  jmp dest
@@cont:
endM

; Struct declarations

tpoints STRUC
  ys     db ?
  xb     db ?
  eraser db ?
  sepair db ?
ends

.data
  extrn oldvecs        : word
  extrn asciiseg       : word
  extrn asciiofs       : word
  extrn lastclock      : word
  extrn clockfreq      : word
  extrn videoptr       : dword
  extrn scr_x          : word
  extrn scr_y          : word
  extrn maxcolor       : byte
  extrn adds           : byte
  extrn stabhi         : byte
  extrn atabhi         : byte
  extrn stablo         : byte
  extrn atablo         : byte
  extrn bandtable      : byte
  extrn gandtablehi    : byte
  extrn gandtablelo    : byte
  extrn leftandtable1  : byte
  extrn rightandtable1 : byte
  extrn colortable1    : byte
  extrn leftandtable2  : byte
  extrn rightandtable2 : byte
  extrn colortable2    : byte
  extrn curmode        : byte
  extrn cgamode        : byte
  extrn scan           : byte
  extrn scancode       : byte
  extrn Escape         : byte
  extrn BackSpc        : byte
  extrn Tab            : byte
  extrn Ent            : byte
  extrn Ctrl           : byte
  extrn ShiftLeft      : byte
  extrn ShiftRight     : byte
  extrn Alt            : byte
  extrn Space          : byte
  extrn F1             : byte
  extrn F2             : byte
  extrn F3             : byte
  extrn F4             : byte
  extrn F5             : byte
  extrn F6             : byte
  extrn F7             : byte
  extrn F8             : byte
  extrn F9             : byte
  extrn F10            : byte
  extrn UpLeft         : byte
  extrn Up             : byte
  extrn UpRight        : byte
  extrn Left           : byte
  extrn Center         : byte
  extrn Right          : byte
  extrn DownLeft       : byte
  extrn Down           : byte
  extrn DownRight      : byte
  extrn endmark        : byte
  extrn tables         : byte
  extrn tableNEGD      : byte
  extrn points         : tpoints
  extrn spr386         : byte

  auxvar     dw ?
  BackOFS    dw ?
  numb       dw ?
  Xobyte     dw ?
  initAND_OR dw ?
  restAND_OR dw ?

.code

  extrn extdelay       : near
  extrn getmem         : near
  extrn freemem        : near
  extrn initpoints     : near
  extrn asciitab       : far

ppixel proc far x,y : word, color : byte
  les di,videoptr
  mov bx, y
  cmp bx, 200
  jb  @@cont1
  RET
@@cont1:
  shl bx, 1
  add di, word ptr adds [bx]
  mov bx, x
  cmp curmode,6
  je  @@1
  cmp bx, 320
  jb  @@cont2
  RET
@@cont2:
  mov ax, bx
  shr ax, 1
  shr ax, 1
  add di, ax
  and bx, 3
  mov al, es:[di]
  and al, byte ptr atablo [bx]
  mov cl, byte ptr stablo [bx]
  mov bl, color
  and bl, 3
  shl bl, cl
  or  al, bl
  stosb
  RET
@@1:
  cmp bx, 640
  jb  @@cont3
  RET
@@cont3:
  mov ax, bx
  shr ax, 1
  shr ax, 1
  shr ax, 1
  add di, ax
  and bx, 7
  mov al, es:[di]
  and al, byte ptr atabhi [bx]
  mov cl, 7
  sub cl, bl
  mov bl, color
  and bl, 1
  shl bl, cl
  or  al, bl
  stosb
  RET
endp

gpixel proc far x,y : word
  les di,videoptr
  mov bx,y
  shl bx,1
  add di, word ptr adds [bx]
  cmp curmode,6
  je @@1
  mov ax,x
  shr ax,1
  shr ax,1
  add di,ax
  mov bx,x
  and bx,3
  mov al,es:[di]
  and al,byte ptr gandtablelo [bx]
  mov cl,byte ptr stablo [bx]
  shr al,cl
  RET
@@1:
  mov ax,x
  shr ax,1
  shr ax,1
  shr ax,1
  add di,ax
  mov bx,x
  and bx,7
  mov al,es:[di]
  and al,byte ptr gandtablehi [bx]
  mov cl,byte ptr stabhi [bx]
  shr al,cl
  RET
endp

hline proc far x0,y,x1 : word, color : byte
  mov si,x0
  mov dx,x1
  mov auxvar,dx
  sub auxvar,si
  cmp auxvar,23
  ja  @@2
@@1:
  push si
  push y
  push word ptr color
  call ppixel
  inc si
  cmp si,dx
  jbe @@1
  RET
@@2:
  les di,videoptr
  mov bx,y
  shl bx,1
  add di,word ptr adds [bx]
  shr si,1
  shr si,1
  shr dx,1
  shr dx,1
  cmp curmode,6
  je  @@3
  add di,si
  sub dx,si
  dec dx
  mov bl,color
  xor bh,bh
  mov cl,byte ptr colortable1 [bx]
  mov ch,cl
  mov bx,x0
  and bx,3
  mov al,es:[di]
  mov ah,byte ptr leftandtable1 [bx]
  and al,ah
  not ah
  and cl,ah
  or  al,cl
  mov es:[di],al
  inc di
  push cx
  mov al,ch
  mov cx,dx
  cld
  rep stosb
  pop  cx
  mov bx,x1
  and bx,3
  mov al,es:[di]
  mov ah,byte ptr rightandtable1 [bx]
  and al,ah
  not ah
  and ch,ah
  or  al,ch
  mov es:[di],al
  RET
@@3:
  shr si,1
  shr dx,1
  add di,si
  sub dx,si
  dec dx
  mov bl,color
  xor bh,bh
  mov cl,byte ptr colortable2 [bx]
  mov ch,cl
  mov bx,x0
  and bx,7
  mov al,es:[di]
  mov ah,byte ptr leftandtable2  [bx]
  and al,ah
  not ah
  and cl,ah
  or  al,cl
  mov es:[di],al
  inc di
  push cx
  mov al,ch
  mov cx,dx
  cld
  rep stosb
  pop  cx
  mov bx,x1
  and bx,7
  mov al,es:[di]
  mov ah,byte ptr rightandtable2 [bx]
  and al,ah
  not ah
  and ch,ah
  or  al,ch
  mov es:[di],al
  RET
endp

vline proc far x,y0,y1 : word, color : byte
  les si, videoptr
  mov bx, y0
  shl bx, 1
  cmp curmode, 6
  je  @@2
  mov ax, x
  mov di, ax
  shr di, 1
  shr di, 1
  add di, si
  mov si, ax
  and si, 3
  mov ch, color
  and ch, 3
  mov cl, byte ptr stablo [si]
  shl ch, cl
  mov cl, byte ptr atablo [si]
  mov ax, y1
  shl ax, 1
  mov si, di
@@1:
  mov di, si
  add di, word ptr adds [bx]
  mov dl, es:[di]
  and dl, cl
  or  dl, ch
  mov es:[di], dl
  inc bx
  inc bx
  cmp bx, ax
  jbe @@1
  RET
@@2:
  mov ax, x
  mov di, ax
  shr di, 1
  shr di, 1
  shr di, 1
  add di, si
  mov si, ax
  and si, 7
  mov ch, color
  and ch, 1
  mov cl, byte ptr stabhi [si]
  shl ch, cl
  mov cl, byte ptr atabhi [si]
  mov ax, y1
  shl ax, 1
  mov si, di
@@3:
  mov di, si
  add di, word ptr adds [bx]
  mov dl, es:[di]
  and dl, cl
  or  dl, ch
  mov es:[di], dl
  inc bx
  inc bx
  cmp bx, ax
  jbe @@3
  RET
endp

line proc far x0, y0, x1, y1, c : word
  push ds
  mov dx, ds
  push cs
  pop ds
  mov bx, y1
  sub bx, y0
  jnc nochg
  neg bx
  mov ax, y1
  xchg ax, y0
  mov ax, x1
  xchg ax, x0
  mov x1, ax
nochg:
  mov cx, x1
  sub cx, x0
  jnc cont1
  neg cx
  lea si, mut1+1
  cmp [si], byte ptr 6
  je cont2
  mov [si], byte ptr 6
  mov [si+9], byte ptr 252
  mov [si+12], byte ptr 4fh
  lea si, mut2+1
  mov [si], byte ptr 6
  mov [si+9], byte ptr 252
  mov [si+12], byte ptr 4fh
  jmp cont2
cont1:
  lea si, mut1+1
  cmp [si], byte ptr 2
  je cont2
  mov [si], byte ptr 2
  mov [si+9], byte ptr 63
  mov [si+12], byte ptr 47h
  lea si, mut2+1
  mov [si], byte ptr 2
  mov [si+9], byte ptr 63
  mov [si+12], byte ptr 47h
cont2:
  mov ds, dx
  inc cx
  inc bx
  les di, videoptr
  mov si, y0
  shl si, 1
  add di, word ptr adds [si]
  mov si, x0
  mov dx, si
  and dx, 3
  shr si, 1
  shr si, 1
  add di, si
  cmp cx, bx
  jna begindy
begindx:
  mov ds, bx
  mov bh, 63
  mov bl, byte ptr c
  and bl, 3
  ror bl, 1
  ror bl, 1
  xchg dx, cx
  shl cx, 1
  ror bh, cl
  ror bl, cl
  mov cx, dx
  xor si, si
@@1:
  cmp si, dx
  jb bcont1
  sub si, dx
  cmp di, 8000
  ja subst1
  add di, 8192
  jmp bcont1
subst1:
  sub di, 8112
bcont1:
  mov al, es:[di]
  and al, bh
  or  al, bl
  mov es:[di], al
  mov ax, ds
  add si, ax
  mov al, cl
mut1:
  mov cl, 2
  ror bh, cl
  ror bl, cl
  mov cl, al
  cmp bh, 63
  jne bcont2
nextx1:
  db 47h
bcont2:
  loop @@1
  pop ds
  RET
begindy:
  xchg cx, bx
  mov ds, bx
  mov bh, 63
  mov bl, byte ptr c
  and bl, 3
  ror bl, 1
  ror bl, 1
  xchg dx, cx
  shl cx, 1
  ror bh, cl
  ror bl, cl
  mov cx, dx
  xor si, si
@@2:
  cmp si, dx
  jb bcont3
  sub si, dx
  mov al, cl
mut2:
  mov cl, 2
  ror bh, cl
  ror bl, cl
  mov cl, al
  cmp bh, 63
  jne bcont3
nextx2:
  db 47h
bcont3:
  mov al, es:[di]
  and al, bh
  or  al, bl
  mov es:[di], al
  mov ax, ds
  add si, ax
  cmp di, 8000
  ja subst2
  add di, 8192
  jmp bcont4
subst2:
  sub di, 8112
bcont4:
  loop @@2
  pop ds
  RET
endp

rect proc far x0,y0, x1,y1 : word, color : byte
  push x0
  push y0
  push x1
  push word ptr color
  call hline
  push x0
  push y1
  push x1
  push word ptr color
  call hline
  push x0
  push y0
  push y1
  push word ptr color
  call vline
  push x1
  push y0
  push y1
  push word ptr color
  call vline
  RET
endp

box proc far x0,y0,x1,y1 : word, value : byte
  les  ax,videoptr
  mov  auxvar,ax
  mov  bx,y0
  mov  dx,y1
  shl  bx,1
  shl  dx,1
  mov  cx,x1
  mov  ax,x0
  sub  cx,ax
  inc  cx
  mov  si,ax
  mov  al,value
@@1:
  mov  di,word ptr adds [bx]
  add  di,auxvar
  add  di,si
  push cx
  rep  stosb
  pop  cx
  inc bx
  inc bx
  cmp bx,dx
  jbe @@1
  RET
endp

pbox proc far x0,y0,x1,y1, color : word
  mov si, y0
  mov dx, y1
@@1:
  push si
  push dx
  push x0
  push si
  push x1
  push color
  call hline
  pop dx
  pop si
  inc si
  cmp si,dx
  jb @@1
  RET
endp

getimage proc far x0byte,y0, x1byte,y1 : word, addr : dword
  les  di,addr
  mov  ax, word ptr videoptr
  mov  auxvar,ax
  mov  cx,x1byte
  mov  dx,x0byte
  sub  cx,dx
  inc  cx
  mov  es:[di],cx
  inc  di
  inc  di
  mov  bx,y0
  mov  ax,y1
  push ax
  sub  ax,bx
  inc  ax
  mov  es:[di],ax
  inc  di
  inc  di
  pop  ax
  shl  bx,1
  shl  ax,1
  cld
@@1:
  mov  si,word ptr adds [bx]
  add  si,dx
  add  si,auxvar
  inc  bx
  inc  bx
  push ds
  push cx
  mov  ds,word ptr videoptr + 2
  rep  movsb
  pop  cx
  pop  ds
  cmp  bx,ax
  jbe  @@1
  RET
endp

putimage proc far x0byte,y0,iseg,iofs : word
  push ds
  les  ax,videoptr
  mov  auxvar,ax
  mov  dx,iseg
  mov  si,iofs
  mov  ds,dx
  mov  cx,[si]
  inc  si
  inc  si
  mov  bx,y0
  mov  ax,[si]
  inc  si
  inc  si
  add  ax,bx
  dec  ax
  shl  ax,1
  shl  bx,1
  pop  ds
  cld
@@1:
  push ds
  push cx
  mov  di,word ptr adds [bx]
  add  di,x0byte
  add  di,auxvar
  mov  ds,dx
  rep  movsb
  pop  cx
  pop  ds
  inc  bx
  inc  bx
  cmp  bx,ax
  jbe  @@1
  RET
endp

movimage proc far x,y,sx,sy,xseg,xofs : word, dest : dword
  les  ax, dest
  mov  auxvar,ax
  mov  dx, xseg
  mov  cx, sx
  mov  si, x
  cmp  si, 80
  jb   @@chk
  add  si, sx
  cmp  si, 79
  ja   @@3
  mov  cx, si
  mov  x, 0
  jmp  @@0
@@chk:
  add  si, cx
  cmp  si, 80
  jb   @@0
  mov  cx, 80
  sub  cx, x
@@0:
  mov  bx, y
  mov  ax, sy
  shl  bx, 1
  cld
@@1:
  cmp  bx, 398
  ja   @@2
  push ds
  push cx
  mov  di,word ptr adds [bx]
  add  di,x
  mov  si,di
  add  di,auxvar
  add  si,xofs
  mov  ds,dx
  rep  movsb
  pop  cx
  pop  ds
@@2:
  inc  bx
  inc  bx
  dec  ax
  jnz @@1
@@3:
  RET
endp

imgsize proc far x0byte,y0,x1byte,y1 : word
  mov bx,y0
  mov cx,y1
  sub cx,bx
  inc cx
  mov ax,x1byte
  mov dx,x0byte
  sub ax,dx
  inc ax
  mul cx
  add ax,4
  RET
endp

showimg proc far no : word, image : dword
  dec  no
  cmp  no, 3
  jaFAR @@go
  inc  no
  push no
  call initpoints
  mov  cx, numpoint
  les  di, image
@@point:
  call extdelay
  push cx
  xor  si, si
  mov  ax, numpoint
  sub  ax, cx
  mov  cl, 2
  shl  ax, cl
  mov  bx, ax
@@yloop:
  push cx
  push si
  push bx
  mov  ax, si
  mov  dl, dimy
  mul  dl
  add  al, byte ptr points [bx].ys
  adc  ah, 0
  mov  dl, points [bx].xb
  mov  ch, points [bx].eraser
  mov  cl, points [bx].sepair
  mov  bx, ax
  shl  bx, 1
  mov  bx, word ptr adds [bx]
  add  bl, dl
  adc  bh, 0
  xor  si, si
@@xloop:
  mov  dl, es:[di + bx]
  push es
  mov  ax, 0b800h
  mov  es, ax
  mov  al, es:[bx]
  and  al, ch
  and  dl, cl
  or   al, dl
  mov  es:[bx], al
  pop  es
  add  bx, 5
  inc  si
  cmp  si, 15
  jbe  @@xloop
  pop  bx
  pop  si
  pop  cx
  inc  si
  cmp  si, 9
  jbe  @@yloop
  pop  cx
  loop @@point
@@go:
  RET
endp

putspr proc far x,y : word, image : dword, back : dword

  test spr386, 255
  jnz  @@c1
  jmp  @@c8086
@@c1:
  jmp  @@c386

@@c8086:
  push ds
  les  dx,videoptr
  lds  si,image
  lodsw
  xor  ah, ah
  mov  cx, ax
  mov  ax, x
  mov  bx, ax
  test ax, 8000h
  jnz  @@neg
  shr  ax, 1
  shr  ax, 1
  and  bx, 3
@@cont:
  mov  cs:x0_byte, ax
  shl  bx, 1
  mov  di, [bx + si]
  mov  cs:numbytes, di
  add  si, 8
  add  si, [bx + si]
  mov  bx, y
  shl  bx, 1
@@1:
  push cx
  mov  di,word ptr cs:csegadds [bx]
  mov  cs:temp, di
  add  di, cs:x0_byte
  mov  cx, cs:numbytes
  cmp  bx, 398
  ja nowy
  push bx
@@2:
  mov bx, di
  sub bx, cs:temp
  cmp bx, 80
  jb wx
  inc di
  inc si
  inc si
  jmp nowx
wx:
  lodsw
  push ds
  lds  bx,back
  mov  bl, [bx + di]
  pop  ds
  and  bl,al
  or   bl,ah
  mov  al,bl
  add  di,dx
  stosb
  sub  di,dx
nowx:
  loop @@2
  pop  bx
cnt:
  inc  bx
  inc  bx
  pop  cx
  loop @@1
  pop  ds
  RET
nowy:
  add di, cx
  shl cx, 1
  add si, cx
  jmp cnt
@@neg:
  neg ax
  mov bx, ax
  and bx, 3
  mov bl, byte ptr cs:table [bx]
  add ax, 3
  shr ax, 1
  shr ax, 1
  neg ax
  jmp @@cont

numbytes dw ?
x0_byte  dw ?
temp     dw ?
table    db 0,3,2,1

.386

@@c386:
  cld
  lgs si, Image
  les cx, gs:[si]
  add si, 4
  xor ch, ch
  mov numb, es
  mov ax, word ptr x
  mov bx, ax
  test ax, 8000h
  jnz @@neg2
  shr ax, 2
  and bx, 3

@@cont1:

  mov Xobyte, ax
  xor al, al
  mov ah, leftandtable1 [bx]
  mov initAND_OR, ax
  shl bx, 9
  add bx, offset Tables
  rol ebx, 16
  mov bx, si
  mov si, word ptr y
  shl si, 1
  les dx, VideoPtr
  lfs di, Back
  mov BackOFS, di
  rol ebp, 16
  rol esp, 16
  mov bp, cx

@@line:

  cmp si, 398
  ja  @@noline

  mov di, word ptr Adds [si]
  mov sp, di
  rol esi, 16
  add di, Xobyte
  mov si, BackOFS
  add si, di
  add di, dx
  rol edx, 16
  mov ax, initAND_OR
  mov restAND_OR, ax
  mov cx, numb

@@Xbyte:

  mov ax, di
  sub ax, sp
  cmp ax, 79
  ja  @@skipXbyte

  mov ax, gs:[bx]
  inc bx
  inc bx
  rol ebx, 16
  mov dx, ax
  xlatb
  xchg ah, al
  xlatb
  or ax, restAND_OR
  xchg ax, dx
  add bx, 256
  xlatb
  xchg ah, al
  xlatb
  mov restAND_OR, ax
  sub bx, 256
  rol ebx, 16

  mov al, fs:[si]
  inc si
  and al, dh
  or  al, dl
  stosb

@@contLooping:

  loop @@Xbyte

  mov ax, di
  sub ax, sp
  cmp ax, 79
  ja  @@skipPARCHE

; PARCHE para adicionar otro BYTE:

  mov ax, 255
  rol ebx, 16
  xlatb
  xchg ah, al
  xlatb
  or ax, restAND_OR
  mov dx, ax
  rol ebx, 16

  mov al, fs:[si]
  and al, dh
  or  al, dl
  stosb

; FIN del PARCHE

@@skipPARCHE:

  rol esi, 16
  rol edx, 16

@@cont2:
  inc si
  inc si
  dec bp

  jnz @@line

  rol ebp, 16
  rol esp, 16
  leave

  RETF 0Ch

@@skipXbyte:

  mov ax, gs:[bx]
  inc bx
  inc bx
  rol ebx, 16
  add bx, 256
  xlatb
  xchg ah, al
  xlatb
  mov restAND_OR, ax
  sub bx, 256
  rol ebx, 16
  inc di
  inc si

  jmp @@contLooping

@@noline:

  mov ax, numb
  shl ax, 1
  add bx, ax
  jmp @@cont2

@@neg2:
  neg ax
  mov bx, ax
  and bx, 3
  mov bl, tableNEGD [bx]
  add ax, 3
  shr ax, 2
  neg ax
  jmp @@cont1

endp

.8086

sprsize proc far image : dword
  les  di, image
  mov  al, es:[di]
  xor  ah, ah
  shl  ax, 1
  add  di, 2
  and  spr386, 255
  jnz  @@c386
  xor  dx, dx
  xor  cx, cx
@@1:
  push es
  push di
  push cx
  push ax
  shl  cx, 1
  add  di, cx
  push dx
  xor  dx, dx
  mul  word ptr es:[di]
  pop  dx
  add  dx, ax
  pop  ax
  pop  cx
  pop  di
  pop  es
  inc  cx
  cmp  cx, 4
  jb   @@1
  add  dx, 18
  mov  ax, dx
  RET
@@c386:
  xor dx, dx
  mov bx, es:[di]
  mul bx
  add ax, 4
  RET
endp

freespr proc far image : dword
  les di, image
  les di, dword ptr es:[di]
  push es
  push di
  call sprsize
  les di, image
  push es
  push di
  push ax
  call freemem
  RET
endp

sprDX proc far image : dword
  les di, image
  mov al, es:[di+01]
  RET
endp

sprDY proc far image : dword
  les di, image
  mov al, es:[di+00]
  RET
endp

fillscr proc far value : byte
  les di,videoptr
  mov cx,3f40h
  mov al,value
  cld
  rep stosb
  RET
endp

getscr proc far image : dword, value : byte
  les  di, image
  mov  ax, 16192
  push es
  push di
  push ax
  call getmem
  les  di, image
  les  di, dword ptr es:[di]
  mov  cx, 8096
  mov  al, value
  mov  ah, al
  cld
  rep stosw
  RET
endp

freescr proc far image : dword
  les  di, image
  mov  ax, 16192
  push es
  push di
  push ax
  call freemem
  RET
endp

setscr proc far iseg,iofs : word
  les  ax,videoptr
  mov  auxvar,ax
  mov  dx,iseg
  mov  cx,80
  xor  bx,bx
  mov  ax,398
  cld
@@1:
  push ds
  push cx
  mov  di,word ptr adds [bx]
  mov  si,di
  add  di,auxvar
  add  si,iofs
  mov  ds,dx
  rep  movsb
  pop  cx
  pop  ds
  inc  bx
  inc  bx
  cmp  bx,ax
  jbe  @@1
  RET
endp

shiftR proc far buffer : dword, cbytes : word, fill : byte
  mov cx, cbytes
  les di, buffer
  shr fill, 1
@@1:
  rcr byte ptr es:[di],1
  inc di
  loop @@1
  RET
endp

shiftL proc far buffer : dword, cbytes : word
  les di, buffer
  mov cx, cbytes
  add di, cx
  dec di
  clc
@@1:
  rcl byte ptr es:[di],1
  dec di
  loop @@1
  RET
endp

setmode proc far mode : byte
  mov ah,0
  mov al,mode
  int 10h
  mov cgamode,255
  mov cl,mode
  mov curmode,cl
  cmp cl,6
  je  @@2
  cmp cl,4
  je  @@1
  cmp cl,5
  je  @@1
  mov cgamode,0
  RET
@@1:
  mov scr_x,319
  mov scr_y,199
  mov maxcolor,3
  RET
@@2:
  mov scr_x,639
  mov scr_y,199
  mov maxcolor,1
  RET
endp

savevec proc far vectorcode : word
  cli
  addrvector
  lea di, oldvecs
  add di, ax
  mov ax, es:[si+00]
  mov bx, es:[si+02]
  mov [di+00], ax
  mov [di+02], bx
  sti
  RET
endp

loadvec proc far vectorcode : word
  cli
  addrvector
  lea di, oldvecs
  add di, ax
  mov ax, [di+00]
  mov bx, [di+02]
  mov es:[si+00], ax
  mov es:[si+02], bx
  sti
  RET
endp

getvec proc far vectorcode : word, paddr : dword
  push ds
  addrvector
  lds di, paddr
  mov ax, es:[si+00]
  mov bx, es:[si+02]
  mov word ptr [di+00], ax
  mov word ptr [di+02], bx
  pop ds
  RET
endp

setvec proc far vectorcode : word, newaddr : dword
  addrvector
  mov ax, word ptr newaddr + 00
  mov bx, word ptr newaddr + 02
  cli
  mov es:[si+00], ax
  mov es:[si+02], bx
  sti
  RET
endp

clrbuffer proc far
  mov ax,0
  mov es,ax
  mov ax,es:[41ah]
  mov es:[41ch],ax
  RET
endp

keyON proc far
  mov dx,21h
  in  al,dx
  and al,253
  out dx,al
  RET
endp

keyOFF proc far
  mov dx,21h
  in  al,dx
  or  al,2
  out dx,al
  RET
endp

keyint proc far
  push  ax
  push  bx
  push  ds
  mov   ax,word ptr cs:datseg
  mov   ds,ax
  in    al,60h
  xor   ah,ah
  mov   bx,ax
  cmp   al,128
  jaFAR keyup

  kon Escape,_Escape
  kon BackSpc,_BackSpc
  kon Tab,_Tab
  kon Ent,_Ent
  kon Ctrl,_Ctrl
  kon ShiftLeft,_ShiftLeft
  kon ShiftRight,_ShiftRight
  kon Alt,_Alt
  kon Space,_Space
  kon F1,_F1
  kon F2,_F2
  kon F3,_F3
  kon F4,_F4
  kon F5,_F5
  kon F6,_F6
  kon F7,_F7
  kon F8,_F8
  kon F9,_F9
  kon F10,_F10
  kon UpLeft,_UpLeft
  kon Up,_Up
  kon UpRight,_UpRight
  kon Left,_Left
  kon Center,_Center
  kon Right,_Right
  kon DownLeft,_DownLeft
  kon Down,_Down
  kon DownRight,_DownRight

@@contaddr:
  mov  scancode, al
  mov  byte ptr scan [bx], 1
  jmp  restint
keyup:
  sub  al, 128
  mov  scancode, al

  koff Escape,_Escape
  koff BackSpc,_BackSpc
  koff Tab,_Tab
  koff Ent,_Ent
  koff Ctrl,_Ctrl
  koff ShiftLeft,_ShiftLeft
  koff ShiftRight,_ShiftRight
  koff Alt,_Alt
  koff Space,_Space
  koff F1,_F1
  koff F2,_F2
  koff F3,_F3
  koff F4,_F4
  koff F5,_F5
  koff F6,_F6
  koff F7,_F7
  koff F8,_F8
  koff F9,_F9
  koff F10,_F10
  koff UpLeft,_UpLeft
  koff Up,_Up
  koff UpRight,_UpRight
  koff Left,_Left
  koff Center,_Center
  koff Right,_Right
  koff DownLeft,_DownLeft
  koff Down,_Down
  koff DownRight,_DownRight

@@contaddr2:
  sub  bx, 128
  mov  byte ptr scan [bx], 0
restint:
  in   al,61h
  or   al,80h
  out  61h,al
  in   al,61h
  and  al,7fh
  out  61h,al
  mov  al,20h
  out  20h,al
  pop  ds
  pop  bx
  pop  ax
  iRET
endp

initscan proc far
  mov scancode, 0
  mov ax, ds
  mov es, ax
  lea cx, endmark
  lea di, Escape
  sub cx, di
  xor ax, ax
  cld
  rep stosb
  lea di, scan
  mov cx, 70H
  rep stosb
  RET
endp

initkeyboard proc far
  lea di, oldvecs
  mov si, 36
  add di, si
  xor ax, ax
  mov es, ax
  mov ax, word ptr es:[si+00]
  mov bx, word ptr es:[si+02]
  mov [di+00], ax
  mov [di+02], bx
  mov ax, seg keyint
  lea bx, keyint
  cli
  mov word ptr es:[si+00], bx
  mov word ptr es:[si+02], ax
  call initscan
  sti
  RET
endp

reskeyboard proc far
  lea di, oldvecs
  mov si, 36
  add di, si
  xor ax, ax
  mov es, ax
  mov ax, [di+00]
  mov bx, [di+02]
  mov word ptr es:[si+00], ax
  mov word ptr es:[si+02], bx
  RET
endp

clockint proc far
  push es
  push di
  push ax
  les  di,cs:clockptr
  inc  word ptr es:[di+00]
  adc  word ptr es:[di+02], 0
  mov  al,20h
  out  20h,al
  pop  ax
  pop  di
  pop  es
  iRET
clockptr  dd 0:46ch
endp

initclock proc far
  lea di, oldvecs
  mov si, 32
  add di, si
  xor ax, ax
  mov es, ax
  mov ax, word ptr es:[si+00]
  mov bx, word ptr es:[si+02]
  mov [di+00], ax
  mov [di+02], bx
  mov ax, seg clockint
  lea bx, clockint
  mov word ptr es:[si+00], bx
  mov word ptr es:[si+02], ax
  RET
endp

resclock proc far
  lea di, oldvecs
  mov si, 32
  add di, si
  xor ax, ax
  mov es, ax
  mov ax, [di+00]
  mov bx, [di+02]
  mov word ptr es:[si+00], ax
  mov word ptr es:[si+02], bx
  RET
endp

progtimer0 proc far divisor : word
  cli
  cmp divisor, 0
  jne @@1
  mov clockfreq,18
@@1:
  mov dx, 43H
  mov al, 36H
  out dx, al
  mov dx, 40H
  mov ax, divisor
  out dx, al
  mov al, ah
  out dx, al
  sti
  RET
endp

timerfreq proc far freq : word
  mov ax, freq
  mov clockfreq, ax
  mov dx, 12H
  mov ax, 34dcH
  mov bx, freq
  div bx
  push ax
  call progtimer0
  RET
endp

waittime proc far time : word
  xor ax, ax
  mov es, ax
  mov cx, es:[0046cH]
  mov dx, time
@@1:
  mov ax, es:[0046cH]
  sub ax, cx
  cmp ax, dx
  jb @@1
  RET
endp

waittimeOK proc far time : word
  xor ax, ax
  mov es, ax
  mov cx, es:[0046cH]
  sub cx, lastclock
  cmp cx, time
  jb  @@1
  or  ax, 1
  RET
@@1:
  xor ax, ax
  RET
endp

seconds proc far
  xor dx, dx
  mov es, dx
  mov ax, es:[0046cH]
  mov bx, clockfreq
  div bx
  mov bx, 60
  xor dx, dx
  div bx
  mov ax, dx
  RET
endp

minutes proc far
  xor dx, dx
  mov es, dx
  mov ax, es:[0046cH]
  mov bx, clockfreq
  div bx
  xor dx, dx
  mov bx, 60
  div bx
  mov bx, 60
  xor dx, dx
  div bx
  mov ax, dx
  RET
endp

syncro proc far
  cli
  mov  dx,03DAH
@@1:
  in   al,dx
  test al,8
  jz   @@1
  sti
  RET
endp

datseg proc far
  dw ?
endp

csegadds proc far
  dw 200 dup (?)
endp

initcode proc far
  xor ax, ax
  push ax
  call progtimer0
  lea di, datseg
  mov cs:[di], ds
  xor cx, cx
  xor si, si
@@1:
  mov bx, cx
  and bx, 1
  mov ax, 8192
  xor dx, dx
  mul bx
  mov di, ax
  mov bx, cx
  shr bx, 1
  mov ax, 80
  xor dx, dx
  mul bx
  add ax, di
  mov word ptr adds [si], ax
  inc si
  inc si
  inc cx
  mov bx, 200
  cmp cx, bx
  jb @@1
  lea si, adds
  mov ax, cs
  mov es, ax
  lea di, csegadds
  mov cx, 200
  cld
  rep movsw
  mov ax, seg asciitab
  lea bx,     asciitab
  mov asciiseg, ax
  mov asciiofs, bx
  call initscan
  push ds
  push ds
  pop  es
  xor  ax, ax
  mov  ds, ax
  mov  si, ax
  lea  di, oldvecs
  mov  cx, 1024
  cld
  rep movsb
  pop  ds
  RET
endp

version proc far
  push ds
  push cs
  pop ds
  lea dx, copyright
  mov ah, 9
  int 21h
  pop ds
  RET
copyright:
  db 10,13
  db 'CTOOLS 1.1 ( low level routines to access video memory on CGA video cards )'
  db 10,13
  db '(C) 1997 ® Jos‚ Humberto Cifuentes & Eduardo Lago Aguilar ¯'
  db 10,13,'$',26
endp

.386


end
