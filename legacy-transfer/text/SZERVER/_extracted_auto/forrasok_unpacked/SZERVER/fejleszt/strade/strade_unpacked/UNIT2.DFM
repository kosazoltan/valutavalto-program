object HAVIEGYENLEG: THAVIEGYENLEG
  Left = 322
  Top = 218
  BorderStyle = bsNone
  Caption = 'HAVIEGYENLEG'
  ClientHeight = 194
  ClientWidth = 513
  Color = 11599871
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 8
    Top = 8
    Width = 489
    Height = 177
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 64
    Top = 24
    Width = 405
    Height = 24
    Caption = 'A BEOLVASOTT ADATOK BEDOLGOZ'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 328
    Top = 76
    Width = 121
    Height = 37
    Caption = 'H'#211'NAP'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label3: TLabel
    Left = 240
    Top = 128
    Width = 158
    Height = 37
    Caption = 'P'#201'NZT'#193'R'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object EVPANEL: TPanel
    Left = 112
    Top = 72
    Width = 113
    Height = 41
    BevelOuter = bvNone
    Caption = '2010'
    Color = 11599871
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object HONAPPANEL: TPanel
    Left = 240
    Top = 72
    Width = 73
    Height = 41
    BevelOuter = bvNone
    Caption = '12'
    Color = 11599871
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object IRODAPANEL: TPanel
    Left = 112
    Top = 128
    Width = 113
    Height = 41
    BevelOuter = bvNone
    Caption = '150'
    Color = 11599871
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object STRADEQUERY: TIBQuery
    Database = STRADEDBASE
    Transaction = STRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 8
  end
  object STRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = STRADEDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 8
  end
  object STRADEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = STRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 8
  end
  object HAVITABLA: TIBTable
    Database = HAVIDBASE
    Transaction = HAVITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 40
  end
  object HAVIQUERY: TIBQuery
    Database = HAVIDBASE
    Transaction = HAVITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 40
  end
  object HAVIDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 40
  end
  object HAVITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 40
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 50
    OnTimer = INDITOTimer
    Left = 16
    Top = 8
  end
end
