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
  object BitBtn1: TBitBtn
    Left = 48
    Top = 80
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 48
    Top = 56
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 168
    Top = 16
    Width = 425
    Height = 569
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
  end
  object Memo2: TMemo
    Left = 648
    Top = 24
    Width = 185
    Height = 569
    Lines.Strings = (
      'Memo2')
    TabOrder = 3
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 56
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 416
    Top = 56
  end
  object VDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 456
    Top = 56
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 496
    Top = 56
  end
  object TETQUERY: TIBQuery
    Database = TETDBASE
    Transaction = TETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 112
  end
  object TETDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 416
    Top = 112
  end
  object TETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETDBASE
    AutoStopAction = saNone
    Left = 456
    Top = 112
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 160
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\POLICE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 424
    Top = 160
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 464
    Top = 160
  end
end
