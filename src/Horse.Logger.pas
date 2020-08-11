unit Horse.Logger;

interface

uses
  System.SysUtils, System.SyncObjs, Horse, System.Classes, System.Generics.Collections;

type
  THorseLoggerConfig = record
    LogDir: string;
    LogFormat: string;
    constructor Create(ALogFormat: string; ALogDir: string); overload;
    constructor Create(ALogFormat: string); overload;
  end;

  THorseLogger = class(TThread)
  private
    FCriticalSection: TCriticalSection;
    FEvent: TEvent;
    FLogDir: string;
    FLogCache: TList<string>;
    procedure SaveLogCache;
    procedure FreeInternalInstances;
    function ExtractLogCache: TArray<string>;
    class var FHorseLogger: THorseLogger;
    class function ValidateValue(AValue: Integer): string; overload;
    class function ValidateValue(AValue: string): string; overload;
    class function ValidateValue(AValue: TDateTime): string; overload;
    class function BuildLogger(AConfig: THorseLoggerConfig): THorseCallback;
    class function GetDefaultHorseLogger: THorseLogger;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function SetLogDir(ALogDir: string): THorseLogger;
    function NewLog(ALog: string): THorseLogger;
    procedure Execute; override;
    class destructor UnInitialize;
    class function GetDefault: THorseLogger;
    class function New(AConfig: THorseLoggerConfig): THorseCallback; overload;
    class function New: THorseCallback; overload;
  end;

const
  DEFAULT_HORSE_LOG_FORMAT =
    '${request_remote_addr} [${time}] ${request_user_agent}'+
    ' "${request_method} ${request_path_info} ${request_version}"'+
    ' ${response_status} ${response_content_length}';

implementation

uses
  Web.HTTPApp, System.DateUtils;

{ THorseLoggerConfig }

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
  FEvent := TEvent.Create;
  FCriticalSection := TCriticalSection.Create;
end;

procedure THorseLogger.BeforeDestruction;
begin
  inherited;
  FreeInternalInstances;
end;

