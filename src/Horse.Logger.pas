unit Horse.Logger;

interface

uses
  Horse.Logger.Manager,
  Horse.Logger.Provider.Contract,
  Horse.Logger.Thread,
  Horse.Logger.Types,
  Horse.Logger.Utils;

type

  THorseLoggerManager = Horse.Logger.Manager.THorseLoggerManager;
  THorseLoggerManagerClass = Horse.Logger.Manager.THorseLoggerManagerClass;
  IHorseLoggerProvider = Horse.Logger.Provider.Contract.IHorseLoggerProvider;
  THorseLoggerCache = Horse.Logger.Types.THorseLoggerCache;
  THorseLoggerLog = Horse.Logger.Types.THorseLoggerLog;
  THorseLoggerThread = Horse.Logger.Thread.THorseLoggerThread;
  THorseLoggerLogItemNumber = Horse.Logger.Types.THorseLoggerLogItemNumber;
  THorseLoggerLogItemString = Horse.Logger.Types.THorseLoggerLogItemString;
  THorseLoggerUtils = Horse.Logger.Utils.THorseLoggerUtils;

implementation

end.
