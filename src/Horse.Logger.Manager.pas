unit Horse.Logger.Manager;

{$IFDEF FPC }
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC }
  SysUtils, Classes, SyncObjs, Generics.Collections, fpjson,
{$ELSE}
  System.SysUtils, System.JSON, System.SyncObjs, System.Classes, System.Generics.Collections,
{$ENDIF}
  Horse.Logger.Types, Horse.Logger.Provider.Contract, Horse, Horse.Logger.Thread;

type
  THorseLoggerManager = class;
  THorseLoggerManagerClass = class of THorseLoggerManager;

  THorseLoggerManager = class(THorseLoggerThread)
  private
    class var FProviderList: TList<IHorseLoggerProvider>;
    class var FDefaultManager: THorseLoggerManager;
  protected
    procedure DispatchLogCache; override;
    class function GetProviderList: TList<IHorseLoggerProvider>;
    class function ByteArrayToHexString(const AValue: TBytes; const ASeparator: string = ''): string;
    class function ValidateValue(const AValue: Integer): THorseLoggerLogItemNumber; overload;
    class function ValidateValue(const AValue: string): THorseLoggerLogItemString; overload;
    class function ValidateValue(const AValue: string; const AContentType: string): THorseLoggerLogItemString; overload;
    class function ValidateValue(const AValue: TBytes; const ASeparator: string = ''): THorseLoggerLogItemString; overload;
  	class function ValidateValue(const AValue: TDateTime; const AShort: Boolean): THorseLoggerLogItemString; overload;
    class function GetDefaultManager: THorseLoggerManager; static;
  public
    class function HorseCallback: THorseCallback; overload;
    class function RegisterProvider(const AProvider: IHorseLoggerProvider): THorseLoggerManagerClass;
    class property DefaultManager: THorseLoggerManager read GetDefaultManager;
    class destructor UnInitialize;
  end;

implementation

uses
{$IFDEF FPC }
  DateUtils, HTTPDefs,
{$ELSE}
  Web.HTTPApp, System.DateUtils,
{$ENDIF}
  Horse.Utils.ClientIP;

{ THorseLoggerManager }

procedure DefaultHorseCallback(AReq: THorseRequest; ARes: THorseResponse; ANext: TNextProc);
var
  LLog: THorseLoggerLog;
  LBeforeDateTime: TDateTime;
  LAfterDateTime: TDateTime;
  LMilliSecondsBetween: Integer;
begin
  LBeforeDateTime := Now();
  try
    ANext();
  finally
    LAfterDateTime := Now();
    LMilliSecondsBetween := MilliSecondsBetween(LAfterDateTime, LBeforeDateTime);
    LLog := THorseLoggerLog.Create;
    try
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('time', THorseLoggerManager.ValidateValue(LBeforeDateTime, False));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('time_short', THorseLoggerManager.ValidateValue(LBeforeDateTime, True));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('execution_time', THorseLoggerManager.ValidateValue(LMilliSecondsBetween.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_clientip', THorseLoggerManager.ValidateValue(ClientIP(AReq)));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_method', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Method));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_version', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ProtocolVersion));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_url', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.URL));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_query', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Query));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_path_info', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.PathInfo));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_path_translated', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.PathTranslated));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_cookie', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Cookie));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_accept', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Accept));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_from', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.From));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_host', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Host));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_referer', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Referer));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_user_agent', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.UserAgent));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_connection', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Connection));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_remote_addr', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteAddr));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_remote_host', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteHost));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_server_port', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ServerPort.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_script_name', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ScriptName));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_authorization', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.Authorization));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_encoding', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ContentEncoding));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_type', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ContentType));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content_length', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.ContentLength.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('request_content', THorseLoggerManager.ValidateValue({$IF DEFINED(FPC)} TEncoding.ANSI.GetBytes({$ENDIF}AReq.RawWebRequest.{$IF DEFINED(FPC)}Content){$ELSE}RawContent{$ENDIF}));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_server', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Server));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_allow', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Allow));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_location', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Location));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_encoding', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.ContentEncoding));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_type', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.ContentType));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content_length', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.ContentLength.ToString));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_content', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Content, AReq.RawWebRequest.ContentType));
      LLog.{$IFDEF FPC}Add{$ELSE}AddPair{$ENDIF}('response_status', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.{$IF DEFINED(FPC)}Code.ToString(){$ELSE}StatusCode.ToString{$ENDIF}));
      {$IF NOT DEFINED(FPC)}
        LLog.AddPair('request_derived_from', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.DerivedFrom));
        LLog.AddPair('request_remote_ip', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.RemoteIP));
        LLog.AddPair('request_internal_path_info', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.InternalPathInfo));
        LLog.AddPair('request_raw_path_info', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.RawPathInfo));
        LLog.AddPair('request_cache_control', THorseLoggerManager.ValidateValue(AReq.RawWebRequest.CacheControl));
        LLog.AddPair('response_realm', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Realm));
        LLog.AddPair('response_log_message', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.LogMessage));
        LLog.AddPair('response_title', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.Title));
        LLog.AddPair('response_content_version', THorseLoggerManager.ValidateValue(ARes.RawWebResponse.ContentVersion));
      {$ENDIF}
    finally
      THorseLoggerManager.GetDefaultManager.NewLog(LLog);
    end;
  end;
