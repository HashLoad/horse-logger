unit Horse.Logger.Utils;

{$IFDEF FPC }
{$MODE DELPHI}
{$ENDIF}

interface

type
  StringArray = TArray<string>;

  THorseLoggerUtils = class
  public
    class function GetFormatParams(AFormat: string): StringArray;
  end;

implementation

uses

{$IFDEF FPC }
  SysUtils, Regexpr;
{$ELSE}
  System.SysUtils, System.RegularExpressions, System.RegularExpressionsCore;
{$ENDIF}


const
  REGEXP_PARAM = '\$\{\w+\}';

  { THorseConsoleUtils }

{$IFDEF FPC}


class function THorseLoggerUtils.GetFormatParams(AFormat: string): StringArray;
var
  LRegex: TRegExpr;
  LCount: Integer;
begin
  LRegex := TRegExpr.Create(REGEXP_PARAM);
  try
    LCount := 0;
    if LRegex.Exec(AFormat) then
    begin
      repeat
        Inc(LCount);
        SetLength(Result, LCount);
        Result[LCount - 1] := LRegex.Match[0].Substring(2, LRegex.Match[0].Length - 3);
      until not LRegex.ExecNext;
    end;
  finally
    LRegex.Free;
  end;
end;
{$ELSE}


class function THorseLoggerUtils.GetFormatParams(AFormat: string): StringArray;
var
  LMatches: TMatchCollection;
  LIndex: Integer;
begin
  // Utiliza a chamada estática TRegEx.Matches que possui cache interno e é Thread-Safe por padrão no Delphi
  LMatches := TRegEx.Matches(AFormat, REGEXP_PARAM);

  SetLength(Result, LMatches.Count);

  for LIndex := 0 to LMatches.Count - 1 do
  begin
    Result[LIndex] := LMatches.Item[LIndex].Value.Substring(2, LMatches.Item[LIndex].Value.Length - 3)
  end;
end;
{$ENDIF}

end.
