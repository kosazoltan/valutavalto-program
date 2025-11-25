object KESZLETBEKULDO: TKESZLETBEKULDO
  Left = 192
  Top = 123
  BorderStyle = bsNone
  Caption = '0i'
  ClientHeight = 24
  ClientWidth = 1008
  Color = clRed
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
    Left = 192
    Top = 1
    Width = 631
    Height = 25
    Caption = 'AZ AKTU'#193'LIS K'#201'SZLET '#201'S FORGALOM BEK'#220'LD'#201'SE'
    Color = clRed
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    Transparent = True
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
  object IBQuery: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 8
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 8
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 200
    Top = 8
  end
  object IBTabla: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 232
    Top = 8
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object TRADEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 296
    Top = 8
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 8
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 328
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 360
    Top = 8
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 392
    Top = 8
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 424
    Top = 8
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 456
    Top = 8
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 488
    Top = 8
  end
end
