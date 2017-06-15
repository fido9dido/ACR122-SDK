unit Polling;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  ACR122s, Dialogs, StdCtrls, ExtCtrls;

type
  TCardPolling = class(TForm)
    bConnect: TButton;
    bQuit: TButton;
    bStart: TButton;
    cbReader: TComboBox;
    Label1: TLabel;
    lCard: TLabel;
    lCardType: TLabel;
    tTimer: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure bQuitClick(Sender: TObject);
    procedure bConnectClick(Sender: TObject);
    procedure bStartClick(Sender: TObject);
    procedure tTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CardPolling: TCardPolling;
  hReader: SCARDHANDLE;
  retCode: DWORD;
  PrintText: String;
  ConnActive: BOOL;
  RecvLen : DWORD;
  SendBuff : array [0..256] of Byte;
  RecvBuff : array [0..256] of Byte;
  enablePoll: BOOL;

procedure PollCard();
procedure InitMenu();
implementation

{$R *.dfm}

procedure InitMenu();
var
indx : Integer;
begin

  connActive := False;

  CardPolling.bConnect.Enabled := True;
  CardPolling.bStart.Enabled := True;

  CardPolling.cbReader.Clear;

  for indx := 1 to 10 do
  begin
    PrintText := 'COM' + IntToStr(indx);
    CardPolling.cbReader.AddItem( PrintText, TObject.NewInstance);
  end;

  enablePoll := False;
  CardPolling.cbReader.ItemIndex := 0;
  CardPolling.lCard.Caption := 'Card Type:';


end;

procedure TCardPolling.bConnectClick(Sender: TObject);
begin
    PrintText := CardPolling.cbReader.Text;

    retCode := ACR122_OpenA( PrintText, @hReader);
    if retCode = 0  then
    begin
      ConnActive := TRUE;
      CardPolling.bConnect.Enabled := False;
      CardPolling.bStart.Enabled := True;

      ShowMessage('Connection Success');

    end
    else
    begin
      ShowMessage('Connection Failed');
    end;


end;

procedure TCardPolling.bQuitClick(Sender: TObject);
begin
     if ConnActive = true then
     begin
        retCode := ACR122_Close(hReader);
     end;
    Application.Terminate;
end;

procedure TCardPolling.bStartClick(Sender: TObject);
begin

    if enablePoll = True then
    begin
       enablePoll := False;
       tTimer.Enabled := False;
       bStart.Caption := 'Start Polling';

    end
    else
    begin
       enablePoll := True;
       tTimer.Enabled := True;
       bStart.Caption := 'Stop Polling';
       lCardType.Caption := '';
    end;

end;

procedure PollCard();
var
indx: integer;
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

           CardPolling.lCardType.Caption := PrintText;
       end
       else
          CardPolling.lCardType.Caption := '';
    end;



end;

procedure TCardPolling.FormActivate(Sender: TObject);
begin
    InitMenu();
end;

procedure TCardPolling.tTimerTimer(Sender: TObject);
begin
    PollCard();
end;

end.
