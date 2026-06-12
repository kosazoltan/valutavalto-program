object Form1: TForm1
  Left = 192
  Top = 125
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
  object STARTGOMB: TBitBtn
    Left = 56
    Top = 48
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 56
    Top = 88
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'KILEP'
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object Memo1: TMemo
    Left = 128
    Top = 360
    Width = 553
    Height = 161
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    TabOrder = 2
  end
  object FDBPANEL: TPanel
    Left = 144
    Top = 64
    Width = 537
    Height = 41
    TabOrder = 3
  end
  object HONAPPANEL: TPanel
    Left = 144
    Top = 112
    Width = 537
    Height = 41
    Caption = 'HONAPPANEL'
    TabOrder = 4
  end
  object UGYFELPANEL: TPanel
    Left = 144
    Top = 160
    Width = 537
    Height = 41
    Caption = 'UGYFELPANEL'
    TabOrder = 5
  end
  object UTABLA: TIBTable
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 32
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 32
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL18.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySoft'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 536
    Top = 32
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 576
    Top = 32
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 72
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 72
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V22.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 536
    Top = 72
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 576
    Top = 72
  end
  object PTABLA: TIBTable
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 112
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 504
    Top = 112
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PERSBIG.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySoft'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 544
    Top = 112
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 584
    Top = 112
  end
end
