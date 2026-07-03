unit Horse.Logger.Tests.Manager;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON, System.SyncObjs, System.DateUtils,
  System.Classes,
  Horse.Logger.Types, Horse.Logger.Provider.Contract, Horse.Logger.Manager;

type
  TTestProvider = class(TInterfacedObject, IHorseLoggerProvider)
  private
    class var FReceivedLogs: THorseLoggerCache;
    class var FEvent: TEvent;
  public
    class var FEnabled: Boolean;
    class var FRegistered: Boolean;
    class procedure ClearReceivedLogs;
    class property ReceivedLogs: THorseLoggerCache read FReceivedLogs;
    class property Event: TEvent read FEvent;
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
    class constructor Create;
    class destructor Destroy;
  end;

  TExceptionProvider = class(TInterfacedObject, IHorseLoggerProvider)
  public
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
  end;

  TAuxTestProvider = class(TInterfacedObject, IHorseLoggerProvider)
  private
    class var FReceivedLogs: THorseLoggerCache;
    class var FEvent: TEvent;
  public
    class var FEnabled: Boolean;
    class var FRegistered: Boolean;
    class procedure ClearReceivedLogs;
    class property ReceivedLogs: THorseLoggerCache read FReceivedLogs;
    class property Event: TEvent read FEvent;
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
    class constructor Create;
    class destructor Destroy;
  end;

  [TestFixture]
  THorseLoggerManagerTests = class
  private
    FProvider: IHorseLoggerProvider;
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
    procedure TestNewLog_ShouldDispatchToProvider;
    [Test]
    procedure TestValidateValue_String;
    [Test]
    procedure TestValidateValue_Integer;
    [Test]
    procedure TestValidateValue_DateTime_Short;
    [Test]
    procedure TestValidateValue_DateTime_Long;
    [Test]
    procedure TestValidateValue_Bytes_WithoutSeparator;
    [Test]
    procedure TestValidateValue_Bytes_WithSeparator;
    [Test]
    procedure TestValidateValue_JSON_Valid;
    [Test]
    procedure TestValidateValue_JSON_Invalid;
    [Test]
    procedure TestValidateValue_JSON_NonJsonContentType;
    [Test]
    procedure TestNewLog_WithProviderException_ShouldNotAffectOtherProviders;
    [Test]
    procedure TestUnInitialize_WithRemainingLogs_ShouldDispatchBeforeTermination;
    [Test]
    procedure TestNewLog_WithMultipleProviders_ShouldDeliverToAll;
    [Test]
    procedure TestNewLog_WithExtremeConcurrency_ShouldNotDeadlockOrLoseLogs;
  end;

  procedure RegistrarProviderSeNecessario;

implementation

type
  THorseLoggerManagerHack = class(THorseLoggerManager);

{ TTestProvider }

class constructor TTestProvider.Create;
begin
  FReceivedLogs := THorseLoggerCache.Create(True);
  FEvent := TEvent.Create;
  FEnabled := False;
  FRegistered := False;
end;

class destructor TTestProvider.Destroy;
begin
  FReceivedLogs.Free;
  FEvent.Free;
end;

class procedure TTestProvider.ClearReceivedLogs;
begin
  FReceivedLogs.Clear;
  FEvent.ResetEvent;
end;

procedure TTestProvider.DoReceiveLogCache(ALogCache: THorseLoggerCache);
var
  LItem: TJSONObject;
begin
  if not FEnabled then
    Exit;
  for LItem in ALogCache do
  begin
    FReceivedLogs.Add(TJSONObject(LItem.Clone));
  end;
  FEvent.SetEvent;
end;

{ TAuxTestProvider }

class constructor TAuxTestProvider.Create;
begin
  FReceivedLogs := THorseLoggerCache.Create(True);
  FEvent := TEvent.Create;
  FEnabled := False;
  FRegistered := False;
end;

class destructor TAuxTestProvider.Destroy;
begin
  FReceivedLogs.Free;
  FEvent.Free;
end;

class procedure TAuxTestProvider.ClearReceivedLogs;
begin
  FReceivedLogs.Clear;
  FEvent.ResetEvent;
