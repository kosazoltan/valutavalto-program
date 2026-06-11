object Form1: TForm1
  Left = 192
  Top = 125
  Width = 1054
  Height = 649
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
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'KERES'#201'S'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 88
    Top = 8
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 304
    Top = 16
    Width = 481
    Height = 545
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    TabOrder = 2
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 10000
    Left = 64
    Top = 264
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 272
  end
  object BLOKKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V136.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 272
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 272
  end
  object EXTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = EXDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 376
  end
  object EXDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KERESO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = EXTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 376
  end
  object EXQUERY: TIBQuery
    Database = EXDBASE
    Transaction = EXTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 376
  end
  object REMQUERY: TIBQuery
    Database = REMDBASE
    Transaction = REMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 328
  end
  object REMDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\UGYEL19.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 216
    Top = 328
  end
  object REMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMDBASE
    AutoStopAction = saNone
    Left = 256
    Top = 328
  end
end
