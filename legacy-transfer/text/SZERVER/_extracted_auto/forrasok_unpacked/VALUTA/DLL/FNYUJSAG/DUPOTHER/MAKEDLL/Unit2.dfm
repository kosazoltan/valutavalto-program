object Fnyujsag: TFnyujsag
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 61
  ClientWidth = 652
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = [fsBold, fsItalic]
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 652
    Height = 61
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Panel1: TPanel
    Left = 48
    Top = 16
    Width = 577
    Height = 33
    BevelOuter = bvNone
    Caption = #193'rfolyamok kik'#252'ld'#233'se  a fut'#243'f'#233'ny-displayre'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object IBQuery: TIBQuery
    Database = IBDbase
    Transaction = ibtranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
  end
  object IBDbase: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ibtranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
  end
  object ibtranz: TIBTransaction
    Active = False
    DefaultDatabase = IBDbase
    AutoStopAction = saNone
    Left = 96
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = INDITOTimer
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTimer
    Top = 24
  end
end
