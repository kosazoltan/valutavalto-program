object STORNOBIZONYLATOK: TSTORNOBIZONYLATOK
  Left = -19
  Top = 121
  AlphaBlend = True
  AlphaBlendValue = 185
  BorderStyle = bsNone
  Caption = 'STORNOBIZONYLATOK'
  ClientHeight = 72
  ClientWidth = 1267
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
  object Label1: TLabel
    Left = 392
    Top = 0
    Width = 563
    Height = 36
    Caption = 'STORN'#211'BIZONYLATOK LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 32
    Top = 40
    Width = 1217
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object INDITOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = INDITOTIMERTimer
    Left = 8
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTIMERTimer
    Left = 40
  end
  object STORNOFEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STORNOFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
  end
  object STORNOFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = STORNOFEJDBASE
    AutoStopAction = saNone
    Left = 144
  end
  object STORNOFEJQUERY: TIBQuery
    Database = STORNOFEJDBASE
    Transaction = STORNOFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
  end
  object STORNOTETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = STORNOTETELDBASE
    AutoStopAction = saNone
    Left = 256
  end
  object STORNOTETELDBASE: TIBDatabase
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
    Left = 224
  end
  object STORNOTETELQUERY: TIBQuery
    Database = STORNOTETELDBASE
    Transaction = STORNOTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOkKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 360
  end
  object BLOkKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 392
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOkKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 328
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOkKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 296
  end
  object DAYBOOKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = daybooktranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 1088
  end
  object daybooktranz: TIBTransaction
    Active = False
    DefaultDatabase = DAYBOOKDBASE
    AutoStopAction = saNone
    Left = 1112
  end
  object DAYBOOKQUERY: TIBQuery
    Database = DAYBOOKDBASE
    Transaction = daybooktranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 1064
  end
  object IRODADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IRODATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 1192
  end
  object IRODATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IRODADBASE
    AutoStopAction = saNone
    Left = 1216
  end
  object IRODAQUERY: TIBQuery
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 1168
  end
end
