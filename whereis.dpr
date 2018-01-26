{                                                                           }
{ File:       whereis.dpr                                                   }
{ Function:   Whereis command line tool                                     }
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

program whereis;

{$APPTYPE CONSOLE}
{$IFDEF ConditionalExpressions}
  {$IF RTLVersion >= 17.0}
    {$WARN SYMBOL_PLATFORM OFF}
    {$INLINE AUTO}
  {$IFEND}
{$ENDIF}

uses
  Windows,
  SysUtils,
  Classes;

const
  CRLF = #13#10;

var
  Debugging: Boolean = False;

resourcestring
  StrHelp =
    'Syntax: WHEREIS [options ...] Name[s]' + CRLF + CRLF +
    'Options start with - or /' + CRLF +
    '  -W        emulate Which: find first executable like OS does' + CRLF +
    '  -D        show debug output' + CRLF +
    '  -H or -?  show this help';
  StrCouldNotFind = 'Could not find %s';

procedure ShowHelp;
begin
  Writeln(StrHelp);
  Halt(1);
end;

procedure AddString(const S: string; List: TStrings);
begin
  if List.IndexOf(S) < 0 then
    List.Add(S);
end;

procedure ParseParameters(Names: TStrings; var FirstResultOnly: Boolean);
var
  I: Integer;
  S: string;
begin
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if (Length(S) = 2) and ((S[1] = '/') or (S[1] = '-')) then
      case UpCase(S[2]) of
        'W': FirstResultOnly := True;
        'H', '?': ShowHelp;
        'D': Debugging := True;
      end
    else
      AddString(S, Names);
  end;
end;

procedure GetDelimitedText(S: string; Delimiter: Char; ResultList: TStrings);
var
  Start, Stop: Integer;
  Len: Integer;
begin
  Len := Length(S);
  if Len = 0 then
    Exit;
  if S[Len] <> Delimiter then
  begin
    S := S + Delimiter;
    Inc(Len);
  end;
  Start := 1;
  while Start <= Len do
  begin
    Stop := Start;
    while S[Stop] <> Delimiter do
      Inc(Stop);
    AddString(Copy(S, Start, Stop - Start), ResultList);
    Start := Stop + 1;
  end;
end;

function ExecutableDirectory: string;
begin
  // Here, we don't want the executable directory of Whereis, we want the
  // directory in which the command interpreter resides.
  Result := ExcludeTrailingBackslash(ExtractFileDir(
              GetEnvironmentVariable('COMSPEC')));
  if Debugging then
    Writeln('Executable directory: ', Result);
end;

function CurrentDirectory: string;
inline;
begin
  SetLength(Result, 2 * MAX_PATH);
  GetCurrentDirectory(Length(Result) - 1, PChar(Result));
  Result := PChar(Result);
  if Debugging then
    Writeln('Current directory: ', Result);
end;

function SystemDirectory: string;
inline;
begin
  SetLength(Result, 2 * MAX_PATH);
  GetSystemDirectory(PChar(Result), Length(Result) - 1);
  Result := PChar(Result);
  if Debugging then
    Writeln('System directory: ', Result);
end;

function WindowsDirectory: string;
inline;
begin
  SetLength(Result, 2 * MAX_PATH);
  GetWindowsDirectory(PChar(Result), Length(Result) - 1);
  Result := PChar(Result);
  if Debugging then
    Writeln('Windows directory: ', Result);
end;

procedure InitDirectories(ResultList: TStrings);
inline;
begin
  AddString(ExecutableDirectory, ResultList);
  AddString(CurrentDirectory, ResultList);
  AddString(SystemDirectory, ResultList);
  AddString(WindowsDirectory, ResultList);
  GetDelimitedText(GetEnvironmentVariable('PATH'), ';', ResultList);
end;

const
  DefaultExtensions = '.COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH';

procedure InitExtensions(Extensions: TStrings); inline;
begin
  // PATHEXT may not exist in some OSes.
  GetDelimitedText(DefaultExtensions, ';', Extensions);
  GetDelimitedText(GetEnvironmentVariable('PATHEXT'), ';', Extensions);
end;

function FindFiles(const Directory, FileName: string;
  ResultList: TStrings): Boolean;
var
  SearchRec: TSearchRec;
  Found: Boolean;
  FullDir: string;
begin
  Result := False;
  FullDir := IncludeTrailingBackslash(Directory);

  Found := FindFirst(FullDir + FileName, faAnyFile, SearchRec) = 0;
  while Found do
  begin
    Result := True;
    AddString(FullDir + SearchRec.Name, ResultList);
    Found := FindNext(SearchRec) = 0;
  end;
  FindClose(SearchRec);
end;

function HasExecutableExtension(const Name: string; Extensions: TStrings): Boolean;
begin
  Result := Extensions.IndexOf(ExtractFileExt(Name)) >= 0;
end;

function SearchExecutable(const Directory, Name: string;
  Extensions, ResultList: TStrings; FirstResultOnly: Boolean): Boolean;
var
  I: Integer;
begin
  Result := False;
  if HasExecutableExtension(Name, Extensions) then
    Result := FindFiles(Directory, Name, ResultList)
  else
    for I := 0 to Extensions.Count - 1 do
    begin
      Result := FindFiles(Directory, Name + Extensions[I], ResultList);
      if Result and FirstResultOnly then
        Exit;
    end;
end;

procedure SearchDirectories(const Name: string;
  Directories, Extensions, ResultList: TStrings; FirstResultOnly: Boolean);
  // inlining this routine crashes app!
var
  I: Integer;
begin
  for I := 0 to Directories.Count - 1 do
    if SearchExecutable(Directories[I], Name, Extensions, ResultList,
         FirstResultOnly) then
      if FirstResultOnly then
        Break;
end;

var
  Directories: TStringList;
  Extensions: TStringList;
  Results: TStringList;
  Names: TStringList;
  FirstResultOnly: Boolean = False;
  I, J: Integer;

begin
  Writeln;
  Results := TStringList.Create;
  Directories := TStringList.Create;
  Extensions := TStringList.Create;
  Names := TStringList.Create;
  try
    ParseParameters(Names, FirstResultOnly);
    InitDirectories(Directories);
    InitExtensions(Extensions);
    if Names.Count = 0 then
      ShowHelp;
    for I := 0 to Names.Count - 1 do
    begin
      Results.Clear;
      SearchDirectories(Names[I], Directories, Extensions, Results,
        FirstResultOnly);
      if Results.Count > 0 then
      begin
        for J := 0 to Results.Count - 1 do
          Writeln(Results[J]);
        Writeln;
      end
      else
      begin
        Writeln(Format(StrCouldNotFind, [Names[I]]));
        Writeln;
      end;
    end;
  finally
    Names.Free;
    Extensions.Free;
    Directories.Free;
    Results.Free;
  end;
end.

