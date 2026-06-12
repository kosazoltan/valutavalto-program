object Form1: TForm1
  Left = 484
  Top = 303
  Width = 379
  Height = 343
  Caption = 'Havi jelenl'#233'ti '#237'vek ....'
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
    Width = 371
    Height = 309
    Align = alClient
    Brush.Color = 3552822
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 24
    Width = 319
    Height = 32
    Caption = 'HAVI JELENL'#201'TI '#205'VEK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 80
    Top = 96
    Width = 81
    Height = 37
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 0
    Text = '2013'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 160
    Top = 96
    Width = 161
    Height = 37
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 1
    Text = 'szeptember'
    OnChange = EVCOMBOChange
  end
  object CSIK: TProgressBar
    Left = 24
    Top = 200
    Width = 329
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 2
  end
  object STARTGOMB: TPanel
    Left = 24
    Top = 160
    Width = 329
    Height = 33
    Cursor = crHandPoint
    Caption = 'EXCEL T'#193'BLA K'#201'SZ'#205'T'#201'SE'
    Color = 8947848
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = STARTGOMBClick
  end
  object QUITGOMB: TPanel
    Left = 24
    Top = 224
    Width = 329
    Height = 33
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Color = 8947848
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = QUITGOMBClick
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTIMERTimer
    Left = 16
    Top = 56
  end
end
