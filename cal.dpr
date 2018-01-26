{                                                                           }
{ File:       cal.dpr                                                       }
{ Function:   Prints simple calendar.                                       }
{ Language:   Delphi 2009                                                   }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2008 Rudy Velthuis                                        }
{                                                                           }
{ Note:       The Console unit can be downloaded from                       }
{             http://rvelthuis.de/zips/console.zip                          }
{                                                                           }
{   CAL - Print out month calendar                                          }
{                                                                           }
{   Synopsis                                                                }
{                                                                           }
{     cal [-13msyeh?] [[month] year]                                        }
{                                                                           }
{   The CAL utility displays a simple calendar.                             }
{   The options are as follows:                                             }
{                                                                           }
{     -1      Print one month only (default).                               }
{                                                                           }
{     -3      Print the previous month, the current month, and the          }
{             next month all on one row.                                    }
{                                                                           }
{     -m      Print a calendar where Monday is the first day of the         }
{             week, as opposed to Sunday.                                   }
{                                                                           }
{     -s      Print a calendar where Sunday is the first day of the         }
{             week (default).                                               }
{                                                                           }
{     -y      Display a calendar for the current year.                      }
{                                                                           }
{     -e      Use English month and day names.                              }
{                                                                           }
{     -h, -?  Display this help.                                            }
{                                                                           }
{     A single parameter specifies the year (1 - 9999) to be displayed;     }
{     note the year must be fully specified: "cal 89" will not display      }
{     a calendar for 1989.  Two parameters denote the month and year;       }
{     the month is a number between 1 and 12.                               }
{                                                                           }
{     A year starts on Jan 1.                                               }
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

program cal;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.DateUtils,
  Winapi.Windows;

var
  Month: Integer = High(Word);
  Year: Integer = High(Word);
  CurrentDay: Word;
  CurrentMonth: Word;
  CurrentYear: Word;

  ThreeMonths: Boolean = False;
  MondayFirst: Boolean = False;
  FullYear: Boolean = False;
  English: Boolean = False;
  ShowToday: Boolean = False;

var
  // Both arrays initialized to English names.
  MonthNames: array[Low(FormatSettings.LongMonthNames)..High(FormatSettings.LongMonthNames)] of string = (
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December');
  DayNames: array[Low(FormatSettings.ShortDayNames)..High(FormatSettings.ShortDayNames)] of string = (
    'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa');

resourcestring
  HelpText =
    'CAL - Print out month calendar'#13#10 +
    #13#10 +
    'Synopsis'#13#10 +
    #13#10 +
    '  cal [-13msyeh?] [[month] year]'#13#10 +
    #13#10 +
    'The CAL utility displays a simple calendar.'#13#10 +
    'The options are as follows:'#13#10 +
    #13#10 +
    '  -1      Print one month only (default).'#13#10 +
    #13#10 +
    '  -3      Print the previous month, the current month, and the next month'#13#10 +
    '          on one row.'#13#10 +
    #13#10 +
    '  -m      Print a calendar where Monday is the first day of the week, as'#13#10 +
    '          opposed to Sunday.'#13#10 +
    #13#10 +
    '  -s      Print a calendar where Sunday is the first day of the week (default).'#13#10 +
    #13#10 +
    '  -y      Display a calendar for the current year.'#13#10 +
    #13#10 +
    '  -e      Use English month and day names.'#13#10 +
    #13#10 +
    '  -h, -?  Display this help.'#13#10 +
    #13#10 +
    '  A single parameter specifies the year (1 - 9999) to be displayed; note'#13#10 +
    '  the year must be fully specified: "cal 89" will not display a calendar'#13#10 +
    '  for 1989 or 2089.  Two parameters denote the month and year; the month is'#13#10 +
    '  a number between 1 and 12.'#13#10 +
    #13#10 +
    '  A year starts on Jan 1.';

// Halts with error number.
procedure Error;
begin
  Halt(2);
end;

// Gets Oem version of string.
function OemString(const S: string): AnsiString;
var
  Ansi: AnsiString;
  AnsiBuffer: array[0..255] of AnsiChar;
begin
  Ansi := AnsiString(S);
  if AnsiToOem(PAnsiChar(Ansi), AnsiBuffer) then
    Result := AnsiBuffer
  else
    Result := Ansi;
end;

// Prints help text.
procedure Help;
begin
  Writeln(HelpText);
end;

// Decodes command line parameters.
procedure DecodeParams;
var
  I: Integer;
  Param: string;
  CurrentDate: TDateTime;
  Nums: array[1..2] of Integer;
  NumIndex: Integer;

  // Decodes parameter that starts with digit.
  procedure DecodeNumber(const AParam: string);
  var
    Num: Integer;
  begin
    if TryStrToInt(AParam, Num) then
    begin
      Inc(NumIndex);
      if NumIndex > 2 then
        NumIndex := 2;
      Nums[NumIndex] := Num;
    end
    else
      Error;
  end;

  // Decodes parameter that starts with - or ?.
  procedure DecodeOption(const AParam: string);
  begin
    if Length(AParam) > 1 then
    begin
      case AParam[2] of
        'H', 'h', '?': // help
          begin
            Help;
            Halt(1);
          end;
        '1':
          begin
            ThreeMonths := False; // default
            FullYear := False;
          end;
        '3':
          begin
            ThreeMonths := True;
            FullYear := False;
          end;
        's', 'S':
          MondayFirst := False; // default
        'm', 'M':
          MondayFirst := True;
        'e', 'E':
          English := True;
        'y', 'Y':
          begin
            FullYear := True;
            ThreeMonths := False;
          end;
      end;
    end
    else
    begin
      Help;
      Halt(1);
    end;
  end;

begin
  CurrentDate := Now;
  DecodeDate(CurrentDate, CurrentYear, CurrentMonth, CurrentDay);
  NumIndex := 0;
  for I := 1 to ParamCount do
  begin
    Param := ParamStr(I);
    case Param[1] of
      '-', '/':
        DecodeOption(Param);
      '0'..'9':
        DecodeNumber(Param);
    end;
  end;
  case NumIndex of
    0:
      begin
        Month := CurrentMonth;
        Year := CurrentYear;
      end;
    1:
      begin
        FullYear := True;
        ThreeMonths := False;
        Month := 1;
        Year := Nums[1];
      end;
    2:
      begin
        Month := Nums[1];
        Year := Nums[2];
      end;
  else
    Month := CurrentMonth;
    Year := CurrentYear;
  end;
  if Month > 12 then
    Month := CurrentMonth;
  if Year > 9999 then
    Year := 9999;
  if not FullYear then
    ShowToday := True;
end;

// Increments month. Ensures that after December follows January of next year.
procedure IncMonth(var AMonth, AYear: Integer);
begin
  Inc(AMonth);
  if (AMonth > 12) then
  begin
    AMonth := 1;
    Inc(AYear);
  end;
end;

// Decrements month. Ensures that before January comes December of previous year.
procedure DecMonth(var AMonth, AYear: Integer);
begin
  Dec(AMonth);
  if (AMonth = 0) then
  begin
    AMonth := 12;
    Dec(AYear);
  end;
end;

// Prints name of month (and year, depending on options) centered above month.
procedure PrintMonthName(AMonth, AYear: Integer);
var
  Name: AnsiString;
  Left, Right: Integer;
begin
  Name := OemString(MonthNames[AMonth]);
  if FullYear then
  begin
    Right := 20 - Length(Name);
    Left := Right - Right div 2;
    Right := Right - Left;
  end
  else
  begin
    Right := 19 - Length(Name) - Length(IntToStr(Year));
    Left := Right div 2;
    Right := Right - Left;
  end;
  Write('': Left, Name);
  if not FullYear then
    Write(' ', AYear);
  Write('': Right);
end;

// Prints one or more month names (and years) in one line, depending on options.
procedure PrintMonthNames(AMonth, AYear: Integer);
var
  M: Integer;
  N: Integer;
begin
  if ThreeMonths or FullYear then
    N := 3
  else
    N := 1;
  for M := 1 to N do
  begin
    PrintMonthName(AMonth, AYear);
    if M <> N then
    begin
      Write('   ');
      IncMonth(AMonth, AYear);
    end;
  end;
  Writeln;
end;

// Prints one Su-Sa strip (or Mo-Su, depending on options).
procedure PrintDayStrip;
var
  D: Integer;
begin
  if MondayFirst then
  begin
    for D := 2 to 7 do
      Write(DayNames[D], ' ');
    Write(DayNames[1], ' ');
  end
  else
    for D := 1 to 7 do
      Write(DayNames[D], ' ');
end;

// Prints one or more day strips, depending on options.
procedure PrintDayStrips(Month, Year: Integer);
var
  M, N: Integer;
begin
  if ThreeMonths or FullYear then
    N := 3
  else
    N := 1;
  for M := 1 to N do
  begin
    PrintDayStrip;
    if M <> N then
      Write('  ');
  end;
  Writeln;
end;

// Finds weekday of first day of month.
function WeekDayOfFirst(Month, Year: Word): Integer;
var
  D: TDateTime;
begin
  D := EncodeDate(Year, Month, 1);
  Result := DayOfTheWeek(D);
end;

// Swaps fore- and background colors on screen
procedure ReverseColor;
var
  Info: TConsoleScreenBufferInfo;
begin
  if GetConsoleScreenBufferInfo(TTextRec(Output).Handle, Info) then
  begin
    SetConsoleTextAttribute(TTextRec(Output).Handle,
      ((Info.wAttributes and $0F) shl 4) or ((Info.wAttributes and $F0) shr 4));
  end;
end;

// Prints one of more monthly calendars, depending on options.
procedure PrintMonths(NumMonths, AMonth, AYear: Integer);
var
  M, D: Integer;
  CurDay: array[1..3] of Integer;
  LastDay: array[1..3] of Integer;
  Finished: array[1..3] of Boolean;
  AllFinished: Boolean;
  StartMonth, StartYear: Integer;
begin
  PrintMonthNames(AMonth, AYear);
  PrintDayStrips(AMonth, AYear);

  StartMonth := AMonth;
  StartYear := AYear;

  for M := 1 to NumMonths do
  begin
    CurDay[M] := 1 - WeekDayOfFirst(AMonth, AYear);
    if MondayFirst then
      CurDay[M] := CurDay[M] + 1;

    // Avoid empty line.
    if CurDay[M] = -6 then
      CurDay[M] := 1;

    LastDay[M] := DaysInAMonth(AYear, AMonth);
    Finished[M] := False;
    IncMonth(AMonth, AYear);
  end;

  repeat
    AMonth := StartMonth;
    AYear := StartYear;
    for M := 1 to NumMonths do
    begin
      for D := 1 to 7 do
      begin
        // Highlight today
        if (CurDay[M] = CurrentDay) and
          (AMonth = CurrentMonth) and
          (AYear = CurrentYear) then
        begin
          ReverseColor;
          Write(CurDay[M]: 2);
          ReverseColor;
        end
        else if (CurDay[M] > 0) and (CurDay[M] <= LastDay[M]) then
          Write(CurDay[M]: 2)
        else
          Write('  ');
        if D <> 7 then
          Write(' ');
        Inc(CurDay[M]);
      end;
      if CurDay[M] > LastDay[M] then
        Finished[M] := True;
      if M <> NumMonths then
        Write('   ');
      IncMonth(AMonth, AYear);
    end;
    Writeln;

    AllFinished := True;
    for M := 1 to NumMonths do
      AllFinished := AllFinished and Finished[M];

  until AllFinished;
end;

// Uses local names, if required (default).
procedure HandleNames;
var
  I: Integer;
begin
  if not English then
  begin
    // Copy localized names to our arrays.
    for I := Low(FormatSettings.LongMonthNames) to High(FormatSettings.LongMonthNames) do
      MonthNames[I] := FormatSettings.LongMonthNames[I];
    for I := Low(FormatSettings.ShortDayNames) to High(FormatSettings.ShortDayNames) do
      DayNames[I] := FormatSettings.ShortDayNames[I];
  end;
end;

// Prints calendar depending on options.
procedure PrintCalendar;
var
  Q: Integer;
  Margin: Integer;
begin
  HandleNames;
  if ThreeMonths then
  begin
    // Print previous month, month and next month.
    DecMonth(Month, Year);
    PrintMonths(3, Month, Year);
  end
  else if FullYear then
  begin
    // Center year at top
    Margin := 66 - Length(IntToStr(Year));
    Writeln('': Margin div 2, Year);
    Writeln;

    // Print 4 rows of 3 months each
    Month := 1;
    for Q := 1 to 4 do
    begin
      PrintMonths(3, Month, Year);
      if Q <> 4 then
      begin
        Writeln;
        Inc(Month, 3);
      end;
    end;
  end
  else
    // Print one month
    PrintMonths(1, Month, Year);
end;

begin
  try
    DecodeParams;
    PrintCalendar;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

