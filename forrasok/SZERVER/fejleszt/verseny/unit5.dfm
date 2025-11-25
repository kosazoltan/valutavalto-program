object UJPENZTARFORGALOM: TUJPENZTARFORGALOM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'UJPENZTARFORGALOM'
  ClientHeight = 232
  ClientWidth = 415
  Color = clGray
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
    Left = 48
    Top = 24
    Width = 331
    Height = 36
    Caption = 'P'#233'nzt'#225'rak forgalmi adatai.'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
  end
  object PENZTARPANEL: TPanel
    Left = 16
    Top = 112
    Width = 385
    Height = 33
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object SMALLCSIK: TProgressBar
    Left = 8
    Top = 168
    Width = 401
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object HIGHCSIK: TProgressBar
    Left = 8
    Top = 184
    Width = 401
    Height = 25
    Min = 0
    Max = 150
    Smooth = True
    TabOrder = 2
  end
  object honappanel: TPanel
    Left = 8
    Top = 72
    Width = 393
    Height = 33
    BevelOuter = bvNone
    Caption = 'honappanel'
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object START: TTimer
    Enabled = False
    Interval = 150
    OnTimer = STARTTimer
    Left = 24
    Top = 24
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 24
  end
  object BLOKKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 24
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 24
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 24
  end
end
