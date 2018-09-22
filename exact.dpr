{                                                                           }
{ File:       exact.dpr                                                     }
{ Function:   Prints exact value of string when converted to IEEE-754       }
{             floating point single, double and extended precision.         }
{ Language:   Delphi XE2 or higher                                          }
{ Author:     Rudy Velthuis                                                 }
{ Copyright:  (c) 2017 Rudy Velthuis                                        }
{                                                                           }
{ Requires:   Velthuis.BigDecimals and Velthuis.BigIntegers units from      }
{             https://github.com/rvelthuis/DelphiBigNumbers/tree/master     }
{             /Source                                                       }
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

program exact;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Math,
  Velthuis.BigIntegers,
  Velthuis.BigDecimals;

procedure Help;
begin
  Writeln;
  Writeln('EXACT');
  Writeln;
  Writeln('Shows the exact values generated for a floating point string, for the');
  Writeln('IEEE-754 binary floating point single,  double and extended precision');
  Writeln('data types, and their hexadecimal representations.');
  Writeln;
  Writeln('Examples:');
  Writeln('  EXACT 1.2345');
  Writeln('  EXACT 17.93e17');
  Writeln('  EXACT 1e-30');
  Writeln;
  Writeln('http://rvelthuis.de/programs/exact.html');
  Writeln;
end;

type
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;
  PUInt64 = ^UInt64;

{$POINTERMATH ON}

function SingleString(Sgl: Single): string;
var
  B: BigDecimal;
begin
  if IsInfinite(Sgl) then
    if Sgl < 0 then
      Result := '-Infinity'
    else
      Result := '+Infinity'
  else
  begin
    B := Sgl;
    Result := B.ToString;
  end;
end;

function DoubleString(Dbl: Double): string;
var
  B: BigDecimal;
begin
  if IsInfinite(Dbl) then
    if Dbl < 0 then
      Result := '-Infinity'
    else
      Result := '+Infinity'
  else
  begin
    B := Dbl;
    Result := B.ToString;
  end;
end;

function ExtendedString(Ext: Extended): string;
var
  B: BigDecimal;
begin
  if IsInfinite(Ext) then
    if Ext < 0 then
      Result := '-Infinity'
    else
      Result := '+Infinity'
  else
  begin
    B := Ext;
    Result := B.ToString;
  end;
end;

function TrimZeroes(const S: string): string;
var
  I: Integer;
begin
  I := Length(S);
  while S[I] = '0' do
    Dec(I);
  if I <= 0 then
    Result := '0'
  else
    Result := Copy(S, 1, I);
end;

function SignedStr(I: Integer): string;
begin
  if I >= 0 then
    Result := '+' + IntToStr(I)
  else
    Result := IntToStr(I);
end;

function DoubleToHex(D: Double): string;
begin
  case D.SpecialType of
    fsZero:
      Result := '0x0.0p+0';
    fsNZero:
      Result := '-0x0.0p+0';
    fsDenormal:
      Result := Format('0x0.%sp-1026', [TrimZeroes(Format('%.13X', [D.Mantissa and $FFFFFFFFFFFFF]))]);
    fsNDenormal:
      Result := Format('-0x0.%sp-1026', [TrimZeroes(Format('%.13X', [D.Mantissa and $FFFFFFFFFFFFF]))]);
    fsPositive:
      Result := Format('0x1.%sp%s', [TrimZeroes(Format('%.13X', [D.Mantissa and $FFFFFFFFFFFFF])), SignedStr(D.Exponent)]);
    fsNegative:
      Result := Format('-0x1.%sp%s', [TrimZeroes(Format('%.13X', [D.Mantissa and $FFFFFFFFFFFFF])), SignedStr(D.Exponent)]);
    fsInf:
      Result := '+Infinity';
    fsNInf:
      Result := '-Infinity';
    fsNaN:
      Result := 'NaN';
  end;
end;


procedure HexValue(const S: string);
var
  BD: BigDecimal;
  BI: BigInteger;
  Sgl: Single;
  Dbl: Double;
  Ext: Extended;
begin
  if BigInteger.TryParse(S, 16, BI) then
  begin
    Sgl := PSingle(BI.Data)^;
    Dbl := PDouble(BI.Data)^;
    Ext := PExtended(BI.Data)^;
    Writeln('Hex Value: ', BI.ToString(16));
    Writeln;
    Writeln('32 bit float: ', SingleString(Sgl));
    Writeln('64 bit float: ', DoubleString(Dbl), ' (', DoubleToHex(Dbl), ')');
    Writeln('80 bit float: ', ExtendedString(Ext));
    Writeln;
  end
  else
  begin
    Writeln(ErrOutput, 'Invalid hex number');
    Writeln;
  end;

end;

procedure ExactValue(const S: string);
var
  B: BigDecimal;
  Sgl: Single;
  Dbl: Double;
  Ext: Extended;
  Value: string;
begin
  B := S;
  Writeln('The value:    ', S, ' (', B.ToString, ')');
  Writeln;

  // Single
  Sgl := Single(B);
  Writeln('32 bit float: ', SingleString(Sgl));
  Writeln(Format('Hex:          %.8X', [PUInt32(@Sgl)^]));
  Writeln;

  // Double
  Dbl := Double(B);
  Writeln('64 bit float: ', DoubleString(Dbl));
  Writeln(Format('Hex:          %.16X (%s)', [PUInt64(@Dbl)^, DoubleToHex(Dbl)]));
  Writeln;

{$IF SizeOf(Extended) > SizeOf(Double)}
  // Extended
  Ext := Extended(B);
  Writeln('80 bit float: ', ExtendedString(Ext));
  Writeln(Format('Hex:          %.4X%.16X', [PUInt16(@Ext)[4], PUInt64(@Ext)^]));
  Writeln;
{$IFEND}
end;

begin
  try
    if ParamCount < 1 then
      Help
    else
      ExactValue(ParamStr(1));
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
