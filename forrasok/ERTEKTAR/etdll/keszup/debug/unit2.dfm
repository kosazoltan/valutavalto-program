object KESZLETBEKULDO: TKESZLETBEKULDO
  Left = 534
  Top = 412
  BorderStyle = bsNone
  Caption = '0i'
  ClientHeight = 44
  ClientWidth = 189
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 41
    BevelOuter = bvNone
    Caption = 'K'#201'SZLETFELT'#214'LT'#201'S'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Visible = False
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = KILEPOTimer
    Left = 104
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
end
