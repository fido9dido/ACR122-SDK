unit KeyManage;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  ACR122s, MifareInit, SamInit, Dialogs, StdCtrls, ComCtrls;

type
  TfKeyManage = class(TForm)
    mMsg: TRichEdit;
    bConnect: TButton;
    Label1: TLabel;
    cbPort: TComboBox;
    bICCon: TButton;
    bInitSam: TButton;
    bGenKeys: TButton;
    bClear: TButton;
    bReset: TButton;
    bQuit: TButton;
    procedure FormActivate(Sender: TObject);
    procedure bConnectClick(Sender: TObject);
    procedure bClearClick(Sender: TObject);
    procedure bResetClick(Sender: TObject);
    procedure bQuitClick(Sender: TObject);
    procedure bICConClick(Sender: TObject);
    procedure bInitSamClick(Sender: TObject);
    procedure bGenKeysClick(Sender: TObject);
  private
    { Private declarations }
  public

  end;

var
  fKeyManage: TfKeyManage;
  hReader : SCARDHANDLE;
  connActive :BOOL;
  PrintText : String;
  SendBuff : array [0..256] of Byte;
  RecvBuff : array [0..256] of Byte;
  Buffer : array [0..256] of Byte;
  retCode  : DWORD;
  SendLen : smallint;
  RecvLen : DWORD;
  tmpBaud  : DWORD;

procedure InitMenu();
procedure ClearBuffers();
function SendAPDUandDisplay(option: Integer): Integer;
procedure displayOut(errType: Integer; retVal: Integer; PrintText: String);
implementation

{$R *.dfm}

procedure ClearBuffers();
var indx: integer;
begin

  for indx := 0 to 256 do
    begin
      SendBuff[indx] := $00;
      RecvBuff[indx] := $00;
    end;

end;

procedure TfKeyManage.bClearClick(Sender: TObject);
begin
      fKeyManage.mMsg.Clear;
end;

procedure TfKeyManage.bConnectClick(Sender: TObject);
var
FWLEN : DWORD;
tempstr : array [0..256] of char;
begin
    PrintText := fKeyManage.cbPort.Text;

    retCode := ACR122_OpenA( PrintText, @hReader);
    if retCode = 0  then
    begin
      ConnActive := True;
      fKeyManage.bConnect.Enabled := False;
      fKeyManage.bICCon.Enabled := True;

      PrintText := 'Connection to ' + PrintText + ' success';
      displayOut( 0, 0, PrintText);

      PrintText := '';

      retCode := ACR122_GetFirmwareVersionA(hReader, 0, tempstr, @FWLEN);
      if retCode = 0 then
      begin
        PrintText := 'Firmware Version: ' + tempstr;
        displayOut(5, 0, PrintText);
      end
      else
      begin
        displayOut( 1, 0, 'Get Firmware Version failed');
      end;
    end
    else
    begin
      PrintText := 'Connection to ' + PrintText + ' failed';
      displayOut( 1, 0, PrintText);
    end;
end;

procedure TfKeyManage.bGenKeysClick(Sender: TObject);
begin
    fMifareInit.Show;
end;

procedure TfKeyManage.bICConClick(Sender: TObject);
var
indx : Integer;
begin

     ClearBuffers();

     RecvLen := 255;

     retCode := ACR122_PowerOnIcc(hReader, 0, @RecvBuff, @RecvLen);

     if retCode = 0 then
     begin
         displayOut( 0, 0, 'Power on ICC success');

         PrintText := 'ATR: ';
         for indx := 0 to RecvLen - 1 do
         begin
           PrintText := PrintText + Format('%.02X ', [RecvBuff[indx]]);
         end;
         displayOut(5, 0, PrintText);

         fKeyManage.bICCon.Enabled := False;
         fKeyManage.bInitSam.Enabled := True;
         fKeyManage.bGenKeys.Enabled := True;
         fKeyManage.bReset.Enabled := True;

     end
     else
     begin
         PrintText := IntToStr(retCode);
         displayOut( 1, 0, PrintText);
     end;


end;

procedure TfKeyManage.bInitSamClick(Sender: TObject);
begin
    fInitSAM.Show;    
end;

procedure TfKeyManage.bQuitClick(Sender: TObject);
begin
     if ConnActive = true then
     begin
        retCode := ACR122_Close(hReader);
     end;
     Application.Terminate;
end;

procedure TfKeyManage.bResetClick(Sender: TObject);
begin
     if ConnActive = true then
     begin
        retCode := ACR122_Close(hReader);
        if retCode = 0 then
        begin
             InitMenu();
        end;

     end;
end;

function SendAPDUandDisplay(option: Integer): integer;
var
indx: integer;
begin

    PrintText := '';

    displayOut(0,0,'Command:');
    for indx := 0 to SendLen - 1 do
          begin
            PrintText := PrintText + Format('%.02X ', [SendBuff[indx]]);
          end;
    displayOut(3,0, PrintText);


    PrintText := '';
    RecvLen := 255;

    if option = 0 then
    begin
        retCode := ACR122_DirectTransmit(hReader, @SendBuff, SendLen, @RecvBuff, @RecvLen);
    end
    else
    begin
        retCode := ACR122_ExchangeApdu(hReader,  0, @SendBuff, SendLen, @RecvBuff, @RecvLen);
    end;


    if retCode = 0 then
    begin
       //if RecvLen > 0 then
      // begin
          displayOut(0,0,'Response:');
          for indx := 0 to RecvLen - 1 do
          begin
            PrintText := PrintText + Format('%.02X ', [RecvBuff[indx]]);
          end;
          displayOut(2,0, PrintText);
      // end;
    end
    else
    begin
      displayOut( 1, 0, 'Send Command failed');
    end;

  SendAPDUandDisplay := retCode;

end;

procedure TfKeyManage.FormActivate(Sender: TObject);
begin
      InitMenu();
end;

procedure InitMenu();
var
indx : Integer;
begin

  connActive := False;

  fKeyManage.mMsg.Clear;

  DisplayOut(0, 0, 'Program ready');

  fKeyManage.cbPort.Clear;

  for indx := 1 to 10 do
  begin
    PrintText := 'COM' + IntToStr(indx);
    fKeyManage.cbPort.AddItem( PrintText, TObject.NewInstance);
  end;

  fKeyManage.cbPort.ItemIndex := 0;

  fKeyManage.bConnect.Enabled := True;
  fKeyManage.bICCon.Enabled := False;
  fKeyManage.bInitSam.Enabled := False;
  fKeyManage.bGenKeys.Enabled := False;


end;

procedure displayOut(errType: Integer; retVal: Integer; PrintText: String);
begin

  case errType of
    0: fKeyManage.mMsg.SelAttributes.Color := clTeal;      // Notifications
    1: begin                                                // Error Messages
         fKeyManage.mMsg.SelAttributes.Color := clRed;
         //PrintText := GetScardErrMsg(retVal);
       end;
    2: begin
         fKeyManage.mMsg.SelAttributes.Color := clBlack;
         PrintText := '< ' + PrintText;                      // Input data
       end;
    3: begin
         fKeyManage.mMsg.SelAttributes.Color := clBlack;
         PrintText := '> ' + PrintText;                      // Output data
       end;
    4: fKeyManage.mMsg.SelAttributes.Color := clRed;        // For ACOS1 error
    5: fKeyManage.mMsg.SelAttributes.Color := clBlack;      // Normal Notification
  end;
  fKeyManage.mMsg.Lines.Add(PrintText);
  fKeyManage.mMsg.SelAttributes.Color := clBlack;
  fKeyManage.mMsg.SetFocus;

end;

end.
