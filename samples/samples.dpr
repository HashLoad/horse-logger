program samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses System.SysUtils, Horse, Horse.Logger, Horse.Logger.Provider.LogFile;

begin

  THorseLoggerManager.RegisterProvider( THorseLoggerProviderLogFile.New() );

  THorse.Use(THorseLoggerManager.HorseCallback());

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
