object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
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
  object Button1: TButton
    Left = 40
    Top = 32
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Panel1: TPanel
    Left = 248
    Top = 120
    Width = 185
    Height = 41
    Caption = 'Panel1'
    TabOrder = 1
  end
  object Panel2: TPanel
    Left = 248
    Top = 176
    Width = 185
    Height = 41
    Caption = 'Panel2'
    TabOrder = 2
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 16
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 184
    Top = 16
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 16
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 312
    Top = 16
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 344
    Top = 16
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 376
    Top = 16
  end
  object RATETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RATEDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 16
  end
  object RATEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\SUMRATE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RATETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 16
  end
  object RATEQUERY: TIBQuery
    Database = RATEDBASE
    Transaction = RATETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 16
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 280
    Top = 16
  end
  object PERMQUERY: TIBQuery
    Database = PERMDBASE
    Transaction = PERMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 640
    Top = 16
  end
  object PERMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\rateperm.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PERMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 672
    Top = 16
  end
  object PERMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PERMDBASE
    AutoStopAction = saNone
    Left = 704
    Top = 16
  end
  object PERMTABLA: TIBTable
    Database = PERMDBASE
    Transaction = PERMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 608
    Top = 16
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTimer
    Left = 792
    Top = 16
  end
end
