object Form1: TForm1
  Left = 367
  Top = 148
  Width = 510
  Height = 653
  Caption = 'Hi'#225'nyz'#243' ID-k'#243'dok p'#243'tl'#225'sa. ...'
  Color = 5592405
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 40
    Width = 460
    Height = 36
    Caption = 'HI'#193'NYZ'#211' ID-K'#211'DOK P'#211'TL'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Button1: TButton
    Left = 128
    Top = 144
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 248
    Top = 144
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = Button2Click
  end
  object HOCOMBO: TComboBox
    Left = 232
    Top = 96
    Width = 121
    Height = 28
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 2
    Text = 'Szeptember'
  end
  object EVCOMBO: TComboBox
    Left = 160
    Top = 96
    Width = 73
    Height = 28
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 3
    Text = '2013'
  end
  object fdbpanel: TPanel
    Left = 8
    Top = 184
    Width = 489
    Height = 33
    BevelOuter = bvNone
    Color = 5592405
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object bizonylatpanel: TPanel
    Left = 8
    Top = 232
    Width = 489
    Height = 25
    BevelOuter = bvNone
    Color = 5592405
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object Memo1: TMemo
    Left = 112
    Top = 304
    Width = 297
    Height = 257
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 6
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 16
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 16
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 416
    Top = 16
  end
  object PROSQUERY: TIBQuery
    Database = PROSDBASE
    Transaction = PROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 24
  end
  object PROSDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 24
  end
  object PROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PROSDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 24
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 320
    Top = 16
  end
end
