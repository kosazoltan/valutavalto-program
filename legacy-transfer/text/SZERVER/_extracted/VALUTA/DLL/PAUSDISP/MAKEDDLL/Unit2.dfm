object SZUNETKIJELZO: TSZUNETKIJELZO
  Left = 192
  Top = 114
  Width = 540
  Height = 270
  Caption = 'SZUNETKIJELZO'
  Color = clBtnFace
  Font.Charset = EASTEUROPE_CHARSET
  Font.Color = clWindowText
  Font.Height = -19
  Font.Name = 'Times New Roman'
  Font.Style = [fsItalic]
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 21
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 529
    Height = 233
    Brush.Color = 4539717
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 88
    Top = 24
    Width = 336
    Height = 31
    Caption = 'P'#233'nzt'#225'r bez'#225'r'#225's'#225'nal kijelz'#233'se'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object TIPUSCOMBO: TComboBox
    Left = 176
    Top = 72
    Width = 169
    Height = 31
    Cursor = crArrow
    BevelInner = bvNone
    BevelOuter = bvNone
    Color = 11579568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 0
    Text = 'Technikai sz'#252'net'
    OnChange = TOLORACOMBOChange
  end
  object TOLORACOMBO: TComboBox
    Left = 48
    Top = 120
    Width = 85
    Height = 31
    Cursor = crArrow
    Color = 11579568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 1
    Text = '13 '#243'ra'
    OnChange = TOLORACOMBOChange
  end
  object TOLPERCCOMBO: TComboBox
    Left = 136
    Top = 120
    Width = 115
    Height = 31
    Cursor = crArrow
    Color = 11579568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 2
    Text = '30 perct'#337'l'
    OnChange = TOLORACOMBOChange
  end
  object IGORACOMBO: TComboBox
    Left = 272
    Top = 120
    Width = 85
    Height = 31
    Cursor = crArrow
    Color = 11579568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 3
    Text = '14 '#243'ra'
    OnChange = TOLORACOMBOChange
  end
  object IGPERCCOMBO: TComboBox
    Left = 360
    Top = 120
    Width = 115
    Height = 31
    Cursor = crArrow
    Color = 11579568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 4
    Text = '00 percig'
    OnChange = TOLORACOMBOChange
  end
  object SZUNETGOMB: TBitBtn
    Left = 72
    Top = 176
    Width = 187
    Height = 25
    Cursor = crHandPoint
    Caption = 'Sz'#252'netkijelz'#233's indul'
    TabOrder = 5
    OnClick = SZUNETGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 264
    Top = 176
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#233'gsem'
    TabOrder = 6
    OnClick = MEGSEMGOMBClick
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 72
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 72
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 72
  end
end