end;

class function THorseLoggerManager.ByteArrayToHexString(const AValue: TBytes; const ASeparator: string): string;
var
  LIndex: integer;
begin
  Result := '';
  for LIndex := Low(AValue) to High(AValue) do
    Result := Result + ASeparator + IntToHex(AValue[LIndex], 2);
end;

procedure THorseLoggerManager.DispatchLogCache;
var
  LLogCache: THorseLoggerCache;
  LHorseLoggerProvider: IHorseLoggerProvider;
  I: Integer;
begin
  LLogCache := ExtractLogCache;
  try
    for I := 0 to Pred(GetProviderList.Count) do
    begin
      if Supports(GetProviderList.Items[I], IHorseLoggerProvider, LHorseLoggerProvider)  then
        LHorseLoggerProvider.DoReceiveLogCache(LLogCache);
    end;
  finally
    LLogCache.Free;
  end;
end;

class function THorseLoggerManager.GetDefaultManager: THorseLoggerManager;
begin
  if not Assigned(FDefaultManager) then
  begin
    FDefaultManager := THorseLoggerManager.Create(True);
    FDefaultManager.FreeOnTerminate := False;
    FDefaultManager.Start;
  end;
  Result := FDefaultManager;
end;

class function THorseLoggerManager.GetProviderList: TList<IHorseLoggerProvider>;
begin
  if FProviderList = nil then
    FProviderList := TList<IHorseLoggerProvider>.Create;
  Result := FProviderList;
end;

class function THorseLoggerManager.HorseCallback: THorseCallback;
begin
  Result := DefaultHorseCallback;
end;

class function THorseLoggerManager.RegisterProvider(const AProvider: IHorseLoggerProvider): THorseLoggerManagerClass;
begin
  Result := THorseLoggerManager;
  GetProviderList.Add(AProvider);
end;

class destructor THorseLoggerManager.UnInitialize;
begin
  if FProviderList <> nil then
  begin
    FProviderList.Free;
  end;
  if FDefaultManager <> nil then
  begin
    FDefaultManager.Terminate;
    FDefaultManager.GetEvent.SetEvent;
    FDefaultManager.WaitFor;
    FDefaultManager.Free;
  end;
end;

class function THorseLoggerManager.ValidateValue(const AValue: TBytes; const ASeparator: string = ''): THorseLoggerLogItemString;
begin
  Result := THorseLoggerLogItemString.Create(ByteArrayToHexString(AValue, ASeparator));
end;

class function THorseLoggerManager.ValidateValue(const AValue: Integer): THorseLoggerLogItemNumber;
begin
  Result := THorseLoggerLogItemNumber.Create(AValue);
end;

class function THorseLoggerManager.ValidateValue(const AValue: string): THorseLoggerLogItemString;
begin
  Result := THorseLoggerLogItemString.Create(AValue);
end;

class function THorseLoggerManager.ValidateValue(const AValue: TDateTime; const AShort: Boolean): THorseLoggerLogItemString;
begin
  if AShort then
  	Result := THorseLoggerLogItemString.Create(FormatDateTime('dd/mm/yyyy hh:mm:ss.zzz', AValue))
  else
    Result := THorseLoggerLogItemString.Create(FormatDateTime('dd/MMMM/yyyy hh:mm:ss.zzz', AValue));
end;

class function THorseLoggerManager.ValidateValue(const AValue: string; const AContentType: string): THorseLoggerLogItemString;
var
  LJSON: {$IF DEFINED(FPC)}TJsonData{$ELSE}TJSONValue{$ENDIF};
begin
  if ((AValue <> '') and (Pos('application/json', AContentType) > 0)) then
  begin
    LJSON := nil;
    try
      try
        LJSON := {$IF DEFINED(FPC)} GetJSON(AValue) {$ELSE} TJSONObject.ParseJSONValue(AValue) {$ENDIF};
        if Assigned(LJSON) then
          Result := THorseLoggerLogItemString.Create(LJSON.ToString)
        else
          Result := THorseLoggerLogItemString.Create(AValue);
      except
        Result := THorseLoggerLogItemString.Create(AValue);
      end;
    finally
      LJSON.Free;
    end;
  end
  else
    Result := THorseLoggerLogItemString.Create(AValue);
end;

end.
