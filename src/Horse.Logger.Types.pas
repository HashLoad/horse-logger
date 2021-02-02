unit Horse.Logger.Types;

{$IFDEF FPC }
  {$MODE DELPHI}
{$ENDIF}

interface

uses

{$IFDEF FPC }
  fpJSON, Generics.Collections;
{$ELSE}
  System.JSON, System.Generics.Collections;
{$ENDIF}



type
  THorseLoggerCache = TObjectList<TJSONObject>;
  THorseLoggerLog = TJSONObject;
  THorseLoggerLogItemNumber = {$IFDEF FPC}TJSONFloatNumber{$ELSE}TJSONNumber{$ENDIF};
  THorseLoggerLogItemString = TJSONString;

implementation

end.