class function THorseLogger.BuildLogger(AConfig: THorseLoggerConfig): THorseCallback;
begin
  Result := procedure(ARequest: THorseRequest; AResponse: THorseResponse; ANext: TProc)
    var
      LWebRequest: TWebRequest;
      LWebResponse: TWebResponse;
      LBeforeDateTime: TDateTime;
      LAfterDateTime: TDateTime;
      LMilliSecondsBetween: Integer;
      LLog: string;
    begin
      LBeforeDateTime := Now();
      try
        ANext();
      finally
        LAfterDateTime := Now();
        LMilliSecondsBetween := MilliSecondsBetween(LAfterDateTime, LBeforeDateTime);

        LWebRequest := THorseHackRequest(ARequest).GetWebRequest;
        LWebResponse := THorseHackResponse(AResponse).GetWebResponse;

        LLog := AConfig.LogFormat;

        LLog := LLog.Replace('${time}', ValidateValue(LBeforeDateTime));
        LLog := LLog.Replace('${execution_time}', ValidateValue(LMilliSecondsBetween));
        LLog := LLog.Replace('${request_method}', ValidateValue(LWebRequest.Method));
        LLog := LLog.Replace('${request_version}', ValidateValue(LWebRequest.ProtocolVersion));
        LLog := LLog.Replace('${request_url}', ValidateValue(LWebRequest.URL));
        LLog := LLog.Replace('${request_query}', ValidateValue(LWebRequest.Query));
        LLog := LLog.Replace('${request_path_info}', ValidateValue(LWebRequest.PathInfo));
        LLog := LLog.Replace('${request_path_translated}', ValidateValue(LWebRequest.PathTranslated));
        LLog := LLog.Replace('${request_cookie}', ValidateValue(LWebRequest.Cookie));
        LLog := LLog.Replace('${request_accept}', ValidateValue(LWebRequest.Accept));
        LLog := LLog.Replace('${request_from}', ValidateValue(LWebRequest.From));
        LLog := LLog.Replace('${request_host}', ValidateValue(LWebRequest.Host));
        LLog := LLog.Replace('${request_referer}', ValidateValue(LWebRequest.Referer));
        LLog := LLog.Replace('${request_user_agent}', ValidateValue(LWebRequest.UserAgent));
        LLog := LLog.Replace('${request_connection}', ValidateValue(LWebRequest.Connection));
        LLog := LLog.Replace('${request_derived_from}', ValidateValue(LWebRequest.DerivedFrom));
        LLog := LLog.Replace('${request_remote_addr}', ValidateValue(LWebRequest.RemoteAddr));
        LLog := LLog.Replace('${request_remote_host}', ValidateValue(LWebRequest.RemoteHost));
        LLog := LLog.Replace('${request_script_name}', ValidateValue(LWebRequest.ScriptName));
        LLog := LLog.Replace('${request_server_port}', ValidateValue(LWebRequest.ServerPort));
        LLog := LLog.Replace('${request_remote_ip}', ValidateValue(LWebRequest.RemoteIP));
        LLog := LLog.Replace('${request_internal_path_info}', ValidateValue(LWebRequest.InternalPathInfo));
        LLog := LLog.Replace('${request_raw_path_info}', ValidateValue(LWebRequest.RawPathInfo));
        LLog := LLog.Replace('${request_cache_control}', ValidateValue(LWebRequest.CacheControl));
        LLog := LLog.Replace('${request_script_name}', ValidateValue(LWebRequest.ScriptName));
        LLog := LLog.Replace('${request_authorization}', ValidateValue(LWebRequest.Authorization));
        LLog := LLog.Replace('${request_content_encoding}', ValidateValue(LWebRequest.ContentEncoding));
        LLog := LLog.Replace('${request_content_type}', ValidateValue(LWebRequest.ContentType));
        LLog := LLog.Replace('${request_content_length}', ValidateValue(LWebRequest.ContentLength));
        LLog := LLog.Replace('${request_content_version}', ValidateValue(LWebRequest.ContentVersion));
        LLog := LLog.Replace('${response_version}', ValidateValue(LWebResponse.Version));
        LLog := LLog.Replace('${response_reason}', ValidateValue(LWebResponse.ReasonString));
        LLog := LLog.Replace('${response_server}', ValidateValue(LWebResponse.Server));
        LLog := LLog.Replace('${response_realm}', ValidateValue(LWebResponse.Realm));
        LLog := LLog.Replace('${response_allow}', ValidateValue(LWebResponse.Allow));
        LLog := LLog.Replace('${response_location}', ValidateValue(LWebResponse.Location));
        LLog := LLog.Replace('${response_log_message}', ValidateValue(LWebResponse.LogMessage));
        LLog := LLog.Replace('${response_title}', ValidateValue(LWebResponse.Title));
        LLog := LLog.Replace('${response_content_encoding}', ValidateValue(LWebResponse.ContentEncoding));
        LLog := LLog.Replace('${response_content_type}', ValidateValue(LWebResponse.ContentType));
        LLog := LLog.Replace('${response_content_length}', ValidateValue(LWebResponse.ContentLength));
        LLog := LLog.Replace('${response_content_version}', ValidateValue(LWebResponse.ContentVersion));
        LLog := LLog.Replace('${response_status}', ValidateValue(LWebResponse.StatusCode));

        THorseLogger.GetDefault.NewLog(LLog);
      end;
    end;
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
  THorseLogger.GetDefault.SetLogDir(AConfig.LogDir);
  Result := BuildLogger(AConfig);
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
    if not DirectoryExists(FLogDir) then
      ForceDirectories(FLogDir);
    LFilename := FLogDir + PathDelim + 'access_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log';
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

function THorseLogger.SetLogDir(ALogDir: string): THorseLogger;
begin
  Result := Self;
  FLogDir := ALogDir.TrimRight([PathDelim]);
end;

class destructor THorseLogger.UnInitialize;
begin
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
  if AValue.IsEmpty then
    Result := '-'
  else
    Result := AValue;
end;

class function THorseLogger.ValidateValue(AValue: Integer): string;
begin
  Result := AValue.ToString;
end;

end.
