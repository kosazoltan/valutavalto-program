object Form2: TForm2
  Left = 197
  Top = 119
  AlphaBlend = True
  AlphaBlendValue = 180
  BorderStyle = bsNone
  ClientHeight = 36
  ClientWidth = 459
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 457
    Height = 33
    Caption = 'KERESKEDELMI ADATOK REGENER'#193'L'#193'SA'
    Color = 16756991
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object TradeDbase: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TradeTranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object TradeTranz: TIBTransaction
    Active = False
    DefaultDatabase = TradeDbase
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object KILEPES: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPESTimer
    Left = 104
    Top = 8
  end
  object TradeQuery: TIBQuery
    Database = TradeDbase
    Transaction = TradeTranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object TRADETABLA: TIBTable
    Database = TradeDbase
    Transaction = TradeTranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 8
  end
  object NAPIQUERY: TIBQuery
    Database = NAPIDBASE
    Transaction = NAPITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 8
  end
  object NAPIDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = NAPITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 8
  end
  object NAPITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPIDBASE
    AutoStopAction = saNone
    Left = 224
    Top = 8
  end
  object HAVIQUERY: TIBQuery
    Database = HAVIDBASE
    Transaction = HAVITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 8
  end
  object HAVIDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 8
  end
  object HAVITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
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
    Left = 392
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 416
    Top = 8
  end
end
