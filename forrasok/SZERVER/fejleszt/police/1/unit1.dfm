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
    Left = 48
    Top = 112
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 48
    Top = 144
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 264
    Top = 200
    Width = 185
    Height = 41
    Caption = 'Panel1'
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 264
    Top = 264
    Width = 185
    Height = 41
    Caption = 'Panel2'
    TabOrder = 3
  end
  object POLQUERY: TIBQuery
    Database = POLDBASE
    Transaction = POLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 24
  end
  object POLDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\POLICE.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = POLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 24
  end
  object POLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = POLDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 24
  end
  object UFQUERY: TIBQuery
    Database = UFDBASE
    Transaction = UFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 312
    Top = 24
  end
  object UFDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 344
    Top = 24
  end
  object UFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UFDBASE
    AutoStopAction = saNone
    Left = 376
    Top = 24
  end
  object BTETQuery: TIBQuery
    Database = BTETDBASE
    Transaction = BTETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 56
  end
  object BTETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BTETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 56
  end
  object BTETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BTETDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 56
  end
  object BtetTABLA: TIBTable
    Database = BTETDBASE
    Transaction = BTETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 440
    Top = 56
  end
  object BFEJQUERY: TIBQuery
    Database = BFEJDBASE
    Transaction = BFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 24
  end
  object BFEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 24
  end
  object BFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFEJDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 24
  end
  object IRODAQUERY: TIBQuery
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 656
    Top = 32
  end
  object IRODADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IRODATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 688
    Top = 32
  end
  object IRODATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IRODADBASE
    AutoStopAction = saNone
    Left = 720
    Top = 32
  end
end
