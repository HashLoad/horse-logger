program Horse.Logger.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.TestFramework,
  Horse.Logger.Tests.Utils in 'Horse.Logger.Tests.Utils.pas',
  Horse.Logger.Tests.Manager in 'Horse.Logger.Tests.Manager.pas',
  Horse.Logger.Tests.Integration in 'Horse.Logger.Tests.Integration.pas',
  Horse.Logger.Utils in '..\src\Horse.Logger.Utils.pas',
  Horse.Logger.Types in '..\src\Horse.Logger.Types.pas',
  Horse.Logger.Thread in '..\src\Horse.Logger.Thread.pas',
  Horse.Logger.Manager in '..\src\Horse.Logger.Manager.pas',
  Horse.Logger.Provider.Contract in '..\src\Horse.Logger.Provider.Contract.pas',
  Horse.Logger in '..\src\Horse.Logger.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
begin
  try
    ReportMemoryLeaksOnShutdown := True;

    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
