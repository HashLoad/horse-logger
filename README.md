# horse-logger
Middleware for access logging in HORSE

### For install in your project using [boss](https://github.com/HashLoad/boss):
``` sh
$ boss install horse-logger
```

### Format
`Format` defines the logging format with defined variables

Default: `${request_remote_addr} [${time}] ${request_user_agent} "${request_method} ${request_path_info} ${request_version}" ${response_status} ${response_content_length}`

Possible values: `time`,`execution_time`,`request_method`,`request_version`,`request_url`,`request_query`,`request_path_info`,`request_path_translated`,`request_cookie`,`request_accept`,`request_from`,`request_host`,`request_referer`,`request_user_agent`,`request_connection`,`request_derived_from`,`request_remote_addr`,`request_remote_host`,`request_script_name`,`request_server_port`,`request_remote_ip`,`request_internal_path_info`,`request_raw_path_info`,`request_cache_control`,`request_script_name`,`request_authorization`,`request_content_encoding`,`request_content_type`,`request_content_length`,`request_content_version`,`response_version`,`response_reason`,`response_server`,`response_realm`,`response_allow`,`response_location`,`response_log_message`,`response_title`,`response_content_encoding`,`response_content_type`,`response_content_length`,`response_content_version`,`response_status`

Sample Horse Logger
```delphi
uses
  Horse, Horse.Logger;

var
  App: THorse;

begin
  App := THorse.Create(9000);

  App.Use( THorseLogger.New() );

  App.Post('ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;

end.
```

Sample Horse Logger with custom log format and log folder
```delphi
uses
  Horse, Horse.Logger;

var
  App: THorse;
  HorseLoggerConfig: THorseLoggerConfig;

begin
  App := THorse.Create(9000);

  HorseLoggerConfig := THorseLoggerConfig.Create('${time} - ${request_method} ${request_path_info}', '/var/log/horse');
  App.Use( THorseLogger.New(HorseLoggerConfig) );

  App.Post('ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong');
    end);

  App.Start;

end.
```
