object fKeyManage: TfKeyManage
  Left = 0
  Top = 0
  Caption = 'Key Management'
  ClientHeight = 328
  ClientWidth = 596
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 11
    Width = 56
    Height = 13
    Caption = 'Select Port:'
  end
  object mMsg: TRichEdit
    Left = 184
    Top = 8
    Width = 401
    Height = 311
    TabOrder = 0
  end
  object bConnect: TButton
    Left = 40
    Top = 38
    Width = 138
    Height = 35
    Caption = '&Connect'
    TabOrder = 1
    OnClick = bConnectClick
  end
  object cbPort: TComboBox
    Left = 84
    Top = 11
    Width = 99
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 2
  end
  object bICCon: TButton
    Left = 40
    Top = 79
    Width = 138
    Height = 35
    Caption = '&Power On ICC'
    TabOrder = 3
    OnClick = bICConClick
  end
  object bInitSam: TButton
    Left = 40
    Top = 120
    Width = 138
    Height = 35
    Caption = '&Initialize SAM'
    TabOrder = 4
    OnClick = bInitSamClick
  end
  object bGenKeys: TButton
    Left = 40
    Top = 161
    Width = 138
    Height = 35
    Caption = '&Generate Keys'
    TabOrder = 5
    OnClick = bGenKeysClick
  end
  object bClear: TButton
    Left = 40
    Top = 202
    Width = 138
    Height = 35
    Caption = 'Cl&ear'
    TabOrder = 6
    OnClick = bClearClick
  end
  object bReset: TButton
    Left = 40
    Top = 243
    Width = 138
    Height = 35
    Caption = '&Reset'
    TabOrder = 7
    OnClick = bResetClick
  end
  object bQuit: TButton
    Left = 40
    Top = 284
    Width = 138
    Height = 35
    Caption = '&Quit'
    TabOrder = 8
    OnClick = bQuitClick
  end
end
