# horse-logger
<b>horse-logger</b> is an official middleware for logging in APIs developed with the <a href="https://github.com/HashLoad/horse">Horse</a> framework.
<br>We created a channel on Telegram for questions and support:<br><br>
<a href="https://t.me/hashload">
  <img src="https://img.shields.io/badge/telegram-join%20channel-7289DA?style=flat-square">
</a>

## ⚙️ Installation
Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
boss install horse-logger
```
If you choose to install manually, simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../horse-logger/src
```

## ✔️ Compatibility
This middleware is compatible with projects developed in:
- [X] Delphi
- [X] Lazarus

## 🧬 Official Providers
| Provider | Delphi | Lazarus |
| --------------------------------------------------------------------- | -------------------- | --------------------------- |
|  [console](https://github.com/HashLoad/horse-logger-provider-console) | &nbsp;&nbsp;&nbsp;✔️ | &nbsp;&nbsp;&nbsp;&nbsp;✔️ |
|  [file](https://github.com/HashLoad/horse-logger-provider-logfile)    | &nbsp;&nbsp;&nbsp;✔️ | &nbsp;&nbsp;&nbsp;&nbsp;✔️ |

## ⚡️ Quickstart & Samples
We provide a complete, real-life sample project showing how to integrate `horse-logger` with a custom text file log provider and handle exceptions globally. You can find it in the [`samples/`](samples/console/ConsoleSample.dpr) folder.

### Registering custom providers and handling logging errors:
```delphi
uses
  Horse,
  Horse.Logger.Manager,
  Horse.Logger.Provider.Contract;

begin
  // Set global handler for logging errors (optional but recommended)
  THorseLoggerManager.OnError := procedure(const AProvider: IHorseLoggerProvider; const AException: Exception)
    begin
      Writeln('Log Provider ' + AProvider.ClassName + ' failed: ' + AException.Message);
    end;

  // Register your custom providers
  THorseLoggerManager.RegisterProvider(TMyCustomLogProvider.Create);

  // Enable middleware
  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Listen(9000);
end.
```

## ⚠️ License
`horse-logger` is free and open-source middleware licensed under the [MIT License](https://github.com/HashLoad/horse-logger/blob/master/LICENSE). 
