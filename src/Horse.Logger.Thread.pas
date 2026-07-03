unit Horse.Logger.Thread;

{$IFDEF FPC }
  {$MODE DELPHI}
{$ENDIF}

interface

uses

{$IFDEF FPC }
  SysUtils, Classes, SyncObjs, Generics.Collections,
{$ELSE}
  System.SysUtils, System.SyncObjs, System.Classes, System.Generics.Collections,
{$ENDIF}
  Horse.Logger.Types;

type

  THorseLoggerThread = class;
  THorseLoggerThreadClass = class of THorseLoggerThread;

  THorseLoggerThread = class(TThread)
  private
    { private declarations }
    FCriticalSection: TCriticalSection;
    FEvent: TEvent;
    FLogCache: THorseLoggerCache;

  protected
    { protected declarations }
    FMaxCacheSize: Integer;
    function GetLogCache: THorseLoggerCache;

    function GetCriticalSection: TCriticalSection;
    function ExtractLogCache: THorseLoggerCache;
    function ResetLogCache: THorseLoggerThread;
    procedure DispatchLogCache; virtual;

  public
    { public declarations }
    function GetEvent: TEvent;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Execute; override;
    function NewLog(ALog: THorseLoggerLog): THorseLoggerThread;
  end;

implementation

{ THorseLoggerThread }

procedure THorseLoggerThread.AfterConstruction;
begin
  inherited;
  FEvent := TEvent.Create{$IFDEF FPC}(nil, False, True, TGuid.NewGuid.ToString(True)){$ENDIF};
  FCriticalSection := TCriticalSection.Create;
  FLogCache := THorseLoggerCache.Create;
  FMaxCacheSize := 0;
end;

procedure THorseLoggerThread.BeforeDestruction;
begin
  FLogCache.Free;
  FEvent.Free;
  FCriticalSection.Free;
  inherited;
end;

procedure THorseLoggerThread.DispatchLogCache;
begin

end;

procedure THorseLoggerThread.Execute;
var
  LWait: TWaitResult;
begin
{$IFNDEF FPC }
  inherited;
{$ENDIF}
  while not(Self.Terminated) do
  begin
    LWait := GetEvent.WaitFor(INFINITE);
    case LWait of
      wrSignaled:
        begin
          DispatchLogCache;
        end
    else
      Continue;
    end;
  end;
  DispatchLogCache;
end;

function THorseLoggerThread.ExtractLogCache: THorseLoggerCache;
var
  LTempCache: THorseLoggerCache;
begin
  LTempCache := THorseLoggerCache.Create(True);
  try
    GetCriticalSection.Enter;
    try
      Result := FLogCache;
      FLogCache := LTempCache;
    finally
      GetCriticalSection.Leave;
    end;
  except
    LTempCache.Free;
    raise;
  end;
end;

function THorseLoggerThread.GetCriticalSection: TCriticalSection;
begin
  Result := FCriticalSection;
end;

function THorseLoggerThread.GetEvent: TEvent;
begin
  Result := FEvent;
end;

function THorseLoggerThread.GetLogCache: THorseLoggerCache;
begin
  Result := FLogCache;
end;

function THorseLoggerThread.NewLog(ALog: THorseLoggerLog): THorseLoggerThread;
begin
  Result := Self;
  if FMaxCacheSize > 0 then
  begin
    GetCriticalSection.Enter;
    try
      if GetLogCache.Count >= FMaxCacheSize then
      begin
        ALog.Free;
        Exit;
      end;
    finally
      GetCriticalSection.Leave;
    end;
  end;

  GetCriticalSection.Enter;
  try
    GetLogCache.Add(ALog);
  finally
    GetCriticalSection.Leave;
    GetEvent.SetEvent;
  end;
end;

function THorseLoggerThread.ResetLogCache: THorseLoggerThread;
begin
  Result := Self;
  GetCriticalSection.Enter;
  try
    if GetLogCache <> nil then
      GetLogCache.Clear;
  finally
    GetCriticalSection.Leave;
  end;
end;

end.
