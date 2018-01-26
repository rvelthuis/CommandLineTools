{                                                                           }
{ File:       slack.dpr                                                     }
{ Function:   Program to calculate slack caused by cluster size.            }
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


program slack;

{$APPTYPE CONSOLE}

{$IFDEF CONDITIONALEXPRESSIONS}
  {$IF CompilerVersion >= 17.0}
    {$DEFINE CANINLINE}
  {$IFEND}
{$ENDIF}

uses
  SysUtils,
  Windows;

var
  ClusterSize: Word;
  StartDirectory: string;
  FileCount: Int64;
  DirectorySize: Int64;
  FileSystemName: array[0..9] of Char;

function GetClusterSize(Drive: Char): Longint;
  {$IFDEF CANINLINE} inline; {$ENDIF}
var
  SectorsPerCluster,
  BytesPerSector,
  Dummy: Cardinal;
begin
  SectorsPerCluster := 0;
  BytesPerSector := 0;
  GetDiskFreeSpace(PChar(Drive + ':\'), SectorsPerCluster,
    BytesPerSector, Dummy, Dummy);
  Result := SectorsPerCluster * BytesPerSector;
  GetVolumeInformation(PChar(Drive + ':\'), nil, 0, nil, Dummy, Dummy,
    FileSystemName, SizeOf(FileSystemName));
end;

procedure Help;
  {$IFDEF CANINLINE} inline; {$ENDIF}
begin
  Writeln;
  Writeln('Usage: SLACK [Options] Filename');
  Writeln;
  Writeln('Options start with - or /');
  Writeln('  -H or -?  Show this help');
  Writeln;
  Writeln('SLACK calculates the number of wasted bytes caused by cluster size.');
  Writeln;
  Halt;
end;

procedure DecodeParams;
  {$IFDEF CANINLINE} inline; {$ENDIF}
var
  ParamNo: Integer;
  Param: string;
begin
  if ParamCount = 0 then
    GetDir(0, StartDirectory)
  else
  begin
    for ParamNo := 1 to ParamCount do
    begin
      Param := ParamStr(ParamNo);
      if (Length(Param) > 1) and ((Param[1] = '-') or (Param[1] = '/')) then
        case UpCase(Param[2]) of
          'H', '?':
            Help;
        else
          Help;
        end
      else
        StartDirectory := ExpandFileName(ParamStr(ParamNo));
    end;
  end;
end;

{ Calculates the wasted bytes for a file with the given size. }
function CalcWaste(Size: Uint64): Int64; // Uint64 gives AV!
  {$IFDEF CANINLINE} inline; {$ENDIF}
var
  Diff: Longint;
begin
  Diff := Size mod ClusterSize;
  if Diff > 0 then
    CalcWaste := ClusterSize - Diff
  else
    CalcWaste := 0;
end;

{ Calculates the wasted bytes of all files in a directory and }
{ its subdirectories.                                         }
function CalcDirWaste(Dir: string): Int64;
{ Can't inline: recursive }
var
  SR: TSearchRec;
  Error: Integer;
begin
  Result := 0;
  Dir := IncludeTrailingPathDelimiter(Dir);
  Error := SysUtils.FindFirst(Dir + '*.*', faAnyFile, SR);
  try
    while Error = 0 do
    begin
      if ((SR.Attr and faDirectory) <> 0) and
         (SR.Name <> '.') and (SR.Name <> '..') then
        Inc(Result, CalcDirWaste(Dir + SR.Name))
      else
      begin
        Inc(Result, CalcWaste(SR.Size));
        Inc(FileCount);
        Inc(DirectorySize, SR.Size);
      end;
      Error := SysUtils.FindNext(SR);
    end;
  finally
    SysUtils.FindClose(SR);
  end;
end;

function FormatInt(L: Int64): string;
  {$IFDEF CANINLINE} inline; {$ENDIF}
begin
  Result := Format('%.n', [L + 0.0]);
end;

function FormatSizes(L: Int64): string;
  {$IFDEF CANINLINE} inline; {$ENDIF}
begin
  Result := FormatInt(L) + ' bytes';
  if L > 1024 then
  begin
    Result := Result + ' = ' + FormatInt(L div 1024) + ' KB';
    if L > 1024 * 1024 then
      Result := Result + ' = ' + FormatInt(L div (1024 * 1024)) + ' MB';
  end;
end;

var
  Wasted: Int64;

begin
  try
    DecodeParams;
    if not DirectoryExists(StartDirectory) then
    begin
      Writeln;
      Writeln('Invalid directory: ', StartDirectory);
      Halt(1);
    end;
    DirectorySize := 0;
    FileCount := 0;
    ClusterSize := GetClusterSize(StartDirectory[1]);
    Writeln;
    Writeln('Path:              ', StartDirectory);
    Writeln('File system type:  ', FileSystemName);
    Writeln('Cluster size:      ', FormatInt(ClusterSize), ' bytes');
    Write('Calculating wasted disk space, please wait...');
    Wasted := CalcDirWaste(StartDirectory);
    Write(#13'                                             '#13);
    Writeln('Total file sizes:  ', FormatSizes(DirectorySize));
    Writeln('Wasted:            ', FormatSizes(Wasted));
    Writeln('Percentage wasted: ', (100.0 * Wasted / (DirectorySize + Wasted)):0:1,
            '%');
    Writeln('Files:             ', FormatInt(FileCount), ', wasted ', FormatInt(Wasted div FileCount), ' bytes per file' );
  except
    on E: Exception do
      Writeln('Error: Exception', E.ClassName, ' with message: ', E.Message);
  end;
end.

