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
  object Button1: TButton
    Left = 64
    Top = 48
    Width = 177
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 64
    Top = 80
    Width = 177
    Height = 25
    Caption = 'KILEP'
    TabOrder = 1
    OnClick = Button2Click
  end
  object ptarpanel: TPanel
    Left = 216
    Top = 168
    Width = 241
    Height = 41
    Caption = 'ptarpanel'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object RECTABLA: TIBTable
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 320
    Top = 24
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 24
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
    Left = 384
    Top = 24
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 416
    Top = 24
  end
  object pttabla: TIBTable
    Database = ptdbase
    Transaction = pttranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 320
    Top = 56
  end
  object ptquery: TIBQuery
    Database = ptdbase
    Transaction = pttranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 56
  end
  object ptdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V9.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = pttranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 56
  end
  object pttranz: TIBTransaction
    Active = False
    DefaultDatabase = ptdbase
    AutoStopAction = saNone
    Left = 416
    Top = 56
  end
  object TRANZTABLA: TIBTable
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 320
    Top = 88
  end
  object TRANZQUERY: TIBQuery
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 88
  end
  object TRANZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZDB.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRANZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 88
  end
  object TRANZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRANZDBASE
    AutoStopAction = saNone
    Left = 416
    Top = 88
  end
end
