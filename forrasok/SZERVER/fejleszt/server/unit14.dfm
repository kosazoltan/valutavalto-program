object MNBLEGYUJTO: TMNBLEGYUJTO
  Left = 283
  Top = 300
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = '0'
  ClientHeight = 225
  ClientWidth = 578
  Color = 8421631
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
    Left = 0
    Top = 0
    Width = 577
    Height = 225
    Brush.Color = 8421631
    Pen.Color = clWhite
    Pen.Width = 7
  end
  object mnbcsik: TProgressBar
    Left = 8
    Top = 120
    Width = 561
    Height = 17
    BorderWidth = 2
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object TOLIGPANEL: TPanel
    Left = 8
    Top = 8
    Width = 561
    Height = 41
    BevelOuter = bvNone
    Caption = 'A 2006 '
    Color = 8421631
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object INFOPANEL: TPanel
    Left = 8
    Top = 56
    Width = 561
    Height = 41
    BevelOuter = bvNone
    Caption = 'K'#214'Z'#214'TTI ADATOK LET'#214'LT'#201'SE'
    Color = 8421631
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object FCSIK: TProgressBar
    Left = 8
    Top = 192
    Width = 561
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 3
  end
  object uzletpanel: TPanel
    Left = 8
    Top = 144
    Width = 561
    Height = 41
    BevelOuter = bvNone
    Color = 8421631
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object LETOLTESINDITO: TTimer
    Enabled = False
    OnTimer = LETOLTESINDITOTimer
    Left = 16
    Top = 16
  end
  object MNBTABLA: TIBTable
    Database = MNBDBASE
    Transaction = MNBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'MNB'
    Left = 16
    Top = 152
  end
  object MNBDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = MNBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 152
  end
  object MNBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MNBDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 152
  end
  object MNBTEMPTABLA: TIBTable
    Database = MNBTEMPDBASE
    Transaction = MNBTEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'MNBTEMP'
    Left = 176
    Top = 152
  end
  object MNBTEMPDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = MNBTEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 152
  end
  object MNBTEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MNBTEMPDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 152
  end
  object BLOKKFEJTABLA: TIBTable
    Database = BLOKKFEJDBASE
    Transaction = BLOKKFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object BLOKKFEJDBASE: TIBDatabase
    DatabaseName = 'localhost:'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 16
  end
  object BLOKKFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKFEJDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 16
  end
  object BLOKKTETELTABLA: TIBTable
    Database = BLOKKTETELDBASE
    Transaction = BLOKKTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 344
    Top = 16
  end
  object BLOKKTETELDBASE: TIBDatabase
    DatabaseName = 'localhost:'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 376
    Top = 16
  end
  object BLOKKTETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKTETELDBASE
    AutoStopAction = saNone
    Left = 408
    Top = 16
  end
  object CIMTARTABLA: TIBTable
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 152
  end
  object CIMTARDBASE: TIBDatabase
    DatabaseName = 'localhost:'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = CIMTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 488
    Top = 152
  end
  object CIMTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CIMTARDBASE
    AutoStopAction = saNone
    Left = 520
    Top = 152
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKFEJDBASE
    Transaction = BLOKKFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 16
  end
  object MNBQUERY: TIBQuery
    Database = MNBDBASE
    Transaction = MNBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 112
    Top = 152
  end
  object CIMTARQUERY: TIBQuery
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 424
    Top = 152
  end
end
