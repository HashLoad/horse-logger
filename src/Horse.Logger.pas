unit Horse.Logger;

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
  Horse, Horse.HTTP, Horse.Utils.ClientIP;

type
  THorseLoggerConfig = class
  public
    LogDir: string;
    LogFormat: string;
    constructor Create(ALogFormat: string; ALogDir: string); overload;
    constructor Create(ALogFormat: string); overload;
  end;

  THorseLogger = class(TThread)
  private
    FCriticalSection: TCriticalSection;
    FEvent: TEvent;
    FLogCache: TList<string>;
    procedure SaveLogCache;
    procedure FreeInternalInstances;
    function ExtractLogCache: TArray<string>;
    class var FHorseLoggerConfig : THorseLoggerConfig;
    class var FHorseLogger: THorseLogger;
    class function ValidateValue(AValue: Integer): string; overload;
    class function ValidateValue(AValue: string): string; overload;
    class function ValidateValue(AValue: TDateTime): string; overload;
    class function GetDefaultHorseLogger: THorseLogger;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function NewLog(ALog: string): THorseLogger;
    procedure Execute; override;
    class destructor UnInitialize;
    class function GetDefault: THorseLogger;
    class function New(AConfig: THorseLoggerConfig): THorseCallback; overload;
    class function New: THorseCallback; overload;
  end;

const
  DEFAULT_HORSE_LOG_FORMAT =
    '${request_clientip} [${time}] ${request_user_agent}'+
    ' "${request_method} ${request_path_info} ${request_version}"'+
    ' ${response_status} ${response_content_length}';

implementation

uses
  {$IFDEF FPC }
    DateUtils, HTTPDefs
  {$else}
    Web.HTTPApp, System.DateUtils
  {$ENDIF}
   ;

procedure Middleware(ARequest: THorseRequest; AResponse: THorseResponse; ANext: {$IF DEFINED(FPC)}TNextProc{$ELSE}TProc{$ENDIF});
var
  LBeforeDateTime: TDateTime;
  LAfterDateTime: TDateTime;
  LMilliSecondsBetween: Integer;
  LLog: string;
