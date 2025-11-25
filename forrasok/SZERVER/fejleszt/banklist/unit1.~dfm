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
    Left = 32
    Top = 32
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 32
    Top = 64
    Width = 75
    Height = 25
    Caption = 'BitBtn2'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Panel1: TPanel
    Left = 40
    Top = 200
    Width = 305
    Height = 41
    Caption = 'Panel1'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 40
    Top = 144
    Width = 305
    Height = 41
    Caption = 'Panel2'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object Panel3: TPanel
    Left = 40
    Top = 256
    Width = 305
    Height = 41
    Caption = 'Panel3'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
  end
  object Panel4: TPanel
    Left = 40
    Top = 312
    Width = 305
    Height = 41
    Caption = 'Panel4'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object Panel5: TPanel
    Left = 40
    Top = 368
    Width = 305
    Height = 41
    Caption = 'Panel5'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
  end
  object Panel6: TPanel
    Left = 40
    Top = 424
    Width = 305
    Height = 41
    Caption = 'Panel6'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
  end
  object Panel7: TPanel
    Left = 40
    Top = 480
    Width = 305
    Height = 41
    Caption = 'Panel7'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
  object BANKQUERY: TIBQuery
    Database = BANKDBASE
    Transaction = BANKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 40
  end
  object BANKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\BANKDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BANKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 40
  end
  object BANKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BANKDBASE
    AutoStopAction = saNone
    Left = 264
    Top = 40
  end
  object UTQUERY: TIBQuery
    Database = UTDBASE
    Transaction = UTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
    Top = 40
  end
  object UTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\mbest.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 400
    Top = 40
  end
  object UTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UTDBASE
    AutoStopAction = saNone
    Left = 440
    Top = 40
  end
  object UF18QUERY: TIBQuery
    Database = UF18DBASE
    Transaction = UF18TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 528
    Top = 48
  end
  object UF19QUERY: TIBQuery
    Database = UF19DBASE
    Transaction = UF19TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 528
    Top = 88
  end
  object UF18DBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL18.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UF18TRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 568
    Top = 48
  end
  object UF19DBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL19.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UF19TRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 568
    Top = 88
  end
  object UF18TRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UF18DBASE
    AutoStopAction = saNone
    Left = 608
    Top = 48
  end
  object UF19TRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UF19DBASE
    AutoStopAction = saNone
    Left = 608
    Top = 88
  end
  object BTQUERY: TIBQuery
    Database = BTDBASE
    Transaction = BTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 536
    Top = 160
  end
  object BTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V53.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 576
    Top = 160
  end
  object BTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BTDBASE
    AutoStopAction = saNone
    Left = 616
    Top = 160
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 544
    Top = 272
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
    Left = 584
    Top = 272
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 624
    Top = 272
  end
  object CASHQUERY: TIBQuery
    Database = CASHDBASE
    Transaction = CASHTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 544
    Top = 312
  end
  object CASHDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = CASHTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 584
    Top = 312
  end
  object CASHTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CASHDBASE
    AutoStopAction = saNone
    Left = 624
    Top = 312
  end
  object BTTABLA: TIBTable
    Database = BTDBASE
    Transaction = BTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 504
    Top = 160
  end
end
