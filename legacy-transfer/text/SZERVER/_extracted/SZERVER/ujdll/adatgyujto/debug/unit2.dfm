object ADATLEGYUJTES: TADATLEGYUJTES
  Left = 229
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 192
  BorderStyle = bsNone
  Caption = 'ADATLEGYUJTES'
  ClientHeight = 193
  ClientWidth = 504
  Color = clWhite
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
    Brush.Color = clSkyBlue
    Pen.Width = 3
  end
  object Label1: TLabel
    Left = 64
    Top = 8
    Width = 363
    Height = 34
    Caption = 'AZ ADATOK LEGY'#220'JT'#201'SE'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -29
    Font.Name = 'Lemon'
    Font.Style = [fsBold, fsItalic]
    ParentColor = False
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
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -24
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
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
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
    Left = 48
    Top = 16
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 16
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 408
    Top = 160
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
    Left = 376
    Top = 160
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 344
    Top = 160
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 440
    Top = 160
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 120
    Top = 16
  end
  object NarfQuery: TIBQuery
    Database = NARFDBASE
    Transaction = NARFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 88
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
    Left = 40
    Top = 88
  end
  object NARFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NARFDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 88
  end
  object RECEPTORTABLA: TIBTable
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 152
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 152
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 152
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 144
    Top = 152
  end
  object ELSZAMQUERY: TIBQuery
    Database = ELSZAMDBASE
    Transaction = ELSZAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 80
  end
  object ELSZAMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ELSZAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 80
  end
  object ELSZAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ELSZAMDBASE
    AutoStopAction = saNone
    Left = 328
    Top = 80
  end
end
