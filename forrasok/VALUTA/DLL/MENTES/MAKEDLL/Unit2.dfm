object NAPIMENTES: TNAPIMENTES
  Left = 198
  Top = 131
  BorderStyle = bsNone
  ClientHeight = 350
  ClientWidth = 502
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
  object BACKUPPANEL: TPanel
    Left = -4
    Top = 0
    Width = 505
    Height = 350
    TabOrder = 0
    object Shape4: TShape
      Left = 1
      Top = 1
      Width = 503
      Height = 348
      Align = alClient
      Brush.Color = 6710886
      Pen.Color = clWhite
      Pen.Width = 10
    end
    object Panel1: TPanel
      Left = 16
      Top = 16
      Width = 473
      Height = 41
      BevelOuter = bvNone
      Caption = 'NAPI ADATMENT'#201'S'
      Color = 6710886
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 456
    Top = 304
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 136
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 136
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 136
    Top = 136
  end
end
