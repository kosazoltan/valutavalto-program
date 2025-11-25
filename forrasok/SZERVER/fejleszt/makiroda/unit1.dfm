object Form1: TForm1
  Left = 342
  Top = 249
  BorderStyle = bsSingle
  BorderWidth = 2
  Caption = 'Irodak.dat k'#233'sz'#237't'#233'se ....'
  ClientHeight = 239
  ClientWidth = 479
  Color = clYellow
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
    Left = 72
    Top = 72
    Width = 364
    Height = 36
    Caption = 'IRODAK.DAT K'#201'SZ'#205'T'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 56
    Top = 120
    Width = 391
    Height = 27
    Caption = '(Path: C:\RECEPTOR\MAIL\IRODAK)'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 24
    Top = 184
    Width = 433
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object STARTTIMER: TTimer
    Enabled = False
    Interval = 50
    OnTimer = STARTTIMERTimer
    Left = 112
    Top = 8
  end
  object ACQUERY: TIBQuery
    Database = ACDBASE
    Transaction = ACTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 8
  end
  object ACDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ACTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 304
    Top = 8
  end
  object ACTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ACDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 8
  end
end
