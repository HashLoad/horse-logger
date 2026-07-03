unit Horse.Logger.Tests.Integration;

interface

uses
  DUnitX.TestFramework, System.Classes, System.SysUtils, System.JSON,
  System.Net.HttpClient, System.SyncObjs, Horse, Horse.Logger.Manager,
  Horse.Logger.Types;

type
  THorseServerThread = class(TThread)
  private
    FPort: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const APort: Integer);
  end;

  [TestFixture]
  THorseLoggerIntegrationTests = class
  private
    FServerThread: THorseServerThread;
    FClient: THTTPClient;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGET_ShouldLogRequestAndResponse;
    [Test]
    procedure TestPOST_WithJSON_ShouldLogRequestAndResponseContent;
    [Test]
    procedure TestGET_WithErrorInRoute_ShouldStillLogRequestAndResponse;
    [Test]
    procedure TestLogContractSchema;
  end;

implementation

uses
  Horse.Logger.Tests.Manager,
  Horse.Logger.Provider.Contract;

type
  THorseLoggerManagerHack = class(THorseLoggerManager);

{ THorseServerThread }

constructor THorseServerThread.Create(const APort: Integer);
begin
  inherited Create(False);
  FPort := APort;
  FreeOnTerminate := False;
end;

procedure THorseServerThread.Execute;
begin
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    begin
      Res.Send('pong');
    end);

  THorse.Post('/echo',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    var
      LBody: TJSONObject;
      LRawBody: string;
    begin
      LRawBody := Req.Body;
      if LRawBody <> '' then
      begin
        LBody := TJSONObject.ParseJSONValue(LRawBody) as TJSONObject;
        try
          if Assigned(LBody) then
            Res.Send(LRawBody).ContentType('application/json')
          else
            Res.Send('invalid json').Status(THTTPStatus.BadRequest);
        finally
          LBody.Free;
        end;
      end
      else
        Res.Send('no body').Status(THTTPStatus.BadRequest);
    end);

  THorse.Get('/error',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TNextProc)
    begin
      raise Exception.Create('Erro interno intencional de teste');
    end);

  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Listen(FPort);
end;

{ THorseLoggerIntegrationTests }

procedure THorseLoggerIntegrationTests.SetupFixture;
begin
  FServerThread := THorseServerThread.Create(9090);
  Sleep(200);
  FClient := THTTPClient.Create;
  RegistrarProviderSeNecessario;
end;

procedure THorseLoggerIntegrationTests.TearDownFixture;
begin
  FClient.Free;
  THorse.StopListen;
  FServerThread.WaitFor;
  FServerThread.Free;
end;

procedure THorseLoggerIntegrationTests.Setup;
begin
  TTestProvider.ClearReceivedLogs;
  THorseLoggerManagerHack(THorseLoggerManager.DefaultManager).ResetLogCache;
  TTestProvider.FEnabled := True;
end;

procedure THorseLoggerIntegrationTests.TearDown;
begin
  Sleep(50);
  TTestProvider.FEnabled := False;
  TTestProvider.ClearReceivedLogs;
end;

procedure THorseLoggerIntegrationTests.TestGET_ShouldLogRequestAndResponse;
var
  LResponse: IHTTPResponse;
  LWaitResult: TWaitResult;
  LLog: TJSONObject;
begin
  LResponse := FClient.Get('http://localhost:9090/ping');
  Assert.AreEqual(200, LResponse.StatusCode);
  Assert.AreEqual('pong', LResponse.ContentAsString);

  LWaitResult := TTestProvider.Event.WaitFor(500);
  Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult, 'O log assíncrono não foi despachado para o provider.');
  
  if TTestProvider.ReceivedLogs.Count <> 1 then
  begin
    Writeln('--- DEBUG GET: Recebidos ' + IntToStr(TTestProvider.ReceivedLogs.Count) + ' logs ---');
    for var I := 0 to TTestProvider.ReceivedLogs.Count - 1 do
      Writeln('LOG ' + IntToStr(I) + ': ' + TTestProvider.ReceivedLogs.Items[I].ToString);
  end;
  Assert.AreEqual(1, TTestProvider.ReceivedLogs.Count, 'O provider deveria ter exatamente 1 log.');

  LLog := TTestProvider.ReceivedLogs.Items[0];
  Assert.AreEqual('GET', LLog.GetValue<string>('request_method'), 'Método HTTP incorreto no log.');
  Assert.AreEqual('/ping', LLog.GetValue<string>('request_path_info'), 'Path info incorreto no log.');
  Assert.AreEqual('200', LLog.GetValue<string>('response_status'), 'Status code da resposta incorreto no log.');
  Assert.AreEqual('pong', LLog.GetValue<string>('response_content'), 'Conteúdo de resposta incorreto no log.');
end;

