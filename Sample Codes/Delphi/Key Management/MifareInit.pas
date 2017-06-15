unit MifareInit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfMifareInit = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    tbSerial: TEdit;
    tbIC: TEdit;
    tbKc: TEdit;
    tbKt: TEdit;
    tbKd: TEdit;
    tbKcr: TEdit;
    tbKcf: TEdit;
    tbKrd: TEdit;
    bGenKeys: TButton;
    GroupBox2: TGroupBox;
    Label9: TLabel;
    rbA: TRadioButton;
    rbB: TRadioButton;
    cb1: TCheckBox;
    tb1: TEdit;
    cb2: TCheckBox;
    tb2: TEdit;
    cb3: TCheckBox;
    tb3: TEdit;
    cb4: TCheckBox;
    tb4: TEdit;
    cb5: TCheckBox;
    tb5: TEdit;
    cb6: TCheckBox;
    tb6: TEdit;
    bSaveKeys: TButton;
    bCancel: TButton;
    procedure bGenKeysClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure bCancelClick(Sender: TObject);
    procedure tMemAddKeyPress(Sender: TObject; var Key: Char);
    procedure bSaveKeysClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fMifareInit: TfMifareInit;
  UID : array [0 .. 4] of Byte;

function GenerateSAMKey( KeyId : Byte ) : String;
procedure SaveKey(BlockNo : Byte; keytype : Integer);
implementation

uses KeyManage;
{$R *.dfm}

procedure TfMifareInit.bCancelClick(Sender: TObject);
begin
    fMifareInit.Close;
end;

procedure TfMifareInit.bGenKeysClick(Sender: TObject);
var
serial : String;
indx : Integer;
key : String;
begin
     ClearBuffers();
     SendBuff[0] := $D4;
     SendBuff[1] := $4A;
     SendBuff[2] := $01;
     SendBuff[3] := $00;

     SendLen := 4;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(0);

      if retCode = 0 then begin
           for indx := 8 to RecvBuff[7] + 7 do
             begin
               UID[indx - 8] := RecvBuff[indx];
             end;

           for indx := 0 to 3 do
             begin
               serial := serial + Format('%.02X ', [UID[indx]]);
             end;
      end
      else begin
           displayOut( 1, 0, 'Failed to get card serial number');
           fMifareInit.Close;
      end;

     tbSerial.Text := serial;

     //Select Issuer DF
     ClearBuffers();
     SendBuff[0] := $00;
     SendBuff[1] := $A4;
     SendBuff[2] := $00;
     SendBuff[3] := $00;
     SendBuff[4] := $02;
     SendBuff[5] := $11;
     SendBuff[6] := $00;

     SendLen := 7;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(1);
     if Not retCode = 0 then begin
           displayOut( 1, 0, 'Failed to select issuer DF');
           fMifareInit.Close;
     end;

     //Submit Issuer PIN
     ClearBuffers();
     SendBuff[0] := $00;
     SendBuff[1] := $20;
     SendBuff[2] := $00;
     SendBuff[3] := $01;
     SendBuff[4] := $08;

     for indx := 0 to 7 do
       begin
         SendBuff[indx + 5] := Buffer[indx];
       end;

     SendLen := 13;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(1);
     if Not retCode = 0 then begin
           displayOut( 1, 0, 'Failed to submit issuer PIN');
           fMifareInit.Close;
     end;

     //Generate Key
     //Generate IC using 1st SAM Master Key (KeyID=81)
     key := GenerateSAMKey( $81 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain IC Key');
        fMifareInit.Close;
     end
     else begin
        tbIC.Text := key;
     end;

     //Generate Card Key Using 2nd SAM Master Key (KeyID=82)
     key := GenerateSAMKey( $82 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Card Key');
        fMifareInit.Close;
     end
     else begin
        tbKc.Text := key;
     end;

     //Generate Terminal Key Using 3rd SAM Master Key (KeyID=83)
     key := GenerateSAMKey( $83 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Terminal Key');
        fMifareInit.Close;
     end
     else begin
        tbKt.Text := key;
     end;

     //Generate Debit Key Using 2nd SAM Master Key (KeyID=84)
     key := GenerateSAMKey( $84 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Debit Key');
        fMifareInit.Close;
     end
     else begin
        tbKd.Text := key;
     end;

     //Generate Credit Key Using 2nd SAM Master Key (KeyID=85)
     key := GenerateSAMKey( $85 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Credit Key');
        fMifareInit.Close;
     end
     else begin
        tbKcr.Text := key;
     end;

     //Generate Certify Key Using 2nd SAM Master Key (KeyID=86)
     key := GenerateSAMKey( $86 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Certify Key');
        fMifareInit.Close;
     end
     else begin
        tbKcf.Text := key;
     end;

     //Generate Revoke Debit Key Using 2nd SAM Master Key (KeyID=87)
     key := GenerateSAMKey( $87 );
     if CompareStr(key, '') < 0  then begin
        displayOut( 1, 0, 'Failed to obtain Revoke Debit Key');
        fMifareInit.Close;
     end
     else begin
        tbKrd.Text := key;
     end;




end;

procedure TfMifareInit.bSaveKeysClick(Sender: TObject);
var
Block : Byte;
begin

    retCode := MessageBox(0, 'Saving keys to Mifare assumes that the keys stored is "FF FF FF FF FF FF". Continue?', 'Warning', +mb_YesNo +mb_ICONWARNING);
     if retCode = 7 then
        Exit;

    if cb1.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Card Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb1.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb1.SetFocus;
         Exit;
      end;
    end;

    if cb2.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Terminal Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb2.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb2.SetFocus;
         Exit;
      end;
    end;

    if cb3.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Debit Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb3.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb3.SetFocus;
         Exit;
      end;
    end;

    if cb4.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Credit Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb4.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb4.SetFocus;
         Exit;
      end;
    end;

    if cb5.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Certify Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb5.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb5.SetFocus;
         Exit;
      end;
    end;

    if cb6.Checked = True then
    begin
      if tbKc.Text = '' then  begin
         MessageBox(0, 'No Revoke Debit Key generated', 'warning' ,MB_OK);
         Exit;
      end;

      if tb6.Text = '' then begin
         MessageBox(0, 'Enter Vaild value for block number', 'warning' ,MB_OK);
         tb6.SetFocus;
         Exit;
      end;
    end;

    if cb1.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb1.Text), 1);
    end;

    if cb2.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb2.Text), 2);
    end;

    if cb3.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb3.Text), 3);
    end;

    if cb4.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb4.Text), 4);
    end;

    if cb5.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb5.Text), 5);
    end;

    if cb6.Checked = True then
    begin
       SaveKey(StrToInt( '$' + tb6.Text), 6);
    end;