end;

procedure TAuxTestProvider.DoReceiveLogCache(ALogCache: THorseLoggerCache);
var
  LItem: TJSONObject;
begin
  if not FEnabled then
    Exit;
  for LItem in ALogCache do
  begin
    FReceivedLogs.Add(TJSONObject(LItem.Clone));
  end;
  FEvent.SetEvent;
end;

procedure RegistrarProviderSeNecessario;
begin
  if not TTestProvider.FRegistered then
  begin
    THorseLoggerManager.RegisterProvider(TTestProvider.Create);
    TTestProvider.FRegistered := True;
  end;
end;

{ THorseLoggerManagerTests }

procedure THorseLoggerManagerTests.SetupFixture;
begin
  RegistrarProviderSeNecessario;
end;

procedure THorseLoggerManagerTests.TearDownFixture;
begin
end;

procedure THorseLoggerManagerTests.Setup;
begin
  TTestProvider.ClearReceivedLogs;
  THorseLoggerManagerHack(THorseLoggerManager.DefaultManager).ResetLogCache;
  TTestProvider.FEnabled := True;
end;

procedure THorseLoggerManagerTests.TearDown;
begin
  Sleep(50);
  TTestProvider.FEnabled := False;
  TTestProvider.ClearReceivedLogs;
end;

procedure THorseLoggerManagerTests.TestNewLog_ShouldDispatchToProvider;
var
  LLog: TJSONObject;
  LWaitResult: TWaitResult;
begin
  LLog := TJSONObject.Create;
  LLog.AddPair('test_key', 'test_value');

  THorseLoggerManager.DefaultManager.NewLog(LLog);

  // Aguarda até que o provider receba o log de forma assíncrona (máximo 500ms)
  LWaitResult := TTestProvider.Event.WaitFor(500);

  var LItem: TJSONObject;
  var LFoundItem: TJSONObject;
  LFoundItem := nil;
  for LItem in TTestProvider.ReceivedLogs do
  begin
    if LItem.GetValue<string>('test_key') = 'test_value' then
    begin
      LFoundItem := LItem;
      Break;
    end;
  end;
  Assert.IsNotNull(LFoundItem, 'O log de teste enviado nao foi recebido pelo provider.');
  Assert.AreEqual('test_value', LFoundItem.GetValue<string>('test_key'), 'O valor do log recebido esta incorreto.');
end;

