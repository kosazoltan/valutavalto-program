object Form1: TForm1
  Left = 370
  Top = 256
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 147
  ClientWidth = 419
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
  object Label1: TLabel
    Left = 64
    Top = 32
    Width = 323
    Height = 43
    Caption = 'E-TRADE ADATOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 88
    Top = 80
    Width = 275
    Height = 43
    Caption = 'BEDOLGOZ'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object ETRADEQUERY: TIBQuery
    Database = ETRADEDBASE
    Transaction = ETRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object ETRADEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ETRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ETRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object ETRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ETRADEDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 300
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
  object ETRADETABLA: TIBTable
    Database = ETRADEDBASE
    Transaction = ETRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 8
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 280
    Top = 8
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 312
    Top = 8
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 344
    Top = 8
  end
  object HZQUERY: TIBQuery
    Database = HZDBASE
    Transaction = HZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 112
  end
  object HZTABLA: TIBTable
    Database = HZDBASE
    Transaction = HZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 112
  end
  object HZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ETRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 112
  end
  object HZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HZDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 112
  end
end