end;

procedure SaveKey(BlockNo : Byte; keytype: Integer);
var
indx : Integer;
temp : array [ 0 .. 255] of Byte;
keyin : array [ 0 .. 255] of Byte;
begin

     BlockNo := ( BlockNo * 4 ) + 4;

     ClearBuffers();
     SendBuff[0] := $D4;
     SendBuff[1] := $40;
     SendBuff[2] := $01;
     SendBuff[3] := $60;
     SendBuff[4] := BlockNo;
     SendBuff[5] := $FF;
     SendBuff[6] := $FF;
     SendBuff[7] := $FF;
     SendBuff[8] := $FF;
     SendBuff[9] := $FF;
     SendBuff[10] := $FF;
     SendBuff[11] := UID[0];
     SendBuff[12] := UID[1];
     SendBuff[13] := UID[2];
     SendBuff[14] := UID[3];

     SendLen := 15;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(0);
     if Not retCode = 0 then begin
           displayOut( 1, 0, 'Error in saving Key');
           fMifareInit.Close;
           Exit;
     end
     else begin
       if Not RecvBuff[2]= $00 then begin
           displayOut( 1, 0, 'Error in saving Key');
           fMifareInit.Close;
           Exit;
       end;
     end;

     ClearBuffers();
     SendBuff[0] := $D4;
     SendBuff[1] := $40;
     SendBuff[2] := $01;
     SendBuff[3] := $30;
     SendBuff[4] := BlockNo;

     SendLen := 5;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(0);
     if Not retCode = 0 then begin
           displayOut( 1, 0, 'Error in saving Key');
           fMifareInit.Close;
           Exit;
     end
     else begin
       if RecvLen < 4 then begin
           displayOut( 1, 0, 'Error in saving Key');
           fMifareInit.Close;
           Exit;
       end;

       for indx := 3 to RecvLen - 1 do
       begin
           temp[indx - 3] := RecvBuff[indx]
       end;

     end;

     Case keytype of
     1:  PrintText := fMifareInit.tbKc.Text;
     2:  PrintText := fMifareInit.tbKt.Text;
     3:  PrintText := fMifareInit.tbKd.Text;
     4:  PrintText := fMifareInit.tbKcr.Text;
     5:  PrintText := fMifareInit.tbKcf.Text;
     6:  PrintText := fMifareInit.tbKrd.Text;
     End;

     for indx :=0 to Length(PrintText) div 2 - 1 do
     begin
         keyin[indx] := StrToInt('$' + copy(PrintText,(indx*2+1),2)); // Format Data In
     end;

     if fMifareInit.rbA.Checked = True then begin

        for indx := 0 to 15 do
          begin
            if indx < 6 then begin
               SendBuff[indx + 5] := keyin[indx];
            end
            else begin
               SendBuff[indx + 5] := temp[indx];
            end;
          end;

     end
     else begin

         for indx := 0 to 15 do
          begin
            if indx < 10 then begin
               SendBuff[indx + 5] := temp[indx];
            end
            else begin
               SendBuff[indx + 5] := keyin[indx - 10];
            end;
          end;

     end;

     SendBuff[0] := $D4;
     SendBuff[1] := $40;
     SendBuff[2] := $01;
     SendBuff[3] := $A0;
     SendBuff[4] := BlockNo;

     SendLen := 21;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(0);
     if Not retCode = 0 then begin
           displayOut( 1, 0, 'Error in saving Key');
           fMifareInit.Close;
           Exit;
     end;

