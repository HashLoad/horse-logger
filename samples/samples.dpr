program samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, Horse, Horse.Logger;

var
  App: THorse;

begin
  App := THorse.Create(9000);

  App.Use(THorseLogger.New());

  App.Post('ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;

end.
