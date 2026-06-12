object GETIDOSZAK: TGETIDOSZAK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETIDOSZAK'
  ClientHeight = 206
  ClientWidth = 752
  Color = 4473924
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape3: TShape
    Left = 88
    Top = 24
    Width = 577
    Height = 169
    Brush.Color = 11599871
    Shape = stRoundRect
  end
  object Shape1: TShape
    Left = 104
    Top = 72
    Width = 537
    Height = 49
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 464
    Top = 84
    Width = 56
    Height = 29
    Caption = '-TOL'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 600
    Top = 84
    Width = 32
    Height = 29
    Caption = '-IG'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 160
    Top = 32
    Width = 440
    Height = 24
    Caption = 'AZ E-KERESKEDELEM ID'#336'SZAKI GY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 224
    Top = 136
    Width = 305
    Height = 41
    Shape = stRoundRect
  end
  object EVCOMBO: TComboBox
    Left = 112
    Top = 80
    Width = 89
    Height = 37
    BevelInner = bvNone
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 0
    Text = '2011'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 200
    Top = 80
    Width = 201
    Height = 37
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 1
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object TOLCOMBO: TComboBox
    Left = 400
    Top = 80
    Width = 65
    Height = 37
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 2
    Text = '22'
    OnChange = TOLCOMBOChange
  end
  object IGCOMBO: TComboBox
    Left = 536
    Top = 80
    Width = 57
    Height = 37
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 29
    ParentFont = False
    TabOrder = 3
    Text = '30'
    OnChange = IGCOMBOChange
  end
  object RENDBENGOMB: TBitBtn
    Left = 232
    Top = 144
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'RENDBEN'
    Default = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = RENDBENGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 384
    Top = 144
    Width = 137
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'M'#201'GSEM'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = MEGSEMGOMBClick
  end
  object FUGGONY: TPanel
    Left = 440
    Top = -8
    Width = 760
    Height = 209
    BevelOuter = bvNone
    Color = 4473924
    TabOrder = 6
  end
end
