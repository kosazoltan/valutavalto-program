object TABMAKER: TTABMAKER
  Left = 188
  Top = 141
  AlphaBlend = True
  AlphaBlendValue = 180
  BorderStyle = bsNone
  Caption = 'TABMAKER'
  ClientHeight = 91
  ClientWidth = 910
  Color = 16311512
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
    Left = 272
    Top = 0
    Width = 405
    Height = 36
    Caption = 'TABL'#211'K'#201'SZ'#205'T'#336' PROGRAM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 40
    Width = 873
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object KORZETCSIK: TProgressBar
    Left = 16
    Top = 64
    Width = 873
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KilepoTimerTimer
    Left = 16
    Top = 8
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 8
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 8
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 8
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 8
  end
  object IBTablA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 8
  end
  object IBQuery: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 248
    Top = 8
  end
  object IBDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 280
    Top = 8
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 312
    Top = 8
  end
end
