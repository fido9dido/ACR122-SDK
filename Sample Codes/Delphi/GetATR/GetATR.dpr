program GetATR;

uses
  Forms,
  ATR in 'ATR.pas' {MainGetATR},
  ACR122s in 'ACR122s.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainGetATR, MainGetATR);
  Application.Run;
end.