procedure THorseLoggerManagerTests.TestValidateValue_String;
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := THorseLoggerManagerHack.ValidateValue('hello');
  try
    Assert.AreEqual('hello', LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_Integer;
var
  LJSONValue: TJSONValue;
begin
  LJSONValue := THorseLoggerManagerHack.ValidateValue(42);
  try
    Assert.AreEqual('42', LJSONValue.ToString);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_DateTime_Short;
var
  LDateTime: TDateTime;
  LJSONValue: TJSONValue;
begin
  LDateTime := EncodeDateTime(2026, 7, 2, 23, 45, 0, 0);

  LJSONValue := THorseLoggerManagerHack.ValidateValue(LDateTime, True);
  try
    // Asserção estrita literal para garantir que o formato do mês não seja mascarado (MM em vez de mm)
    Assert.AreEqual('02/07/2026 23:45:00.000', LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_DateTime_Long;
var
  LDateTime: TDateTime;
  LJSONValue: TJSONValue;
  LExpected: string;
begin
  LDateTime := EncodeDateTime(2026, 7, 2, 23, 45, 0, 0);
  LExpected := FormatDateTime('dd/MMMM/yyyy hh:mm:ss.zzz', LDateTime);

  LJSONValue := THorseLoggerManagerHack.ValidateValue(LDateTime, False);
  try
    Assert.AreEqual(LExpected, LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_Bytes_WithoutSeparator;
var
  LBytes: TBytes;
  LJSONValue: TJSONValue;
begin
  LBytes := TBytes.Create(65, 66, 67);
  LJSONValue := THorseLoggerManagerHack.ValidateValue(LBytes, '');
  try
    Assert.AreEqual('414243', LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_Bytes_WithSeparator;
var
  LBytes: TBytes;
  LJSONValue: TJSONValue;
begin
  LBytes := TBytes.Create(65, 66, 67);
  LJSONValue := THorseLoggerManagerHack.ValidateValue(LBytes, '-');
  try
    Assert.AreEqual('-41-42-43', LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_JSON_Valid;
var
  LJSONValue: TJSONValue;
  LJSONInput: string;
begin
  LJSONInput := '{"name":"Horse","version":"3.1"}';
  LJSONValue := THorseLoggerManagerHack.ValidateValue(LJSONInput, 'application/json');
  try
    // Garante que o retorno é um objeto JSON parseado nativamente de forma estruturada
    Assert.IsTrue(LJSONValue is TJSONObject, 'O valor retornado deveria ser um TJSONObject real.');
    Assert.AreEqual('Horse', TJSONObject(LJSONValue).GetValue<string>('name'));
    Assert.AreEqual('3.1', TJSONObject(LJSONValue).GetValue<string>('version'));
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_JSON_Invalid;
var
  LJSONValue: TJSONValue;
  LJSONInput: string;
begin
  LJSONInput := '{"name":';
  LJSONValue := THorseLoggerManagerHack.ValidateValue(LJSONInput, 'application/json');
  try
    Assert.AreEqual(LJSONInput, LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

procedure THorseLoggerManagerTests.TestValidateValue_JSON_NonJsonContentType;
var
  LJSONValue: TJSONValue;
  LJSONInput: string;
begin
  LJSONInput := '{"name":"Horse"}';
  LJSONValue := THorseLoggerManagerHack.ValidateValue(LJSONInput, 'text/plain');
  try
    Assert.AreEqual(LJSONInput, LJSONValue.Value);
  finally
    LJSONValue.Free;
  end;
end;

{ TExceptionProvider }

procedure TExceptionProvider.DoReceiveLogCache(ALogCache: THorseLoggerCache);
begin
  raise Exception.Create('Erro intencional no provider de teste');
end;

{ THorseLoggerManagerTests }

procedure THorseLoggerManagerTests.TestNewLog_WithProviderException_ShouldNotAffectOtherProviders;
var
  LExceptProvider: IHorseLoggerProvider;
  LLog: TJSONObject;
  LWaitResult: TWaitResult;
  LErrorFired: Boolean;
begin
  LErrorFired := False;
  THorseLoggerManager.OnError := procedure(const AProvider: IHorseLoggerProvider; const AException: Exception)
    begin
      if AException.Message.Contains('Erro intencional no provider de teste') then
        LErrorFired := True;
    end;

  try
    LExceptProvider := TExceptionProvider.Create;
    THorseLoggerManager.RegisterProvider(LExceptProvider);

    LLog := TJSONObject.Create;
    LLog.AddPair('robustness', 'test');
    THorseLoggerManager.DefaultManager.NewLog(LLog);

    LWaitResult := TTestProvider.Event.WaitFor(500);
    Sleep(50);

    Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult, 'O log nao foi entregue ao TTestProvider apos a excecao do primeiro provider.');
    Assert.IsTrue(TTestProvider.ReceivedLogs.Count > 0, 'O log deveria ter sido recebido pelo provider de teste.');
    Assert.IsTrue(LErrorFired, 'O callback OnError do Manager nao foi invocado com a excecao do provider.');
  finally
    THorseLoggerManager.OnError := nil;
  end;
end;

procedure THorseLoggerManagerTests.TestUnInitialize_WithRemainingLogs_ShouldDispatchBeforeTermination;
var
  LTempManager: THorseLoggerManager;
  LLog: TJSONObject;
  LFound: Boolean;
  LItem: TJSONObject;
begin
  LTempManager := THorseLoggerManager.Create(True);
  LTempManager.FreeOnTerminate := False;
  LTempManager.Start;
  Sleep(50);
  try
    LLog := TJSONObject.Create;
    LLog.AddPair('shutdown_test', 'persisted_value');
    LTempManager.NewLog(LLog);

    LTempManager.Terminate;
    LTempManager.GetEvent.SetEvent;
    LTempManager.WaitFor;
  finally
    LTempManager.Free;
  end;

  LFound := False;
  for LItem in TTestProvider.ReceivedLogs do
  begin
    if LItem.GetValue<string>('shutdown_test') = 'persisted_value' then
    begin
      LFound := True;
      Break;
    end;
  end;

  if not LFound then
  begin
    var LLogListStr: string;
    LLogListStr := '';
    for LItem in TTestProvider.ReceivedLogs do
      LLogListStr := LLogListStr + ' | ' + LItem.ToString;
    Assert.IsTrue(LFound, 'Logs residuais no cache foram descartados durante o desligamento do Logger. Logs recebidos: ' + LLogListStr);
  end
  else
    Assert.IsTrue(True);
end;

procedure THorseLoggerManagerTests.TestNewLog_WithMultipleProviders_ShouldDeliverToAll;
var
  LLog: TJSONObject;
  LWaitResult1: TWaitResult;
  LWaitResult2: TWaitResult;
  LProviderAux: IHorseLoggerProvider;
begin
  TTestProvider.ClearReceivedLogs;
  TTestProvider.FEnabled := True;

  LProviderAux := TAuxTestProvider.Create;
  THorseLoggerManager.RegisterProvider(LProviderAux);
  TAuxTestProvider.FEnabled := True;
  TAuxTestProvider.ClearReceivedLogs;

  try
    LLog := TJSONObject.Create;
    LLog.AddPair('multi_provider_test', 'value');
    THorseLoggerManager.DefaultManager.NewLog(LLog);

    LWaitResult1 := TTestProvider.Event.WaitFor(500);
    LWaitResult2 := TAuxTestProvider.Event.WaitFor(500);

    Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult1, 'TTestProvider nao sinalizou o log.');
    Assert.AreEqual(TWaitResult.wrSignaled, LWaitResult2, 'TAuxTestProvider nao sinalizou o log.');

    Assert.AreEqual(1, TTestProvider.ReceivedLogs.Count, 'TTestProvider deveria ter 1 log.');
    Assert.AreEqual(1, TAuxTestProvider.ReceivedLogs.Count, 'TAuxTestProvider deveria ter 1 log.');
  finally
    TTestProvider.FEnabled := False;
    TAuxTestProvider.FEnabled := False;
  end;
end;

procedure THorseLoggerManagerTests.TestNewLog_WithExtremeConcurrency_ShouldNotDeadlockOrLoseLogs;
var
  LThreads: TArray<TThread>;
  I: Integer;
  LActiveThreads: Int64;
  LItem: TJSONObject;
  LMatchCount: Integer;
begin
  TTestProvider.ClearReceivedLogs;
  TTestProvider.FEnabled := True;

  SetLength(LThreads, 5);
  LActiveThreads := 5;

  for I := 0 to 4 do
  begin
    LThreads[I] := TThread.CreateAnonymousThread(
      procedure
      var
        J: Integer;
        LLog: TJSONObject;
      begin
        for J := 1 to 20 do
        begin
          LLog := TJSONObject.Create;
          LLog.AddPair('concurrency_index', J.ToString);
          THorseLoggerManager.DefaultManager.NewLog(LLog);
          Sleep(5);
        end;
        TInterlocked.Decrement(LActiveThreads);
      end);
    LThreads[I].FreeOnTerminate := True;
    LThreads[I].Start;
  end;

  I := 0;
  while (TInterlocked.Read(LActiveThreads) > 0) and (I < 100) do
  begin
    Sleep(50);
    Inc(I);
  end;

  Sleep(300);

  Assert.AreEqual(Int64(0), TInterlocked.Read(LActiveThreads), 'Nem todas as threads de gravacao terminaram no tempo limite.');
  
  LMatchCount := 0;
  for LItem in TTestProvider.ReceivedLogs do
  begin
    if LItem.FindValue('concurrency_index') <> nil then
      Inc(LMatchCount);
  end;

  Assert.AreEqual(100, LMatchCount, 'Deveria ter recebido exatamente 100 logs das threads paralelas.');
  TTestProvider.FEnabled := False;
end;

initialization
  TDUnitX.RegisterTestFixture(THorseLoggerManagerTests);

end.
