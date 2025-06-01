Program ir_decode;

{$IFDEF WINDOWS}
   Uses WinCrt, WinDos, WinProcs;
{$ELSE}
   uses DOS, CRT;
{$ENDIF}

const
   {weight : array [1..8] of byte = (128,64,32,16,8,4,2,1);  {}
   weight : array [1..8] of byte = (1,2,4,8,16,32,64,128);  {}

type
   pulse=record
      name    : string;
      sync_hi,
      sync_lo : real;
      data    : array [1..4] of byte;
      exit    : real;
   end;

var
   codes    : array [1..150] of pulse;
   temp     : pulse;
   pointer,
   pointer1,
   pointer2 : integer;
   infile,
   outfile  : text;
   infname,
   outfname : string;
   line     : string;
   linelen  : integer;
   crsr     : integer;
   avg0,
   avg1     : real;
   i        : integer;
   sortq    : string;

procedure openfile;

begin
   assign(infile,infname+'.txt');
   reset(infile);
   assign(outfile,infname+'.out');
   rewrite(outfile);
end;

procedure closefile;

begin
   close(infile);
   close(outfile);
end;

function tohexbyte(a:byte):string;

const h:array [0..15] of char = ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');

begin
   tohexbyte:=h[a div 16]+h[a mod 16];
end; { function tohexbyte }

function getnum(line : string) : real;

var
   str : string;
   num : real;
   i   : integer;

begin
   str:='';
   while not(line[crsr] in ['.','0'..'9']) do inc(crsr);  { skip non-digits }
   while (line[crsr] in ['.','0'..'9']) do begin
      str:=str+line[crsr];
      inc(crsr);
   end; { while line[crsr] < '.' }
   val(str,num,i);
   if i>0 then begin
      writeln;
      writeln('Error in data (100).');
      writeln;
      halt;
   end; { if i>0 }
   getnum:=num;
end;  { function getnum }

procedure get4bytes;

begin
end; { procedure get4bytes }

procedure readcode;

var name  : string;
    num   : real;
    pass  : integer;
    data  : byte;
    bits  : integer;

begin
   pass:=1;
   data:=0;
   bits:=8;
   pointer:=0;
   while (not EOF(infile)) and (pass<99) do begin
      readln(infile,line);
      linelen:=length(line);
      crsr:=1;
      name:='';
      while (line[crsr]<'!') and (crsr<linelen) do inc(crsr);
      if crsr<linelen then begin
         case pass of
            1: if upcase(line[crsr]) in ['A'..'Z'] then begin
                  repeat
                     name:=name+line[crsr];
                     inc(crsr);
                  until crsr>linelen;
                  inc(pass);
                  inc(pointer);
                  codes[pointer].name:=name;
               end;
            2: begin
                  inc(crsr);
                  inc(crsr);
                  inc(pass);
                  codes[pointer].sync_hi:=getnum(line);
               end;
            3: begin
                  inc(crsr);
                  inc(crsr);
                  inc(pass);
                  codes[pointer].sync_lo:=getnum(line);
               end;
         4..7: begin    { LSB first !!! }
                  if line[crsr]='1' then begin
                     repeat
                        inc(crsr);
                     until (line[crsr] in ['.','0'..'9']);
                     data:=data+trunc(1000*getnum(line))*weight[bits];
                     dec(bits);
                     if bits=0 then begin
                        bits:=8;
                        codes[pointer].data[pass-3]:=data;
                        data:=0;
                        inc(pass);
                     end;
                  end; { if }
               end;  { if pass=4 }
            8: begin { exit code }
                  inc(pass);
                  codes[pointer].exit:=0;
               end
            else begin
               pass:=1;
               data:=0;
               bits:=8;
            end; { else }
         end; { case pass }
      end; { if crsr<linelen }
   end; { while (not EOF(infile)) and (pass<99) }
end; { procedure readcode }

procedure sort;

begin
   for pointer1:=1 to pointer do
      for pointer2:=pointer1+1 to pointer do
         if codes[pointer1].data[3]>codes[pointer2].data[3] then begin
            temp:=codes[pointer1];
            codes[pointer1]:=codes[pointer2];
            codes[pointer2]:=temp;
         end;
end; { procedure sort }   
      
begin { main program }
   write('Enter file name ( extension must be .TXT ): ');
   readln(infname);
   while length(infname)>0 do begin
      openfile;
      readcode;
      for pointer1:=1 to pointer do
         with codes[pointer1] do begin
            write(#9,'db ');
            for i:=1 to 4 do begin
               write('0',tohexbyte(data[i]),'h');
	       if i<4 then write(',');
            end;
            writeln(#9,'; ',name);
         end;
      write('Sort ? (Y/N) ');
      readln(sortq);
      if upcase(sortq[1])='Y' then begin
         sort;
         for pointer1:=1 to pointer do
            with codes[pointer1] do begin
               write(#9,'db ');
               for i:=1 to 4 do begin
                  write('0',tohexbyte(data[i]),'h');
	          if i<4 then write(',');
               end;
               writeln(#9,'; ',name);
            end;
         end;
      for pointer1:=1 to pointer do
         with codes[pointer1] do begin
            write(outfile,#9,'db ');
            for i:=1 to 4 do begin
               write(outfile,'0',tohexbyte(data[i]),'h');
	       if i<4 then write(outfile,',');
            end;
            writeln(outfile,#9,'; ',name);
         end;
      closefile;
      write('Enter file name ( extension must be .TXT ): ');
      readln(infname);
   end;
end. { main program }
