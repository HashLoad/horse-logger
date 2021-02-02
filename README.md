# horse-logger
Middleware for access logging in HORSE

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install horse-logger
```

Values sent to providers: `time`,`execution_time`,`request_clientip`,`request_method`,`request_version`,`request_url`,`request_query`,`request_path_info`,`request_path_translated`,`request_cookie`,`request_accept`,`request_from`,`request_host`,`request_referer`,`request_user_agent`,`request_connection`,`request_derived_from`,`request_remote_addr`,`request_remote_host`,`request_script_name`,`request_server_port`,`request_remote_ip`,`request_internal_path_info`,`request_raw_path_info`,`request_cache_control`,`request_script_name`,`request_authorization`,`request_content_encoding`,`request_content_type`,`request_content_length`,`request_content_version`,`response_version`,`response_reason`,`response_server`,`response_realm`,`response_allow`,`response_location`,`response_log_message`,`response_title`,`response_content_encoding`,`response_content_type`,`response_content_length`,`response_content_version`,`response_status`

### Sample Horse Logger

Needs to install the logfile provider for the sample to work correctly.
Run: boss install horse-logger-provider-logfile

```delphi
uses Horse, Horse.Logger, Horse.Logger.Provider.LogFile;

begin

  THorseLoggerManager.RegisterProvider( THorseLoggerProviderLogFile.New() );

  THorse.Use( THorseLoggerManager.HorseCallback() );

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);

end.
```

### Official providers

- [Console](https://github.com/HashLoad/horse-logger-provider-console)
- [LogFile](https://github.com/HashLoad/horse-logger-provider-logfile)