end;

function GenerateSAMKey( KeyId : Byte ) : String;
var
indx : Integer;
buff : String;
begin

     ClearBuffers();
     SendBuff[0] := $80;
     SendBuff[1] := $88;
     SendBuff[2] := $00;
     SendBuff[3] := KeyId;
     SendBuff[4] := $08;

     for indx := 0 to 3 do
     begin
       SendBuff[indx + 5] := UID[indx];
     end;

     SendLen := 13;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(1);

      if Not retCode = 0 then begin
           displayOut( 1, 0, 'Error in generating Key');
           fMifareInit.Close;
           Exit;
      end;

     ClearBuffers();
     SendBuff[0] := $00;
     SendBuff[1] := $C0;
     SendBuff[2] := $00;
     SendBuff[3] := $00;
     SendBuff[4] := $08;

     SendLen := 5;
     RecvLen := 255;

     retCode := SendAPDUandDisplay(1);

     if retCode = 0 then begin
           if (RecvBuff[RecvLen - 2] = $90) And (RecvBuff[RecvLen - 1] = $00) then
           begin
              for indx := 0 to 5 do
                begin
                  buff := buff + Format('%.02X', [RecvBuff[indx]]);
                end;
           end;
           
     end
     else begin
           displayOut( 1, 0, 'Error in generating Key');
           fMifareInit.Close;
           Exit;
     end;

    GenerateSAMKey := buff;

end;

procedure TfMifareInit.FormShow(Sender: TObject);
begin
    tbSerial.Text := '';
    tbIC.Text := '';
    tbKc.Text := '';
    tbKt.Text := '';
    tbKd.Text := '';
    tbKcr.Text := '';
    tbKcf.Text := '';
    tbKrd.Text := '';

    tb1.Text := '';
    tb2.Text := '';
    tb3.Text := '';
    tb4.Text := '';
    tb5.Text := '';
    tb6.Text := '';

    cb1.Checked := False;
    cb2.Checked := False;
    cb3.Checked := False;
    cb4.Checked := False;
    cb5.Checked := False;
    cb6.Checked := False;

    rbA.Checked := True;
    rbB.Checked := False;

end;

procedure TfMifareInit.tMemAddKeyPress(Sender: TObject; var Key: Char);
begin
  if Key <> chr($08) then begin
    if Key in ['a'..'z'] then
      Dec(Key, 32);
    if Not (Key in ['0'..'9', 'A'..'F'])then
      Key := Chr($00);
  end;


end;

end.
