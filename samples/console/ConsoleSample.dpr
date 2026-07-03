program ConsoleSample;

{$APPTYPE CONSOLE}

uses
  {$IFDEF FPC}
    {$IFDEF UNIX}
    cthreads,
    {$ENDIF}
  SysUtils, Classes, fpjson,
  {$ELSE}
  System.SysUtils,
  System.Classes,
  System.JSON,
  {$ENDIF}
  Horse,
  Horse.Logger.Manager,
  Horse.Logger.Provider.Contract,
  Horse.Logger.Types;

type
  {$IFDEF FPC}
  TErrorHandler = class
  public
    procedure OnLoggerError(const AProvider: IHorseLoggerProvider; const AException: Exception);
  end;
  {$ENDIF}

  { TTextFileLogProvider }
  // Exemplo de provedor customizado que grava requisições de forma estruturada em arquivo local
  TTextFileLogProvider = class(TInterfacedObject, IHorseLoggerProvider)
  private
    FFileName: string;
  public
    constructor Create(const AFileName: string);
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
  end;

{ TTextFileLogProvider }

constructor TTextFileLogProvider.Create(const AFileName: string);
begin
  FFileName := AFileName;
end;

procedure TTextFileLogProvider.DoReceiveLogCache(ALogCache: THorseLoggerCache);
var
  LItem: TJSONObject;
  LTextFile: TextFile;
  LLogLine: string;
begin
  AssignFile(LTextFile, FFileName);
  try
    if FileExists(FFileName) then
      Append(LTextFile)
    else
      Rewrite(LTextFile);

    for LItem in ALogCache do
    begin
      LLogLine := Format('[%s] %s %s - Status: %s - IP: %s - ExecTime: %sms', [
        {$IFDEF FPC}
        LItem.Strings['time_short'],
        LItem.Strings['request_method'],
        LItem.Strings['request_path_info'],
        LItem.Strings['response_status'],
        LItem.Strings['request_clientip'],
        LItem.Strings['execution_time']
        {$ELSE}
        LItem.GetValue<string>('time_short'),
        LItem.GetValue<string>('request_method'),
        LItem.GetValue<string>('request_path_info'),
        LItem.GetValue<string>('response_status'),
        LItem.GetValue<string>('request_clientip'),
        LItem.GetValue<string>('execution_time')
        {$ENDIF}
      ]);
      Writeln(LTextFile, LLogLine);
    end;
  finally
    CloseFile(LTextFile);
  end;
end;

{$IFDEF FPC}
procedure TErrorHandler.OnLoggerError(const AProvider: IHorseLoggerProvider; const AException: Exception);
begin
  Writeln('[ERROR CALLBACK] Ocorreu uma falha no provedor de log: ' + AException.Message);
end;
{$ENDIF}

{ Rotas HTTP }

procedure PingRoute(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('pong');
end;

procedure EchoRoute(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LBody: string;
begin
  LBody := Req.Body;
  if LBody <> '' then
    Res.Send(LBody).ContentType('application/json')
  else
    Res.Send('no body').Status(THTTPStatus.BadRequest);
end;

procedure ErrorRoute(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  raise Exception.Create('Erro interno intencional demonstrativo.');
end;

var
  {$IFDEF FPC}
  LErrHandler: TErrorHandler;
  {$ENDIF}
begin
  {$IFDEF FPC}
  LErrHandler := TErrorHandler.Create;
  {$ENDIF}
  try
    // 1. Configura tratamento e reporte de erro customizado do logger
    {$IFDEF FPC}
    THorseLoggerManager.OnError := LErrHandler.OnLoggerError;
    {$ELSE}
    THorseLoggerManager.OnError := procedure(const AProvider: IHorseLoggerProvider; const AException: Exception)
      begin
        Writeln('[ERROR CALLBACK] Ocorreu uma falha no provedor de log: ' + AException.Message);
      end;
    {$ENDIF}

    // 2. Registra o nosso provedor de log em arquivo de texto
    THorseLoggerManager.RegisterProvider(TTextFileLogProvider.Create('app.log'));

    // 3. Ativa o middleware global de logs do Horse
    THorse.Use(THorseLoggerManager.HorseCallback);

    // 4. Mapeia rotas de teste real utilizando procedures estáticas nomeadas
    THorse.Get('/ping', PingRoute);
    THorse.Post('/echo', EchoRoute);
    THorse.Get('/error', ErrorRoute);

    // 5. Inicializa o servidor Horse
    Writeln('Servidor de Exemplo ativo na porta 9000.');
    Writeln('Links para testes:');
    Writeln('  - GET  http://localhost:9000/ping');
    Writeln('  - POST http://localhost:9000/echo (envie JSON no corpo)');
    Writeln('  - GET  http://localhost:9000/error (simula erro 500)');
    Writeln('Pressione Ctrl+C para encerrar o servidor.');
    Writeln('---');

    THorse.Listen(9000);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  {$IFDEF FPC}
  LErrHandler.Free;
  {$ENDIF}
end.
