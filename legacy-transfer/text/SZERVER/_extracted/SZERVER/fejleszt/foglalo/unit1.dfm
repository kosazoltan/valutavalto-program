object Form1: TForm1
  Left = 431
  Top = 322
  Width = 464
  Height = 261
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
    Left = 40
    Top = 32
    Width = 382
    Height = 33
    Caption = 'A FOGLAL'#211'K  KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object csik: TProgressBar
    Left = 16
    Top = 80
    Width = 425
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object KILEPOGOMB: TBitBtn
    Left = 120
    Top = 168
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object STARTGOMB: TBitBtn
    Left = 120
    Top = 136
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'EXCEL T'#193'BLA K'#201'SZ'#205'T'#201'SE'
    Enabled = False
    TabOrder = 2
    OnClick = STARTGOMBClick
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 272
    Top = 8
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 304
    Top = 8
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 240
    Top = 8
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTIMERTimer
    Left = 8
    Top = 112
  end
end
