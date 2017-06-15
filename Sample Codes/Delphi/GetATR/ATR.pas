unit ATR;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  ACR122s, Dialogs, StdCtrls, ComCtrls;

type
  TMainGetATR = class(TForm)
    mMsg: TRichEdit;
    bGetAtr: TButton;
    bClear: TButton;
    bReset: TButton;
    bQuit: TButton;
    Label1: TLabel;
    cbReader: TComboBox;
    bConnect: TButton;
    procedure bQuitClick(Sender: TObject);
    procedure bResetClick(Sender: TObject);
    procedure bClearClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure bGetAtrClick(Sender: TObject);
    procedure bConnectClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainGetATR: TMainGetATR;
  hReader: SCARDHANDLE;
  retCode: DWORD;
  PrintText: String;
  ConnActive: BOOL;
  RecvLen : DWORD;
  RecvBuff : array [0..256] of Byte;

procedure InitMenu();
procedure displayOut(errType: Integer; retVal: Integer; PrintText: String);

implementation

{$R *.dfm}

procedure TMainGetATR.bClearClick(Sender: TObject);
begin
   mMsg.Clear;
end;

procedure InitMenu();
var
indx : Integer;
begin

  connActive := False;
  MainGetATR.mMsg.Clear;
  DisplayOut(0, 0, 'Program ready');
  MainGetATR.bConnect.Enabled := True;
  MainGetATR.bGetAtr.Enabled := False;
  MainGetATR.bReset.Enabled := False;

  MainGetATR.cbReader.Clear;

  for indx := 1 to 10 do
  begin
    PrintText := 'COM' + IntToStr(indx);
    MainGetATR.cbReader.AddItem( PrintText, TObject.NewInstance);
  end;
    
  MainGetATR.cbReader.ItemIndex := 0;


end;

procedure displayOut(errType: Integer; retVal: Integer; PrintText: String);
begin

  case errType of
    0: MainGetATR.mMsg.SelAttributes.Color := clTeal;      // Notifications
    1: begin                                                // Error Messages
         MainGetATR.mMsg.SelAttributes.Color := clRed;
         //PrintText := GetScardErrMsg(retVal);
       end;
    2: begin
         MainGetATR.mMsg.SelAttributes.Color := clBlack;
         PrintText := '< ' + PrintText;                      // Input data
       end;
    3: begin
         MainGetATR.mMsg.SelAttributes.Color := clBlack;
         PrintText := '> ' + PrintText;                      // Output data
       end;
    4: MainGetATR.mMsg.SelAttributes.Color := clRed;        // For ACOS1 error
    5: MainGetATR.mMsg.SelAttributes.Color := clBlack;      // Normal Notification
  end;
  MainGetATR.mMsg.Lines.Add(PrintText);
  MainGetATR.mMsg.SelAttributes.Color := clBlack;
  MainGetATR.mMsg.SetFocus;

end;

procedure TMainGetATR.bGetAtrClick(Sender: TObject);
var
indx: integer;
SendBuff : array [0..256] of Byte;
CardType : Byte;

begin
    SendBuff[0] :=  $D4;
    SendBuff[1] :=  $60;
    SendBuff[2] :=  $01;
    SendBuff[3] :=  $01;
    SendBuff[4] :=  $20;
    SendBuff[5] :=  $23;
    SendBuff[6] :=  $11;
    SendBuff[7] :=  $04;
    SendBuff[8] :=  $10;

    PrintText := '';
    RecvLen := 255;
    retCode := ACR122_DirectTransmit(hReader, @SendBuff, 9, @RecvBuff, @RecvLen);

    if retCode = 0 then
    begin
       displayOut(0,0,'ATR');
       for indx := 0 to Recvlen - 1 do
          begin
            PrintText := PrintText + Format('%.02X ', [RecvBuff[indx]]);
          end;
       displayOut(2,0, PrintText);
       if RecvLen > 3 then
       begin
           CardType := RecvBuff[8];
           Case CardType of
           $18 : PrintText := 'Mifare 4K';
           $00 : PrintText := 'Mifare Ultralight';
           $28 : PrintText := 'ISO 14443-4 Type A';
           $08 : PrintText := 'Mifare 1K';
           $09 : PrintText := 'Mifare Mini';
           $20 : PrintText := 'Mifare DesFire';
           $98 : PrintText := 'GemPlus MPCOS';
           else
                begin
                CardType := RecvBuff[3];
                Case CardType of
                $23 : PrintText := 'ISO 14443-4 Type B';
                $11 : PrintText := 'FeliCa 212K';
                $04 : PrintText := 'Topaz';
                else
                    PrintText := 'Unknown contactless card';
                End;

                end;
           End;

           PrintText := PrintText + ' detected';
           displayOut(0,0, PrintText);
       end
       else
       begin
          displayOut(0,0, 'No contactless card detected');
       end;




    end
    else
    begin
      displayOut(1, 0, 'Get ATR failed');
    end;

end;

procedure TMainGetATR.bConnectClick(Sender: TObject);
var
FWLEN : DWORD;
tempstr : array [0..256] of char;
begin

    PrintText := MainGetATR.cbReader.Text;

    retCode := ACR122_OpenA( PrintText, @hReader);
    if retCode = 0  then
    begin
      ConnActive := TRUE;
      MainGetATR.bConnect.Enabled := False;
      MainGetATR.bReset.Enabled := True;
      MainGetATR.bGetAtr.Enabled := True;
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
        PrintText := 'Get Firmware Version failed';
        displayOut( 1, 0, PrintText);
      end;

    end
    else
    begin
      PrintText := 'Connection to ' + PrintText + ' failed';
      displayOut( 1, 0, PrintText);
    end;

end;

procedure TMainGetATR.bQuitClick(Sender: TObject);
begin
  if ConnActive = true then
     begin
        retCode := ACR122_Close(hReader);
     end;
  Application.Terminate;
end;

procedure TMainGetATR.bResetClick(Sender: TObject);
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

procedure TMainGetATR.FormActivate(Sender: TObject);
begin
   InitMenu();
end;

procedure TMainGetATR.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ConnActive = true then
     begin
        retCode := ACR122_Close(hReader);
     end;
  Application.Terminate;
end;

end.
