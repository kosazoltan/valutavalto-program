object Form1: TForm1
  Left = 473
  Top = 288
  Width = 409
  Height = 273
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
    Left = 24
    Top = 24
    Width = 169
    Height = 25
    Caption = 'P'#211'TL'#193'S INDUL'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 192
    Top = 24
    Width = 169
    Height = 25
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 24
    Top = 64
    Width = 337
    Height = 153
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 24
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 216
    Top = 24
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 248
    Top = 24
  end
  object UTABLA: TIBTable
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 24
  end
  object TQUERY: TIBQuery
    Database = TDBASE
    Transaction = TTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 56
  end
  object TDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 56
  end
  object TTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 56
  end
  object IDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ISO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 120
  end
  object ITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 120
  end
  object IQUERY: TIBQuery
    Database = IDBASE
    Transaction = ITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 120
  end
  object NTABLA: TIBTable
    Database = NDBASE
    Transaction = NTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 176
  end
  object NDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 176
  end
  object NTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 176
  end
  object NQUERY: TIBQuery
    Database = NDBASE
    Transaction = NTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 144
    Top = 176
  end
end
