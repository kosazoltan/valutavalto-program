object DBOOKCTRL: TDBOOKCTRL
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'DBOOKCTRL'
  ClientHeight = 22
  ClientWidth = 629
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 631
    Height = 21
    BevelOuter = bvNone
    Caption = 'DAYBOOK ADATB'#193'ZIS ELLEN'#336'RZ'#201'SE'
    Color = 13697023
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object STARTTIMER: TTimer
    Enabled = False
    Interval = 300
    Left = 8
    Top = 32
  end
  object DAYBOOKTABLA: TIBTable
    Database = DAYBOOKDBASE
    Transaction = DAYBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 32
  end
  object DAYBOOKQUERY: TIBQuery
    Database = DAYBOOKDBASE
    Transaction = DAYBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 32
  end
  object DAYBOOKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = DAYBOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 32
  end
  object DAYBOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBOOKDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 32
  end
  object RECEPTTABLA: TIBTable
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 224
    Top = 32
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 32
  end
  object RECEPTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 32
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 32
  end
  object EXPTABLA: TIBTable
    Database = EXPDBASE
    Transaction = EXPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 224
    Top = 72
  end
  object EXPQUERY: TIBQuery
    Database = EXPDBASE
    Transaction = EXPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 72
  end
  object EXPDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = EXPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 72
  end
  object EXPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = EXPDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 72
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = KILEPOTimer
    Left = 8
    Top = 64
  end
  object ENGTABLA: TIBTable
    Database = ENGDBASE
    Transaction = ENGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 72
  end
  object ENGQUERY: TIBQuery
    Database = ENGDBASE
    Transaction = ENGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 72
  end
  object ENGDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ENGEDELY.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ENGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 440
    Top = 72
  end
  object ENGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ENGDBASE
    AutoStopAction = saNone
    Left = 472
    Top = 72
  end
  object PTERMTABLA: TIBTable
    Database = PTERMDBASE
    Transaction = PTERMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 32
  end
  object PTERMQUERY: TIBQuery
    Database = PTERMDBASE
    Transaction = PTERMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 32
  end
  object PTERMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\POSTTERM.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTERMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 440
    Top = 32
  end
  object PTERMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PTERMDBASE
    AutoStopAction = saNone
    Left = 472
    Top = 32
  end
  object EXPBOOKTABLA: TIBTable
    Database = EXPBOOKDBASE
    Transaction = EXPBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 64
  end
  object EXPBOOKQUERY: TIBQuery
    Database = EXPBOOKDBASE
    Transaction = EXPBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 64
  end
  object EXPBOOKDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = EXPBOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 64
  end
  object EXPBOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = EXPBOOKDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 64
  end
end
