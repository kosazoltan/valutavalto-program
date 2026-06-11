object Form1: TForm1
  Left = 192
  Top = 125
  Width = 1305
  Height = 675
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
    Left = 56
    Top = 40
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object Panel1: TPanel
    Left = 368
    Top = 144
    Width = 369
    Height = 41
    Caption = 'Panel1'
    TabOrder = 1
  end
  object BitBtn2: TBitBtn
    Left = 56
    Top = 16
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 2
    OnClick = BitBtn2Click
  end
  object DBOOKQUERY: TIBQuery
    Database = DBOOKDBASE
    Transaction = DBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 40
  end
  object DBOOKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = DBOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 40
  end
  object DBOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DBOOKDBASE
    AutoStopAction = saNone
    Left = 272
    Top = 40
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 80
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 120
  end
  object GYQUERY: TIBQuery
    Database = GYDBASE
    Transaction = GYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 160
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 80
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V67.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 120
  end
  object GYDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTARFORG.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 160
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 80
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 120
  end
  object GYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 160
  end
end
