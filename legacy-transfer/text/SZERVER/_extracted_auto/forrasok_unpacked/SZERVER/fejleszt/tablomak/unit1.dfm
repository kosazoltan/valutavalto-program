object Form1: TForm1
  Left = 473
  Top = 366
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 199
  ClientWidth = 501
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 501
    Height = 199
    Align = alClient
    Brush.Color = clMoneyGreen
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 8
    Width = 439
    Height = 41
    Caption = 'TABL'#211'K'#201'SZ'#205'T'#336' PROGRAM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 40
    Top = 64
    Width = 231
    Height = 22
    Caption = 'AZ UTOLS'#211' MUNKANAP:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object startgomb: TButton
    Left = 24
    Top = 104
    Width = 449
    Height = 25
    Cursor = crHandPoint
    Caption = 'TABL'#211'K'#201'SZ'#205'T'#201'S INDUL'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = startgombClick
  end
  object QUITGOMB: TButton
    Left = 24
    Top = 136
    Width = 449
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = QUITGOMBClick
  end
  object DATUMEDIT: TEdit
    Left = 280
    Top = 56
    Width = 137
    Height = 37
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    MaxLength = 10
    ParentFont = False
    TabOrder = 2
    Text = '2015.01.14'
  end
end
