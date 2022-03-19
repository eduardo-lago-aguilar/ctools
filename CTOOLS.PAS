{*****************************************************************************}
{    - CTOOLS.PAS version 1.1 (c) 1997 Eduardo Lago & Jos‚ H Cifuentes -      }
{   Turbo Pascal Unit to access video memory and control some PC functions    }
{                                                                             }
{    Note: Ctools must be used only with CGA's 320x200-4 color mode OR        }
{                                        CGA's 640x200-2 color mode ...       }
{    TinoSoft (C) 1997                                                        }
{*****************************************************************************}

{$A+,B-,D-,E-,F-,I-,L-,N-,O-,R-,S-,V-}
{$L CTOOLS.OBJ}
{$L ASCII.OBJ}
{$L CLOCKASM.OBJ}


  UNIT CTOOLS;

  INTERFACE   { * public declarations * }

  USES DOS;

    type texttype    = (IR, NOR, IL);
         ttable2     = array [0..1] of byte;
         ttable4     = array [0..3] of byte;
         ttable8     = array [0..7] of byte;

    const
      cgamode        : boolean = FALSE;
      video          : pointer = ptr ($B800,0);
      videoptr       : pointer = ptr ($B800,0);
      colortable2    : ttable2 = (000,255);
      tableNEGD      : ttable4 = (000,003,002,001);
      atablo         : ttable4 = (063,207,243,252);
      stablo         : ttable4 = (006,004,002,000);
      bandtable      : ttable4 = (016,032,064,128);
      leftandtable1  : ttable4 = (000,192,240,252);
      rightandtable1 : ttable4 = (063,015,003,000);
      colortable1    : ttable4 = (000,085,170,255);
      gandtablelo    : ttable4 = (192,048,012,003);
      atabhi         : ttable8 = (127,191,223,239,247,251,253,254);
      stabhi         : ttable8 = (007,006,005,004,003,002,001,000);
      gandtablehi    : ttable8 = (128,064,032,016,008,004,002,001);
      leftandtable2  : ttable8 = (000,128,192,224,240,248,252,254);
      rightandtable2 : ttable8 = (127,063,031,015,007,003,001,000);
      mainfreq       : word = 19;
      freq           : word = 25;
      clock_hz       = 4608;
      ajuste         : longint = 0;

    var
      int8      : pointer;
      temptime  : longint;
      scancode  : byte;
      Escape,
      BackSpc,
      Tab,
      Ent,
      Ctrl,
      ShiftLeft,
      ShiftRight,
      Alt, Space,
      F1, F2, F3, F4, F5,
      F6, F7, F8, F9, F10,
      UpLeft, Up, UpRight,
      Left,  Center,  Right,
      DownLeft, Down, DownRight,

      endmark     : boolean;

      lastclock,
      clockfreq,
      scr_x,
      scr_y,
      asciiseg,
      asciiofs    : word;
      curmode,
      maxcolor,
      iocode      : byte;
      adds        : array [0..199] of word;
      scan        : array [0..$70] of boolean;
      clock       : longint absolute $0000:$046c;
      intvecs     : array [0..$FF] of pointer absolute $0000:$0000;
      oldvecs     : array [0..$FF] of pointer;
      spr386      : boolean;

      { graphics screen tools }

      procedure ppixel (x, y : word; color : byte);
      function  gpixel (x, y : word) : byte;
      procedure hline (x0, y0, x1 : word; color : byte);
      procedure vline (x0, y0, y1 : word; color : byte);
      procedure line (x0, y0, x1, y1 : integer; color : byte);
      procedure rect (x0, y0, x1, y1 : word; color : byte);
      procedure ellipse (x, y, Xrad, Yrad : integer; color : byte);
      procedure box (x0, y0, x1, y1 : word; value : byte);
      procedure pbox (x0, y0, x1, y1 : word; color : byte);
      procedure getimage (x, y, x1, y1 : word; VAR buffer);
      procedure putimage (x, y : word; VAR buffer);
      procedure movimage (x, y, lx, ly : word; VAR buffer, dest);
      function  imgsize (x, y, x1, y1 : word) : word;
      procedure putspr  (x, y : word; VAR image, back);
      procedure fillscr (value : byte);
      procedure setscr (VAR buffer);
      procedure shiftr (VAR buffer; times : word; fill : boolean);
      procedure shiftl (VAR buffer; times : word);
      procedure setmode (mode  : byte);

      { keyboard I/O, and control procedures }

      procedure savevec (vector : word );
      procedure loadvec (vector : word );
      procedure getvec  (vector : word; VAR buffer : pointer );
      procedure setvec  (vector : word; buffer : pointer );
      procedure clrbuffer;
      procedure keyon;
      procedure keyoff;
      procedure keyint;
      procedure initscan;
      procedure initkeyboard;
      procedure reskeyboard;
      procedure clockint;
      procedure initclock;
      procedure resclock;
      procedure progtimer0 (divisor : word);
      procedure timerfreq  (newfreq : word);
      procedure waittime   (time : word );
      function  waittimeOK (time : word ) : boolean ;
      function  seconds : word;
      function  minutes : word;
      procedure syncro;

      { auxiliar data procedures to macro assembler }

      procedure datseg;
      procedure csegadds;
      procedure initcode;
      procedure version;
      procedure asciitab;

      { another useful procedures, including sprites, fonts, etc ... }

      procedure aspr (VAR psprs; address  : pointer);
      procedure aimg (VAR pimgs; address  : pointer);
      function  sprsize (VAR sprite) : word;
      function  sprsize3 (VAR sprite) : word;
      function  sprDX   (VAR sprite) : byte;
      function  sprDY   (VAR sprite) : byte;
      procedure newspr  (VAR oldspr; VAR newspr : pointer; ix, iy : boolean);
      procedure initsprs(filename   : string; VAR psprs, list; numspr : byte);
      procedure initimgs(filename   : string; VAR pimgs, list; numimg : byte);
      procedure donesprs(VAR psprs, list; numspr : byte);
      procedure doneimgs(VAR pimgs, list; numimg : byte);
      procedure freespr (VAR sprite : pointer);
      procedure getscr  (VAR screen : pointer; code : byte);
      procedure loadPIC (Fname : string; VAR p : pointer; PIC : boolean);
      procedure freescr (VAR screen : pointer);
      procedure textxy  (x, y, color, fontsize, sx, sy : word;
                         ttype : texttype; msg : string );
      procedure showimg (no : word; VAR image);
      procedure SetAdds (Normal : boolean);

      procedure ajust;
      procedure initadapter;
      procedure restadapter;
      function  getclock  : longint;
      procedure EGApalette (old, new : byte);
      procedure CGApalette (t : byte);

 IMPLEMENTATION

    procedure ppixel;                                      external;
    function  gpixel;                                      external;
    procedure hline;                                       external;
    procedure vline;                                       external;
    procedure line;                                        external;
    procedure rect;                                        external;
    procedure box;                                         external;
    procedure pbox;                                        external;
    procedure getimage;                                    external;
    procedure putimage;                                    external;
    procedure movimage;                                    external;
    function  imgsize;                                     external;
    procedure putspr;                                      external;
    procedure freespr;                                     external;
    function  sprsize;                                     external;
    function  sprDX;                                       external;
    function  sprDY;                                       external;
    procedure fillscr;                                     external;
    procedure getscr;                                      external;
    procedure freescr;                                     external;
    procedure setscr;                                      external;
    procedure shiftr;                                      external;
    procedure shiftl;                                      external;
    procedure setmode;                                     external;
    procedure savevec;                                     external;
    procedure loadvec;                                     external;
    procedure getvec;                                      external;
    procedure setvec;                                      external;
    procedure clrbuffer;                                   external;
    procedure keyON;                                       external;
    procedure keyOFF;                                      external;
    procedure keyint;                                      external;
    procedure initscan;                                    external;
    procedure initkeyboard;                                external;
    procedure reskeyboard;                                 external;
    procedure clockint;                                    external;
    procedure initclock;                                   external;
    procedure resclock;                                    external;
    procedure progtimer0;                                  external;
    procedure timerfreq;                                   external;
    procedure waittime;                                    external;
    function  waittimeOK;                                  external;
    function  seconds;                                     external;
    function  minutes;                                     external;
    procedure syncro;                                      external;
    procedure datseg;                                      external;
    procedure csegadds;                                    external;
    procedure initcode;                                    external;
    procedure version;                                     external;
    procedure asciitab;                                    external;
    procedure showimg;                                     external;
    function  getclock  : longint;                         external;

    var tables : array [0..3,1..2,0..255] of byte;

    procedure inittables;
    const table2 : ttable4 = (0, 3, 15, 63);
    var i, j     : byte;
    begin
      for j:=0 to 3 do
        for i:=0 to 255 do begin
          tables [j, 1, i]:=i shr (2*j);
          tables [j, 2, i]:=(i and table2 [j]) shl (8-2*j)
        end
    end;

    procedure extdelay;
    begin
    end;

    procedure timerISR;  interrupt;
    begin
     inc (CTOOLS.clock);
     port [$20]:=$20;
     if CTOOLS.clock>60000 then begin
      CTOOLS.clock:=0;
      temptime:=0;
     end;
    end;

    procedure ajust;
    begin
     ajuste:=clock_hz div freq * (mainfreq div 18);
    end;

    procedure initadapter;
    begin
     ajust;
     getvec (8, int8);
     setvec (8, @timerISR);
     CTOOLS.clock:=0;
    end;

    procedure restadapter;
    begin
     setvec(8,int8);
    end;

    procedure cgapalette (t : byte);
    const
      reg : array [1..3, 1..3] of byte = ((14, 14, 1), (4, 4, 0), (0, 0, 0));
    var r : registers;
    begin
      r.AX:=$B00 or reg [t, 1];
      r.BX:=(reg [t, 3] shl 8) or reg [t, 2];
      Intr ($10, r)
    end;

    procedure EGApalette (old, new : byte);
    var t : byte;
    begin
      t:=port [$3da];
      port [$3c0]:=old;
      port [$3c0]:=new;
      t:=port [$3da];
      port [$3c0]:=32;
    end;

    procedure getmem (VAR p : pointer; size : word);
    begin
      SYSTEM.getmem (p, size)
    end;

    procedure freemem (VAR p : pointer; size : word);
    begin
      SYSTEM.freemem (p, size)
    end;

    procedure blockread (VAR f : file; VAR buffer; count : word);
    begin
      SYSTEM.blockread (f, buffer, count);
      IOcode:=IOresult
    end;

    procedure textXY;
    var
      i,j,k, value,u,o  : byte;
      add,calcx, calcy  : word;
      des               : shortint;

    begin
      des  := byte (ttype) - 1;
      for i:=1 to byte ( msg [0] ) do
        begin
          add:= byte ( msg [i] ) * 8 + asciiofs;
          for j:=0 to 7 do
            for k:=0 to 7 do
              if mem [asciiseg:add+j] and gandtablehi [k] <> 0 then
                begin
                  calcx:=x+(i-1)*fontsize+k*sx+j*des;
                  calcy:=y+j*sy;
                  for u:=0 to sx - 1 do
                    for o:=0 to sy - 1 do
                      ppixel (calcx+u,calcy+o,color);
                end;
        end;
    end;

    procedure ellipse;
    var
      EX, EY : integer;
      YRadSqr, YRadSqr2, XRadSqr, XRadSqr2, D, DX, DY : longint;

    begin
      EX:=Xrad;
      Xrad:=Yrad;
      Yrad:=EX;
      EX:=0;
      EY:=XRad;
      YRadSqr:=longint (Yrad)*Yrad;
      YRadSqr2:=2*YRadSqr;
      XRadSqr:=longint (Xrad)*Xrad;
      XRadSqr2:=2*XRadSqr;
      D:=XRadSqr - YRadSqr*Xrad + YRadSqr div 4;
      DX:=0;
      DY:=YRadSqr2*Xrad;
      ppixel (x, y-EY, color);
      ppixel (x, y+EY, color);
      ppixel (x-Yrad, y, color);
      ppixel (x+Yrad, y, color);
      while (DX < DY) do begin
        if (D > 0) then begin
          dec (EY);
          dec (DY, YRadSqr2);
          dec (D, DY);
        end;
        inc (EX);
        inc (DX, XRadSqr2);
        inc (D, XRadSqr+DX);
        ppixel (x+EX, y+EY, color);
        ppixel (x+EX, y-EY, color);
        ppixel (x-EX, y+EY, color);
        ppixel (x-EX, y-EY, color);
      end;
      inc (D, (3*(YRadSqr-XRadSqr) div 2 - (DX + DY)) div 2);
      while (EY > 0) do begin
        if (D < 0) then begin
          inc (EX);
          inc (DX, XRadSqr2);
          inc (D, XRadSqr+DX);
        end;
        dec (EY);
        dec (DY, YRadSqr2);
        inc (D, YRadSqr-DY);
        ppixel (x+EX, y+EY, color);
        ppixel (x+EX, y-EY, color);
        ppixel (x-EX, y+EY, color);
        ppixel (x-EX, y-EY, color);
      end;
    end;

    const
      inv : array [0..255] of byte =

    (0,64,128,192,16,80,144,208,32,96,160,224,48,112,176,240,4,68,132,
     196,20,84,148,212,36,100,164,228,52,116,180,244,8,72,136,200,24,88,
     152,216,40,104,168,232,56,120,184,248,12,76,140,204,28,92,156,220,
     44,108,172,236,60,124,188,252,1,65,129,193,17,81,145,209,33,97,161,
     225,49,113,177,241,5,69,133,197,21,85,149,213,37,101,165,229,53,117,
     181,245,9,73,137,201,25,89,153,217,41,105,169,233,57,121,185,249,13,
     77,141,205,29,93,157,221,45,109,173,237,61,125,189,253,2,66,130,194,
     18,82,146,210,34,98,162,226,50,114,178,242,6,70,134,198,22,86,150,
     214,38,102,166,230,54,118,182,246,10,74,138,202,26,90,154,218,42,106,
     170,234,58,122,186,250,14,78,142,206,30,94,158,222,46,110,174,238,62,
     126,190,254,3,67,131,195,19,83,147,211,35,99,163,227,51,115,179,243,7,
     71,135,199,23,87,151,215,39,103,167,231,55,119,183,247,11,75,139,203,
     27,91,155,219,43,107,171,235,59,123,187,251,15,79,143,207,31,95,159,
     223,47,111,175,239,63,127,191,255);

     function sprsize3 (VAR sprite) : word;
     type tc  = record
       dy, dx : byte;
       numb   : word
     end;
     var    p : pointer;
     begin
       p:=@sprite;
       sprsize3:=tc (p^).dy * tc (p^).numb * 2 + 4
     end;

     procedure newspr;

       procedure invert (VAR sprite);
       var
         dimx, dimy,
         i, j, d, k  : byte;
         p2          : pointer;
         ands, ors   : array [1..101, 1..30] of byte;

         function dofs (disp : byte) : word;
         begin
           dofs:=memw [seg (sprite):ofs (sprite)+10+disp*2]+10
         end;

         function cbytes (disp : byte) : word;
         begin
           cbytes:=memw [seg (sprite):ofs (sprite)+2+disp*2]
         end;

         procedure swapbytes (VAR bytes; num : word; a : boolean);
         var
           i, t : byte;

         begin
           for i:=1 to (num*4-dimx)*2 do shiftR (bytes, num, a);
           for i:=1 to num div 2 do
             begin
               t:=mem [seg (bytes):ofs (bytes)+i-1];
               mem [seg (bytes):ofs (bytes)+i-1]:=
                 inv [mem [seg (bytes):ofs (bytes)+num-i]];
               mem [seg (bytes):ofs (bytes)+num-i]:=inv [t]
             end;
           if num mod 2 = 1 then
             mem [seg (bytes):ofs (bytes) + num div 2]:=
               inv [mem [seg (bytes):ofs (bytes) + num div 2]]
         end;

       const
         precs : array [0..1, FALSE..TRUE] of word =
           ((17, 3),  (3, 0));

       var
         cb : ttable4;

       begin
         p2:=@sprite;
         dimy:=byte (p2^);
         inc (word (p2));
         dimx:=byte (p2^);
         inc (word (p2), precs [0, spr386]);
         for i:=0 to 3 do cb [i]:=cbytes (i);
         for j:=1 to dimy do
           begin
             for i:=1 to cb [0] do
               begin
                 ands [j, i]:=byte (p2^); inc (word (p2));
                 ors  [j, i]:=byte (p2^); inc (word (p2));
               end;
             ands [j, i+1]:=$ff;
             ors  [j, i+1]:=$00
           end;
         if ix then
           for j:=1 to dimy do
             begin
               swapbytes (ands [j], cb [0], TRUE);
               swapbytes (ors  [j], cb [0], FALSE)
             end;
         for d:=0 to precs [1, spr386] do
           begin
             p2:=@sprite;
             inc (word (p2), dofs (d) * byte(not spr386) +
                                    4 * byte(    spr386));
             if d > 0 then
               for j:=1 to dimy do
                 for k:=1 to 2 do
                   begin
                     shiftR (ands [j], cb [d], TRUE);
                     shiftR (ors  [j], cb [d], FALSE)
                   end;
             if not iy then
               for j:=1 to dimy do
                 for i:=1 to cb [d] do
                   begin
                     byte (p2^):=ands [j, i]; inc (word (p2));
                     byte (p2^):=ors  [j, i]; inc (word (p2))
                   end else
                     for j:=1 to dimy do
                       for i:=1 to cb [d] do
                         begin
                           byte (p2^):=ands [dimy+1-j, i];
                           inc (word (p2));
                           byte (p2^):=ors  [dimy+1-j, i];
                           inc (word (p2))
                         end
           end
       end;

    begin
      getmem (newspr, sprsize (oldspr));
      move   (oldspr, newspr^, sprsize (oldspr));
      invert (newspr^)
    end;

    Type
      castP = array [1..100] of pointer;
      castB = array [1..100] of byte;
      castW = array [1..100] of word;
      shead = record
        numspr : word;
        jmptab : array [1..255] of longint;
      end;
      shead2 = record
        dy, dx : byte;
        nbytes : array [0..3] of word;
      end;
      ihead  = record
        numimg : word;
        table  : array [1..40] of record
          JMPrel,
          IMGsiz : word;
        end
      end;

    procedure aspr;
    var i : word;
        p : pointer;
    begin
      p:=address;
      for i:=1 to shead (p^).numspr do
        castP (pSprs) [i]:=PTR (seg (p^),
          ofs (p^) + shead (p^).jmptab [i])
    end;

    procedure aimg;
    var i : word;
        p : pointer;
    begin
      p:=address;
      for i:=1 to ihead (p^).numimg do
        castP (pimgs) [i]:=PTR (seg (p^), ofs (p^) +
          ihead (p^).table [i].JMPrel)
    end;

    procedure InitSprs;
    const hsize : array [FALSE..TRUE] of byte = (10, 4);
    var f       : file;
        i       : word;
        Head    : Shead;
        Head2   : Shead2;
        SprNo   : byte;
        p       : pointer;

    begin
      if numspr = 0 then exit;
      assign (f, Filename); reset (f, 1);
      iocode:=IOresult;
      if iocode <> 0 then exit;
      seek (f, 0);
      blockread (f, Head, 2);
      if iocode <> 0 then exit;
      blockread (f, Head.jmptab, Head.numspr * 4);
      if iocode <> 0 then exit;
      for i:=1 to numspr do begin
        SprNo:=castB (list) [i];
        seek (f, Head.jmptab [SprNo]);
        blockread (f, Head2, Hsize [spr386]);
        if iocode <> 0 then exit;
        getmem (castP (PSprs) [SprNo], sprsize (Head2));
        P:=castP (PSprs) [SprNo];
        move (Head2, P^, Hsize [spr386]);
        inc (word (P), Hsize [spr386]);
        blockread (f, P^, sprsize (Head2) - Hsize [spr386]);
        if iocode <> 0 then exit;
      end;
      close (f)
    end;

    procedure DoneSprs;
    var i,
        SprNo : byte;
        P     : pointer;

    begin
      if numspr = 0 then exit;
      for i:=1 to numspr do begin
        SprNo:=castB (list) [i];
        P:=castP (PSprs) [SprNo];
        freemem (P, sprsize (P^))
      end;
    end;

    procedure InitImgs;
    var
      f        : file;
      head     : ihead;
      p        : pointer;
      i, ImgNo : byte;

    begin
      assign (f, filename); reset (f, 1);
      iocode:=IOresult;
      if iocode <> 0 then exit;
      blockread (f, head, 2);
      if iocode <> 0 then exit;
      blockread (f, head.table, head.numimg * 4);
      if iocode <> 0 then exit;
      for i:=1 to numimg do begin
        ImgNo:=castB (list) [i];
        getmem (castP (Pimgs) [ImgNo], head.table [ImgNo].IMGsiz);
        p:=castP (Pimgs) [ImgNo];
        seek (f, head.table [ImgNo].JMPrel);
        blockread (f, P^, head.table [ImgNo].IMGsiz);
        if iocode <> 0 then exit
      end;
      close (f)
    end;

    procedure DoneImgs;
    var
      i, ImgNo : byte;
      P        : pointer;

      function s (VAR img) : word;
      begin
        s:=castW (img) [1] *
           castW (img) [2] + 4
      end;

    begin
      for i:=1 to numimg do begin
        ImgNo:=castB (list) [i];
        P:=castP (Pimgs) [ImgNo];
        freemem (P, s (P^))
      end
    end;

    procedure LoadPIC;
    var f : file;
    begin
      getscr (p, 0);
      assign (f, Fname); reset (f, 1); seek (f, byte (PIC)*7);
      iocode:=IOresult;
      if iocode <> 0 then exit;
      blockread (f, p^, 16192);
      iocode:=IOresult;
      if iocode <> 0 then exit;
      close (f)
    end;

  const
    dimX    = 20;
    dimY    = 20;
    eratab  : ttable4 = (63, 207, 243, 252);
    septab  : ttable4 = (192, 48, 12, 3);

  var
    points : array [1..DimX * DimY] of
      record
        YS, XB,
        eraser,
        sepair : byte
      end;
    TmpRect : array [0..DimY-1, 0..DimX-1] of boolean;

    procedure InitPoints (Efect : byte);
    var
      rx, ry, up, dw,
      lf, rg, dx, dy,
      k,  x,  y       : integer;

      procedure Update;
      begin
        with Points [k] do
          begin
            YS:=ry;
            XB:=rx shr 2;
            Eraser:=EraTab [rx and 3];
            Sepair:=SepTab [rx and 3]
          end
      end;

    begin
      up:=0; dw:=dimY;
      lf:=0; rg:=dimX;
      rx:=0; ry:=0;
      dx:=1; dy:=0;
      fillchar (TmpRect, sizeof (TmpRect), FALSE);
      case Efect of
        1, 2:
          for k:=1 to DimX * DimY do
            begin
              if Efect = 1 then
                begin
                  repeat
                    rx:=random (DimX);
                    ry:=random (DimY)
                  until not TmpRect [ry, rx];
                  TmpRect [ry, rx]:=TRUE
                end;
              UpDate;
              if Efect = 2 then
                begin
                  case dx of
                    1: if rx + dx >= rg then
                      begin dx:=0; dy:=1; dec (rg) end;
                   -1: if rx + dx < lf then
                      begin dx:=0; dy:=-1; inc (lf) end
                  end;
                  case dy of
                    1: if ry + dy >= dw then
                      begin dy:=0; dx:=-1; dec (dw) end;
                   -1: if ry + dy <= up then
                      begin dy:=0; dx:=1; inc (up) end
                  end;
                  inc (rx, dx);
                  inc (ry, dy)
                end
            end;
        3, 4:
            begin
              for k:=1 to DimX * DimY do
                begin
                  UpDate;
                  if efect = 3 then
                    begin
                      if rx < DimX-1 then inc (rx) else
                        begin
                          rx:=0;
                          inc (ry)
                        end
                    end else
                      begin
                        if ry < DimY-1 then inc (ry) else
                          begin
                            ry:=0;
                            inc (rx)
                          end
                      end
                end
            end
      end
    end;

    var nadds : array [0..1, 0..199] of word;

    procedure InitAdds;
     var
      i     : word;
    begin
     for i:=0 to 199 do nadds [0, i]:=(i mod 2) * 8192 + (i div 2) * 80;
     for i:=0 to 199 do nadds [1, i]:=nadds [0, 199-i];
    end;

    procedure SetAdds;
    begin
     move (nadds[byte(not Normal)], adds, sizeof (adds));
     move (nadds[byte(not Normal)], @csegadds^, sizeof (adds));
    end;

  begin
   spr386:=FALSE;
   inittables;
   initadds;
   initcode
  end.{*****************************************************************************}
{    - CTOOLS.PAS version 1.1 (c) 1997 Eduardo Lago & Jos‚ H Cifuentes -      }
{   Turbo Pascal Unit to access video memory and control some PC functions    }
{            