program samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses System.SysUtils, Horse, Horse.Logger;

begin
  THorse.Use(THorseLogger.New());

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
