# horse-logger
Middleware for access logging in HORSE

#### For version 2.0.0, see the lumberjack branch:  
  [horse-logger 2.0.0](https://github.com/HashLoad/horse-logger/tree/lumberjack)

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install horse-logger
```

### Format
`Format` defines the logging format with defined variables

Default: `${request_clientip} [${time}] ${request_user_agent} "${request_method} ${request_path_info} ${request_version}" ${response_status} ${response_content_length}`

Possible values: `time`,`execution_time`,`request_clientip`,`request_method`,`request_version`,`request_url`,`request_query`,`request_path_info`,`request_path_translated`,`request_cookie`,`request_accept`,`request_from`,`request_host`,`request_referer`,`request_user_agent`,`request_connection`,`request_derived_from`,`request_remote_addr`,`request_remote_host`,`request_script_name`,`request_server_port`,`request_remote_ip`,`request_internal_path_info`,`request_raw_path_info`,`request_cache_control`,`request_script_name`,`request_authorization`,`request_content_encoding`,`request_content_type`,`request_content_length`,`request_content_version`,`response_version`,`response_reason`,`response_server`,`response_realm`,`response_allow`,`response_location`,`response_log_message`,`response_title`,`response_content_encoding`,`response_content_type`,`response_content_length`,`response_content_version`,`response_status`

Sample Horse Logger
```delphi
uses Horse, Horse.Logger;

begin
  THorse.Use(THorseLogger.New());

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
```

Sample Horse Logger with custom log format and log folder
```delphi
uses Horse, Horse.Logger;

var
  HorseLoggerConfig: THorseLoggerConfig;

begin
  HorseLoggerConfig := THorseLoggerConfig.Create('${time} - ${request_method} ${request_path_info}', '/var/log/horse');
  THorse.Use(THorseLogger.New(HorseLoggerConfig));

  THorse.Post('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end.
```
