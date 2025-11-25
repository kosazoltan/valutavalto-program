object ADATLEGYUJTES: TADATLEGYUJTES
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'ADATLEGYUJTES'
  ClientHeight = 193
  ClientWidth = 504
  Color = 8421631
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
    Width = 505
    Height = 193
    Brush.Color = 221
    Pen.Width = 3
  end
  object Label1: TLabel
    Left = 24
    Top = 8
    Width = 451
    Height = 43
    Caption = 'AZ ADATOK LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object CSIK: TProgressBar
    Left = 8
    Top = 144
    Width = 481
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object UZENOPANEL: TPanel
    Left = 8
    Top = 48
    Width = 481
    Height = 33
    BevelOuter = bvNone
    Color = 221
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object ALCIMPANEL: TPanel
    Left = 8
    Top = 88
    Width = 481
    Height = 25
    BevelOuter = bvNone
    Color = 221
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object NAGYCSIK: TProgressBar
    Left = 8
    Top = 120
    Width = 481
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = INDITOTimer
    Left = 8
    Top = 80
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 56
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 56
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 400
    Top = 56
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 368
    Top = 56
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 56
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 432
    Top = 56
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 144
    Top = 56
  end
  object ELSZAMQUERY: TIBQuery
    Database = NARFDBASE
    Transaction = NARFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 56
  end
  object NARFDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NARFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 56
  end
  object NARFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NARFDBASE
    AutoStopAction = saNone
    Left = 280
    Top = 56
  end
  object RECEPTORTABLA: TIBTable
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 56
  end
end