procedure THorseLoggerIntegrationTests.TestPOST_WithJSON_ShouldLogRequestAndResponseContent;
var
  LResponse: IHTTPResponse;
  LWaitResult: TWaitResult;
  LPostData: TStringStream;
  LLog: TJSONObject;
begin
  LPostData := TStringStream.Create('{"input":"hello"}', TEncoding.UTF8);
  try
    FClient.ContentType := 'application/json';
    LResponse := FClient.Post('http://localhost:9090/echo', LPostData);
    Assert.AreEqual(200, LResponse.StatusCode);
    Assert.IsTrue(LResponse.ContentAsString.Contains('"input"'), 'Resposta HTTP nao contem "input". Recebido: ' + LResponse.ContentAsString);
    Assert.IsTrue(LResponse.ContentAsString.Contains('"hello"'), 'Resposta HTTP nao contem "hello". Recebido: ' + LResponse.ContentAsString);
  finally
    LPostData.Free;
  end;

  LWaitResult := TTestProvider.Event.WaitFor(500);
  Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult, 'O log assíncrono não foi despachado para o provider.');
  Assert.AreEqual(1, TTestProvider.ReceivedLogs.Count, 'O provider deveria ter exatamente 1 log.');

  LLog := TTestProvider.ReceivedLogs.Items[0];
  Writeln('--- DEBUG POST LOG: ' + LLog.ToString);
  
  Assert.AreEqual('POST', LLog.GetValue<string>('request_method'), 'Método HTTP incorreto no log.');
  Assert.AreEqual('/echo', LLog.GetValue<string>('request_path_info'), 'Path info incorreto no log.');
  Assert.AreEqual('200', LLog.GetValue<string>('response_status'), 'Status code da resposta incorreto no log.');
  
  Assert.AreEqual('7b22696e707574223a2268656c6c6f227d', LLog.GetValue<string>('request_content').ToLower, 'Corpo da requisicao incorreto no log. LOG: ' + LLog.ToString);
  var LResponseContent: TJSONValue := LLog.GetValue('response_content');
  Assert.IsNotNull(LResponseContent, 'response_content nao encontrado no log');
  Assert.IsTrue(LResponseContent is TJSONObject, 'response_content deveria ser um TJSONObject estruturado.');
  Assert.AreEqual('hello', TJSONObject(LResponseContent).GetValue<string>('input'), 'Atributo "input" incorreto no response_content do log.');
end;

procedure THorseLoggerIntegrationTests.TestGET_WithErrorInRoute_ShouldStillLogRequestAndResponse;
var
  LResponse: IHTTPResponse;
  LWaitResult: TWaitResult;
  LLog: TJSONObject;
begin
  try
    LResponse := FClient.Get('http://localhost:9090/error');
  except
  end;

  Assert.AreEqual(500, LResponse.StatusCode);

  LWaitResult := TTestProvider.Event.WaitFor(500);
  Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult, 'O log do erro HTTP nao foi despachado.');
  Assert.AreEqual(1, TTestProvider.ReceivedLogs.Count, 'O provider deveria ter recebido exatamente 1 log.');

  LLog := TTestProvider.ReceivedLogs.Items[0];
  Assert.AreEqual('GET', LLog.GetValue<string>('request_method'), 'Metodo HTTP incorreto no log.');
  Assert.AreEqual('/error', LLog.GetValue<string>('request_path_info'), 'Path info incorreto no log.');
  Assert.AreEqual('500', LLog.GetValue<string>('response_status'), 'Status code 500 incorreto no log.');
end;

procedure THorseLoggerIntegrationTests.TestLogContractSchema;
var
  LResponse: IHTTPResponse;
  LWaitResult: TWaitResult;
  LLog: TJSONObject;
  LRequiredFields: TArray<string>;
  LField: string;
begin
  LResponse := FClient.Get('http://localhost:9090/ping');
  Assert.AreEqual(200, LResponse.StatusCode);

  LWaitResult := TTestProvider.Event.WaitFor(500);
  Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult, 'O log de integracao nao foi despachado.');
  Assert.AreEqual(1, TTestProvider.ReceivedLogs.Count);

  LLog := TTestProvider.ReceivedLogs.Items[0];

  LRequiredFields := TArray<string>.Create(
    'time', 'time_short', 'execution_time', 'request_clientip', 'request_method',
    'request_version', 'request_url', 'request_query', 'request_path_info',
    'request_host', 'request_content_type', 'request_content_length', 'request_content',
    'response_content_type', 'response_content_length', 'response_content', 'response_status'
  );

  for LField in LRequiredFields do
  begin
    Assert.IsNotNull(LLog.FindValue(LField), 'O campo de contrato obrigatório "' + LField + '" nao foi encontrado no JSON de log.');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THorseLoggerIntegrationTests);

end.
