unit Horse.Logger.Tests.Utils;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  THorseLoggerUtilsTests = class
  public
    [Test]
    procedure TestGetFormatParams_WithParams;
    [Test]
    procedure TestGetFormatParams_WithoutParams;
    [Test]
    procedure TestGetFormatParams_WithEmptyString;
    [Test]
    procedure TestGetFormatParams_WithMultipleParams;
    [Test]
    procedure TestGetFormatParams_WithDuplicateParams;
    [Test]
    procedure TestGetFormatParams_WithMalformedParams;
  end;

implementation

uses
  System.SysUtils,
  Horse.Logger.Utils;

{ THorseLoggerUtilsTests }

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithParams;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('${request_clientip}');
  Assert.AreEqual(1, Length(LResult));
  Assert.AreEqual('request_clientip', LResult[0]);
end;

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithoutParams;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('sem parametros');
  Assert.AreEqual(0, Length(LResult));
end;

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithEmptyString;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('');
  Assert.AreEqual(0, Length(LResult));
end;

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithMultipleParams;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('${request_method} - ${request_url} - ${response_status}');
  Assert.AreEqual(3, Length(LResult));
  Assert.AreEqual('request_method', LResult[0]);
  Assert.AreEqual('request_url', LResult[1]);
  Assert.AreEqual('response_status', LResult[2]);
end;

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithDuplicateParams;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('${request_method} e novamente ${request_method}');
  Assert.AreEqual(2, Length(LResult));
  Assert.AreEqual('request_method', LResult[0]);
  Assert.AreEqual('request_method', LResult[1]);
end;

procedure THorseLoggerUtilsTests.TestGetFormatParams_WithMalformedParams;
var
  LResult: TArray<string>;
begin
  LResult := THorseLoggerUtils.GetFormatParams('${request_method');
  Assert.AreEqual(0, Length(LResult));

  LResult := THorseLoggerUtils.GetFormatParams('${}');
  Assert.AreEqual(0, Length(LResult));

  LResult := THorseLoggerUtils.GetFormatParams('${   }');
  Assert.AreEqual(0, Length(LResult));

  LResult := THorseLoggerUtils.GetFormatParams('${request_method} e ${request_url');
  Assert.AreEqual(1, Length(LResult));
  Assert.AreEqual('request_method', LResult[0]);
  
  LResult := THorseLoggerUtils.GetFormatParams('${  request_method  }');
  Assert.AreEqual(0, Length(LResult));
end;

initialization
  TDUnitX.RegisterTestFixture(THorseLoggerUtilsTests);

end.
