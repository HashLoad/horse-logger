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
  LRegex: {$IFDEF FPC}TRegExpr{$ELSE}TRegEx{$ENDIF};
begin
  LRegex := TRegExpr.Create(REGEXP_PARAM);
  try
    if LRegex.Exec(AFormat) then
    begin
      repeat
        Result := Result + [LRegex.Match[0].Substring(2, LRegex.Match[0].Length - 3)];
      until not LRegex.ExecNext;
    end;
  finally
    LRegex.Free;
  end;
end;
{$ELSE}


class function THorseLoggerUtils.GetFormatParams(AFormat: string): StringArray;
var
  LRegex: TRegEx;
  LMatches: TMatchCollection;
  LIndex: Integer;
begin
  LRegex := TRegEx.Create(REGEXP_PARAM);
  LMatches := LRegex.Matches(AFormat);

  SetLength(Result, LMatches.Count);

  for LIndex := 0 to LMatches.Count - 1 do
  begin
    Result[LIndex] := LMatches.Item[LIndex].Value.Substring(2, LMatches.Item[LIndex].Value.Length - 3)
  end;
end;
{$ENDIF}

end.
