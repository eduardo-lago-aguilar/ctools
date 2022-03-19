.model tpascal

  cmode EQU 43h
  cdata EQU 40h

  public getclock

.code

  getclock proc far
    xor ah,ah
    int 1ah
    mov ah,dl
    mov dl,dh
    mov dh,cl
    xor al,al
    out cmode,al
    inc al
    out cmode,al
    in al,cdata
    in al,cdata
    neg al
    RET
  endp

end