begin
  LBeforeDateTime := Now();
  try
    ANext;
  finally
    LAfterDateTime := Now();
    LMilliSecondsBetween := MilliSecondsBetween(LAfterDateTime, LBeforeDateTime);

    LLog := THorseLogger.GetDefault.FHorseLoggerConfig.LogFormat;
    LLog := LLog.Replace('${time}', THorseLogger.ValidateValue(LBeforeDateTime));
    LLog := LLog.Replace('${execution_time}', THorseLogger.ValidateValue(LMilliSecondsBetween));
    LLog := LLog.Replace('${request_clientip}', THorseLogger.ValidateValue(ClientIP(ARequest)));
    LLog := LLog.Replace('${request_method}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Method));
    LLog := LLog.Replace('${request_version}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ProtocolVersion));
    LLog := LLog.Replace('${request_url}', THorseLogger.ValidateValue(ARequest.RawWebRequest.URL));
    LLog := LLog.Replace('${request_query}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Query));
    LLog := LLog.Replace('${request_path_info}', THorseLogger.ValidateValue(ARequest.RawWebRequest.PathInfo));
    LLog := LLog.Replace('${request_path_translated}', THorseLogger.ValidateValue(ARequest.RawWebRequest.PathTranslated));
    LLog := LLog.Replace('${request_cookie}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Cookie));
    LLog := LLog.Replace('${request_accept}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Accept));
    LLog := LLog.Replace('${request_from}', THorseLogger.ValidateValue(ARequest.RawWebRequest.From));
    LLog := LLog.Replace('${request_host}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Host));
    LLog := LLog.Replace('${request_referer}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Referer));
    LLog := LLog.Replace('${request_user_agent}', THorseLogger.ValidateValue(ARequest.RawWebRequest.UserAgent));
    LLog := LLog.Replace('${request_connection}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Connection));
    LLog := LLog.Replace('${request_remote_addr}', THorseLogger.ValidateValue(ARequest.RawWebRequest.RemoteAddr));
    LLog := LLog.Replace('${request_remote_host}', THorseLogger.ValidateValue(ARequest.RawWebRequest.RemoteHost));
    LLog := LLog.Replace('${request_script_name}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ScriptName));
    LLog := LLog.Replace('${request_server_port}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ServerPort));
    LLog := LLog.Replace('${request_script_name}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ScriptName));
    LLog := LLog.Replace('${request_authorization}', THorseLogger.ValidateValue(ARequest.RawWebRequest.Authorization));
    LLog := LLog.Replace('${request_content_encoding}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ContentEncoding));
    LLog := LLog.Replace('${request_content_type}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ContentType));
    LLog := LLog.Replace('${request_content_length}', THorseLogger.ValidateValue(ARequest.RawWebRequest.ContentLength));
    LLog := LLog.Replace('${response_server}', THorseLogger.ValidateValue(AResponse.RawWebResponse.Server));
    LLog := LLog.Replace('${response_allow}', THorseLogger.ValidateValue(AResponse.RawWebResponse.Allow));
    LLog := LLog.Replace('${response_location}', THorseLogger.ValidateValue(AResponse.RawWebResponse.Location));
    LLog := LLog.Replace('${response_content_encoding}', THorseLogger.ValidateValue(AResponse.RawWebResponse.ContentEncoding));
    LLog := LLog.Replace('${response_content_type}', THorseLogger.ValidateValue(AResponse.RawWebResponse.ContentType));
    LLog := LLog.Replace('${response_content_length}', THorseLogger.ValidateValue(AResponse.RawWebResponse.ContentLength));
    LLog := LLog.Replace('${response_status}', THorseLogger.ValidateValue(AResponse.RawWebResponse.{$IF DEFINED(FPC)}Code.ToString(){$ELSE}StatusCode{$ENDIF}));
    {$IF NOT DEFINED(FPC)}
    LLog := LLog.Replace('${request_derived_from}', THorseLogger.ValidateValue(ARequest.RawWebRequest.DerivedFrom));
    LLog := LLog.Replace('${request_remote_ip}', THorseLogger.ValidateValue(ARequest.RawWebRequest. RemoteIP));
    LLog := LLog.Replace('${request_internal_path_info}', THorseLogger.ValidateValue(ARequest.RawWebRequest.InternalPathInfo));
    LLog := LLog.Replace('${request_raw_path_info}', THorseLogger.ValidateValue(ARequest.RawWebRequest.RawPathInfo));
    LLog := LLog.Replace('${request_cache_control}', THorseLogger.ValidateValue(ARequest.RawWebRequest.CacheControl));
    LLog := LLog.Replace('${response_realm}', THorseLogger.ValidateValue(AResponse.RawWebResponse.Realm));
    LLog := LLog.Replace('${response_log_message}', THorseLogger.ValidateValue(AResponse.RawWebResponse.LogMessage));
    LLog := LLog.Replace('${response_title}', THorseLogger.ValidateValue(AResponse.RawWebResponse.Title));
    LLog := LLog.Replace('${response_content_version}', THorseLogger.ValidateValue(AResponse.RawWebResponse.ContentVersion));
    {$ENDIF}
    THorseLogger.GetDefault.NewLog(LLog);
  end;
end;

constructor THorseLoggerConfig.Create(ALogFormat: string; ALogDir: string);
begin
  LogFormat := ALogFormat;
  LogDir := ALogDir;
end;

constructor THorseLoggerConfig.Create(ALogFormat: string);
begin
  Create(ALogFormat, ExtractFileDir(ParamStr(0)));
end;

{ THorseLogger }

procedure THorseLogger.AfterConstruction;
begin
  inherited;
  FLogCache := TList<string>.Create;
  FEvent := TEvent.Create{$IFDEF FPC}(nil, False, True, 'HORSE_LOGGER'){$ENDIF};
  FCriticalSection := TCriticalSection.Create;
end;

procedure THorseLogger.BeforeDestruction;
begin
  inherited;
  FreeInternalInstances;
end;

procedure THorseLogger.Execute;
var
  LWait: TWaitResult;
begin
  inherited;
  while not(Self.Terminated) do
  begin
    LWait := FEvent.WaitFor(INFINITE);
    FEvent.ResetEvent;
    case LWait of
      wrSignaled:
        begin
          SaveLogCache;
        end
    else
      Continue;
    end;
  end;
end;

class function THorseLogger.GetDefault: THorseLogger;
begin
  Result := GetDefaultHorseLogger;
end;

class function THorseLogger.GetDefaultHorseLogger: THorseLogger;
begin
  if not Assigned(FHorseLogger) then
  begin
    FHorseLogger := THorseLogger.Create(True);
    FHorseLogger.FreeOnTerminate := True;
    FHorseLogger.Start;
  end;
  Result := FHorseLogger;
end;

function THorseLogger.ExtractLogCache: TArray<string>;
var
  LLogCacheArray: TArray<string>;
begin
  FCriticalSection.Enter;
  try
    LLogCacheArray := FLogCache.ToArray;
    FLogCache.Clear;
    FLogCache.TrimExcess;
  finally
    FCriticalSection.Leave;
  end;
  Result := LLogCacheArray;
end;

procedure THorseLogger.FreeInternalInstances;
begin
  FLogCache.Free;
  FEvent.Free;
  FCriticalSection.Free;
end;

class function THorseLogger.New(AConfig: THorseLoggerConfig): THorseCallback;
begin
  Self.FHorseLoggerConfig := AConfig;
  Result := Middleware;
end;

class function THorseLogger.New: THorseCallback;
var
  LLogFormat: string;
begin
  LLogFormat := DEFAULT_HORSE_LOG_FORMAT;
  Result := THorseLogger.New(THorseLoggerConfig.Create(LLogFormat));
end;

function THorseLogger.NewLog(ALog: string): THorseLogger;
begin
  Result := Self;
  FCriticalSection.Enter;
  try
    FLogCache.Add(ALog);
  finally
    FCriticalSection.Leave;
    FEvent.SetEvent;
  end;
end;

procedure THorseLogger.SaveLogCache;
var
  LFilename: string;
  LLogCacheArray: TArray<string>;
  LTextFile: TextFile;
  I: Integer;
begin
  FCriticalSection.Enter;
  try
    if not DirectoryExists(FHorseLoggerConfig.LogDir) then
      ForceDirectories(FHorseLoggerConfig.LogDir);
    LFilename := FHorseLoggerConfig.LogDir + PathDelim + 'access_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log';
    AssignFile(LTextFile, LFilename);
    if (FileExists(LFilename)) then
      Append(LTextFile)
    else
      Rewrite(LTextFile);
    try
      LLogCacheArray := ExtractLogCache;
      for I := Low(LLogCacheArray) to High(LLogCacheArray) do
      begin
        writeln(LTextFile, LLogCacheArray[I]);
      end;
    finally
      CloseFile(LTextFile);
    end;
  finally
    FCriticalSection.Leave;
  end;
end;

class destructor THorseLogger.UnInitialize;
begin
  if Assigned(FHorseLoggerConfig) then
    FreeAndNil(FHorseLoggerConfig);
  if Assigned(FHorseLogger) then
  begin
    FHorseLogger.Terminate;
    FHorseLogger.FEvent.SetEvent;
  end;
end;

class function THorseLogger.ValidateValue(AValue: TDateTime): string;
begin
  Result := FormatDateTime('dd/MMMM/yyyy hh:mm:ss:zzz', AValue);
end;

class function THorseLogger.ValidateValue(AValue: string): string;
begin
  Result := AValue;
  if AValue.IsEmpty then
    Result := '-';
end;

class function THorseLogger.ValidateValue(AValue: Integer): string;
begin
  Result := AValue.ToString;
end;

end.