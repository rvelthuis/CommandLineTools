unit EOLConv.Converters;

interface

uses
  System.Classes;

procedure ConvertBytes(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
procedure Convert16BE(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
procedure Convert16LE(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
function ConvertFile(const InFileName, OutFileName: string; LineBreaks: TTextLineBreakStyle): Boolean;

implementation

uses
  System.SysUtils;

procedure ConvertBytes(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
var
  PIn, POut, PEnd: PByte;
  CurByte: Byte;
  LLen: Integer;
  InBuffer, OutBuffer: TArray<Byte>;
begin
  SetLength(InBuffer, 1024 * 1024);
  SetLength(OutBuffer, 2 * Length(InBuffer));
  repeat
    LLen := InStream.Read(InBuffer[0], Length(InBuffer));
    if LLen = 0 then
      Break;

    // Start conversion single byte
    PIn := @InBuffer[0];
    PEnd := PIn + LLen;
    POut := @OutBuffer[0];

    while PIn < PEnd do
    begin
      CurByte := PIn^;
      if (CurByte = 10) or (CurByte = 13) then
      begin
        if LineBreaks = tlbsCRLF then
        begin
          POut^ := 13;
          Inc(POut);
        end;
        POut^ := 10;
        Inc(POut);
        Inc(PIn);
        if (CurByte = 13) and (PIn^ = 10) then
          Inc(PIn);
      end
      else
      begin
        POut^ := PIn^;
        Inc(POut);
        Inc(PIn);
      end;
    end;
    OutStream.Write(OutBuffer, POut - PByte(OutBuffer));
  until LLen < Length(InBuffer);
end;

{$POINTERMATH ON}

procedure Convert16BE(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
var
  PIn, POut, PEnd: PWord;
  CurChar: Word;
  LLen: Integer;
  InBuffer, OutBuffer: TArray<Word>;
begin
  SetLength(InBuffer, 1024 * 1024);
  SetLength(OutBuffer, 2 * Length(InBuffer));
  repeat
    LLen := InStream.Read(InBuffer[0], Length(InBuffer) * SizeOf(Char));
    if LLen = 0 then
      Break;

    // Start conversion single byte
    PIn := @InBuffer[0];
    PEnd := PIn + (LLen div SizeOf(Char));
    POut := @OutBuffer[0];

    while PIn < PEnd do
    begin
      CurChar := PIn^;
      if (CurChar = $0A00) or (CurChar = $0D00) then
      begin
        if LineBreaks = tlbsCRLF then
        begin
          POut^ := $0D00;
          Inc(POut);
        end;
        POut^ := $0A00;
        Inc(POut);
        Inc(PIn);
        if (CurChar = $0D00) and (PIn^ = $0A00) then
          Inc(PIn);
      end
      else
      begin
        POut^ := PIn^;
        Inc(POut);
        Inc(PIn);
      end;
    end;
    OutStream.Write(OutBuffer[0], (POut - PWord(OutBuffer)) * SizeOf(Char));
  until LLen < Length(InBuffer) * SizeOf(Char);
end;

procedure Convert16LE(const InStream, OutStream: TStream; LineBreaks: TTextLineBreakStyle);
var
  PIn, POut, PEnd: PWord;
  CurChar: Word;
  LLen: Integer;
  InBuffer, OutBuffer: TArray<Word>;
begin
  SetLength(InBuffer, 1024 * 1024);
  SetLength(OutBuffer, 2 * Length(InBuffer));
  repeat
    LLen := InStream.Read(InBuffer[0], Length(InBuffer) * SizeOf(Char));
    if LLen = 0 then
      Break;

    // Start conversion single byte
    PIn := @InBuffer[0];
    PEnd := PIn + (LLen div SizeOf(Char));
    POut := @OutBuffer[0];

    while PIn < PEnd do
    begin
      CurChar := PIn^;
      if (CurChar = $000A) or (CurChar = $000D) then
      begin
        if LineBreaks = tlbsCRLF then
        begin
          POut^ := $000D;
          Inc(POut);
        end;
        POut^ := $000A;
        Inc(POut);
        Inc(PIn);
        if (CurChar = $000D) and (PIn^ = $000A) then
          Inc(PIn);
      end
      else
      begin
        POut^ := PIn^;
        Inc(POut);
        Inc(PIn);
      end;
    end;
    OutStream.Write(OutBuffer[0], (POut - PWord(@OutBuffer[0])) * SizeOf(Char));
  until LLen < Length(InBuffer) * SizeOf(Char);
end;

function ConvertFile(const InFileName, OutFileName: string; LineBreaks: TTextLineBreakStyle): Boolean;
var
  InStream, OutStream: TStream;
  InBuffer: array[0..1] of Byte;
begin
  Result := True;
  OutStream := nil;
  try
  InStream := TFileStream.Create(InFileName, fmOpenRead);
  try
    OutStream := TFileStream.Create(OutFileName, fmCreate);
    if (InStream.Read(InBuffer[0], 2) = 2) then
    begin
      // Check for UTF-16 BE BOM
      if (InBuffer[0] = $FE) and (InBuffer[1] = $FF) then
      begin
        OutStream.Write(InBuffer, 2);
        Convert16BE(InStream, OutStream, LineBreaks)
      end
      // Check for UTF-16 LE BOM
      else if (InBuffer[0] = $FF) and (InBuffer[1] = $FE) then
      begin
        OutStream.Write(InBuffer, 2);
        Convert16LE(InStream, OutStream, LineBreaks)
      end
      else
      begin
        // Assume single-byte encoding
        InStream.Position := 0;
        ConvertBytes(InStream, OutStream, LineBreaks);
      end
    end
    else
    begin
      // Size can only be 0 or 1:
      if Instream.Size = 1 then
        OutStream.Write(InBuffer, 1);
    end;
  finally
    OutStream.Free;
    InStream.Free;
  end;
  except
    Result := False;
  end;
end;

end.
