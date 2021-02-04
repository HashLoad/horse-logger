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
    GetEvent.ResetEvent;
    case LWait of
      wrSignaled:
        begin
          DispatchLogCache;
        end
    else
      Continue;
    end;
  end;
end;

function THorseLoggerThread.ExtractLogCache: THorseLoggerCache;
var
  LLogCache: THorseLoggerCache;
begin
  GetCriticalSection.Enter;
  try
    LLogCache := THorseLoggerCache.Create;
    while GetLogCache.Count > 0 do
      LLogCache.Add(
      {$IFDEF FPC }
        GetLogCache.ExtractIndex(0)
      {$ELSE}
        {$IFDEF CompilerVersion >= 33.0}
        GetLogCache.ExtractAt(0)
        {$ELSE}
        GetLogCache.Extract(GetLogCache.Items[0])
        {$ENDIF}
      {$ENDIF}
      );
    Result := LLogCache;
    ResetLogCache;
  finally
    GetCriticalSection.Leave;
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
