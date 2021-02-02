unit Horse.Logger.Provider.Contract;

interface

uses
  Horse.Logger.Types;

type
  IHorseLoggerProvider = interface
    ['{179D41E3-7327-434E-A533-05D3ED71DF27}']
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
  end;

implementation

end.
