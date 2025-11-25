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
    object Memo2: TMemo
      Left = 56
      Top = 128
      Width = 393
      Height = 193
      BorderStyle = bsNone
      Color = 6710886
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      Lines.Strings = (
        ''
        '')
      ParentFont = False
      TabOrder = 0
    end
    object Panel1: TPanel
      Left = 16
      Top = 16
      Width = 473
      Height = 41
      BevelOuter = bvNone
      Caption = 'ADATB'#193'ZISOK'
      Color = 6710886
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object ALCIMPANEL: TPanel
      Left = 16
      Top = 56
      Width = 473
      Height = 41
      BevelOuter = bvNone
      Caption = 'ELMENT'#201'SE'
      Color = 6710886
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 4000
    OnTimer = KILEPOTimer
    Left = 456
    Top = 304
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 296
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 296
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 296
  end
end
