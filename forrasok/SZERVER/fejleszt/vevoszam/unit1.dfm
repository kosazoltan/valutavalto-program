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
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 256
    Top = 144
    Width = 377
    Height = 41
    Caption = 'Panel1'
    TabOrder = 0
  end
  object Button1: TButton
    Left = 200
    Top = 24
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 200
    Top = 56
    Width = 75
    Height = 25
    Caption = 'KILEP'
    TabOrder = 2
    OnClick = Button2Click
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 16
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
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
    Left = 88
    Top = 16
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 16
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 104
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
    Left = 56
    Top = 104
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 112
  end
  object UGYFQUERY: TIBQuery
    Database = UGYFDBASE
    Transaction = ugyftranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 56
  end
  object UGYFDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ugyftranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 56
  end
  object ugyftranz: TIBTransaction
    Active = False
    DefaultDatabase = UGYFDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 56
  end
end
