{                                                                           }
{ File:       eolconv.dpr                                                   }
{ Function:   Command line tool that converts all line endings of a text    }
{             file to a specified style or to the default.                  }
{ Language:   Delphi for Win32                                              }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2005 Rudy Velthuis                                        }
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

program eolconv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
{$IFDEF DEBUG}
  Velthuis.AutoConsole, // Can be omitted, see http://rvelthuis.de/programs/autoconsole.html
{$ENDIF }
  Winapi.Windows,
  System.SysUtils,
  System.Classes;

const
{$IFDEF MSWINDOWS}
  NL = #13#10;
{$ELSE}
  NL = #10;
{$ENDIF}

resourcestring
  SCouldNotOpenFile    = 'Could not open file ''%s''';
  SCouldNotWriteBackup = 'Could not write backup file for ''%s''';
  SHelpDesc            = 'EOLCONV: Convert line ends of text file.' + NL;
  SHelp                =
    'Syntax: EOLCONV [options ...] Names[s]' + NL + NL +
    'Options start with %s' + NL +
    '  -W         Convert all to Windows line ends (CR+LF)%s' + NL +
    '  -U         Convert all to Unix line ends (LF)%s' + NL +
    '  -H or -?   Show this help' + NL;

procedure Message(const FormatStr: string; Arguments: array of const);
begin
  Writeln(Format(FormatStr, Arguments));
end;

function ProcessFile(const FileName: string; LineEndType: TTextLineBreakStyle): Boolean;
var
  LList: TStringList;
  I: Integer;
begin
  Result := True;
  LList := TStringList.Create;
  try
    // Check if file exists.
    if not FileExists(FileName) then
    begin
      Message(SCouldNotOpenFile, [FileName]);
      Exit(False);
    end;

    // Load from file. Recognizes encoding and cuts up at line breaks.
    LList.LoadFromFile(FileName);

    // Set desied output line break.
    case LineEndType of
      tlbsLF: LList.LineBreak := #10;
      tlbsCRLF: LList.LineBreak := #13#10;
    end;

    // Write backup file: fn+'.~1', fn+'.~2' etc. up to fn+'.~200'.
    I := 1;
    while not RenameFile(FileName, FileName + '.~' + IntToStr(I)) and (I < 200) do
      Inc(I);
    if I <= 200 then
      LList.SaveToFile(FileName)
    else
    begin
      Message(SCouldNotWriteBackup, [FileName]);
      Exit(False);
    end;
  finally
    LList.Free;
  end;
end;

procedure Help(Description: Boolean);
begin
  if Description then
    Writeln(SHelpDesc);
{$IFDEF MSWINDOWS}
  Message(SHelp, ['- or /', ' (default)', '']);
{$ELSE}
  Error(SHelp, ['-', '', ' (default)']);
{$ENDIF}
end;

procedure ProcessParams(const FileNames: TStringList; var LineEndType: TTextLineBreakStyle);
var
  I: Integer;
begin
  // No parameters: Help -- syntax only
  if ParamCount = 0 then
  begin
    Help(False);
    Halt(1);
  end;

  // -H or -?: help with description
  if FindCmdLineSwitch('H', True) or FindCmdLineSwitch('?') then
  begin
    Help(True);
    Halt(0);
  end;

  // -U: Unix line ends
  if FindCmdLineSwitch('U', True) then
    LineEndType := tlbsLF

  // -W: Windows line ends
  else if FindCmdLineSwitch('W', True) then
    LineEndType := tlbsCRLF;

  // No - (or /): file name.
  for I := 1 to ParamCount do
    if (ParamStr(I)[1] <> '-') {$IFDEF MSWINDOWS} and (ParamStr(I)[1] <> '/') {$ENDIF} then
      FileNames.Add(ParamStr(I));
end;

var
  FileNameList: TStringList;
  LineEndType: TTextLineBreakStyle = {$IFDEF MSWINDOWS}tlbsCRLF{$ELSE}tlbsLF{$ENDIF};
  FileName: string;
  Success: Boolean = True;

begin
  FileNameList := TStringList.Create;
  try
    ProcessParams(FileNameList, LineEndType);
    for FileName in FileNameList do
      Success := Success and ProcessFile(FileName, LineEndType);
  finally
    FileNameList.Free;
  end;
  if not Success then
    Halt(1);
end.
