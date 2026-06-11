object IDOSZAKKEROFORM: TIDOSZAKKEROFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'IDOSZAKKEROFORM'
  ClientHeight = 172
  ClientWidth = 539
  Color = 16311512
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
    Width = 537
    Height = 169
    Brush.Color = clRed
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 432
    Top = 48
    Width = 16
    Height = 55
    Caption = '-'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -48
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 136
    Top = 8
    Width = 294
    Height = 33
    Caption = 'A VIZSG'#193'LT ID'#336'SZAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 32
    Top = 56
    Width = 105
    Height = 45
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ItemHeight = 37
    ParentFont = False
    TabOrder = 0
    Text = '2011'
    OnChange = evcomboChange
  end
  object HOCOMBO: TComboBox
    Left = 136
    Top = 56
    Width = 217
    Height = 45
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ItemHeight = 37
    ParentFont = False
    TabOrder = 1
    Text = 'szeptember'
    OnChange = evcomboChange
  end
  object TOLNAPCOMBO: TComboBox
    Left = 352
    Top = 56
    Width = 65
    Height = 45
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ItemHeight = 37
    ParentFont = False
    TabOrder = 2
    Text = '30'
    OnChange = TOLNAPCOMBOChange
  end
  object IGNAPCOMBO: TComboBox
    Left = 464
    Top = 56
    Width = 65
    Height = 45
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ItemHeight = 37
    ParentFont = False
    TabOrder = 3
    Text = '31'
    OnChange = IGNAPCOMBOChange
  end
  object IDOSZAKOKEGOMB: TBitBtn
    Left = 56
    Top = 120
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'ID'#336'SZAK RENDBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = IDOSZAKOKEGOMBClick
  end
  object KILEPESGOMB: TBitBtn
    Left = 280
    Top = 120
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = KILEPESGOMBClick
  end
end
