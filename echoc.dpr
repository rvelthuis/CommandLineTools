{                                                                           }
{ File:       echoc.dpr                                                     }
{ Function:   Program for batch and command files to output text in color.  }
{ Language:   Delphi                                                        }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2007 Rudy Velthuis                                        }
{                                                                           }
{ License and disclaimer:                                                   }
{                                                                           }
{ Redistribution and use in source and binary forms, with or without        }
{ modification, are permitted provided that the following conditions are    }
{ met:                                                                      }
{                                                                           }
{   * Redistributions of source code must retain the above copyright        }
{     notice, this list of conditions and the following disclaimer.         }
{   * Redistributions in binary form must reproduce the above copyright     }
{     notice, this list of conditions and the following disclaimer in the   }
{     documentation and/or other materials provided with the distribution.  }
{   * Neither the name of Rudy Velthuis nor the names of any contributors   }
{     of this software may be used to endorse or promote products derived   }
{     from this software without specific prior written permission.         }
{                                                                           }
{ THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS        }
{ "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT         }
{ LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR     }
{ A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT      }
{ OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,     }
{ SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED  }
{ TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR    }
{ PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF    }
{ LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING      }
{ NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF             }
{ THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.         }
{                                                                           }

program echoc;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows;

var
  StdOut: THandle;
  TextAttr: Byte;

procedure InitStdOut;
var
  BufferInfo: TConsoleScreenBufferInfo;
begin
  StdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(StdOut, BufferInfo);
  TextAttr := BufferInfo.wAttributes and $FF;
end;

procedure TextColor(Color: Byte);
begin
  TextAttr := (TextAttr and $F0) or (Color and $0F);
  SetConsoleTextAttribute(StdOut, TextAttr);
end;

procedure TextBackground(Color: Byte);
begin
  TextAttr := (TextAttr and $0F) or ((Color shl 4) and $F0);
  SetConsoleTextAttribute(StdOut, TextAttr);
end;


procedure SetColorFromStr(const S: string; Foreground: Boolean);
var
  Color: Byte;
  I: Integer;
begin
  Color := 0;
  for I := 1 to Length(S) do
    if (S[I] >= '0') and (S[I] <= '9') then
      Color := Color * 10 + Ord(S[I]) - Ord('0')
    else
      Break;
  if Foreground then
    TextColor(Color)
  else
    TextBackground(Color);
end;

procedure WriteStr(const S: string; Separator: Boolean);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if S[I] = '^' then
      Write(#13#10)
    else
      Write(S[I]);
  if Separator then
    Write(' ');
end;

procedure Help;
const
  HelpText =
    #13#10 +
    'ECHO in Color, Copyright (c) 2007 by Rudy Velthuis.'#13#10 +
    #13#10 +
    'Usage: ECHOC backgnd foregnd "The text"'#13#10 +
    #13#10 +
    'Foreground and background colors are numbers 0..15.'#13#10 +
    'A ^ in the text represents a newline.'#13#10;
begin
  Writeln(HelpText);
end;

var
  OldColor: Byte;
  I: Integer;

begin
  InitStdOut;
  OldColor := TextAttr;
  if ParamCount = 0 then
    Help;
  if ParamCount > 0 then
    SetColorFromStr(ParamStr(1), False);
  if ParamCount > 1 then
    SetColorFromStr(ParamStr(2), True);
  if ParamCount > 2 then
    for I := 3 to ParamCount do
      WriteStr(ParamStr(I), I < ParamCount);
  TextBackground((OldColor and $F0) shr 4);
  TextColor(OldColor and $0F);
end.
