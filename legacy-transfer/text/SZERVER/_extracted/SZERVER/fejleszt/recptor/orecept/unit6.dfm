object BIGSUM: TBIGSUM
  Left = 25
  Top = 97
  AlphaBlend = True
  AlphaBlendValue = 190
  BorderStyle = bsNone
  Caption = 'BIGSUM'
  ClientHeight = 72
  ClientWidth = 1267
  Color = 16756991
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
    Left = 408
    Top = 0
    Width = 530
    Height = 36
    Caption = 'NAGY TRANZAKCI'#211'K LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object csik: TProgressBar
    Left = 16
    Top = 40
    Width = 1233
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object INDITOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = InditoTimerTimer
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KilepoTimerTimer
    Left = 32
  end
  object STORNOFEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'password=masterkey'
      'lc_ctype=WIN1250'
      'user_name=SYSDBA')
    LoginPrompt = False
    DefaultTransaction = STORNOFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
  end
  object STORNOFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = STORNOFEJDBASE
    AutoStopAction = saNone
    Left = 128
  end
  object STORNOFEJQUERY: TIBQuery
    Database = STORNOFEJDBASE
    Transaction = STORNOFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
  end
  object stornoteteldbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STORNOTETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 192
  end
  object STORNOTETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = stornoteteldbase
    AutoStopAction = saNone
    Left = 216
  end
  object stornotetelquery: TIBQuery
    Database = stornoteteldbase
    Transaction = STORNOTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 368
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 336
  end
  object blokktabla: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 304
  end
  object blokkquery: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
  end
  object ARFEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = arfetranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 1096
  end
  object arfetranz: TIBTransaction
    Active = False
    DefaultDatabase = ARFEDBASE
    AutoStopAction = saNone
    Left = 1128
  end
  object ARFEQUERY: TIBQuery
    Database = ARFEDBASE
    Transaction = arfetranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 1064
  end
  object BIGSUMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIGSUMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 1200
  end
  object BIGSUMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIGSUMDBASE
    AutoStopAction = saNone
    Left = 1232
  end
  object BIGSUMQUERY: TIBQuery
    Database = BIGSUMDBASE
    Transaction = BIGSUMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 1168
  end
end
