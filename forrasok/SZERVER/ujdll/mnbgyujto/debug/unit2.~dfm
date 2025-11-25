object MNBLEGYUJTO: TMNBLEGYUJTO
  Left = 288
  Top = 347
  AlphaBlend = True
  AlphaBlendValue = 180
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = '0'
  ClientHeight = 225
  ClientWidth = 572
  Color = clWhite
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
    Width = 572
    Height = 225
    Align = alClient
    Brush.Color = 6781877
    Pen.Width = 3
  end
  object mnbcsik: TProgressBar
    Left = 8
    Top = 120
    Width = 561
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object TOLIGPANEL: TPanel
    Left = 8
    Top = 8
    Width = 561
    Height = 33
    BevelOuter = bvNone
    Caption = '2020 szeptember 12 -23'
    Color = 6781877
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object INFOPANEL: TPanel
    Left = 8
    Top = 48
    Width = 561
    Height = 33
    BevelOuter = bvNone
    Caption = 'K'#214'Z'#214'TTI ADATOK LET'#214'LT'#201'SE'
    Color = 6781877
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Eras Medium ITC'
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
    Color = 6781877
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
  end
  object MESSPANEL: TPanel
    Left = 8
    Top = 88
    Width = 561
    Height = 25
    BevelOuter = bvNone
    Caption = 'MESSPANEL'
    Color = 6781877
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
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
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 16
  end
  object BLOKKDBASE: TIBDatabase
    DatabaseName = 'localhost:'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 16
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 96
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
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
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
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 16
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 488
    Top = 16
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 520
    Top = 16
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTimer
    Left = 16
    Top = 48
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 456
    Top = 80
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 488
    Top = 80
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 520
    Top = 80
  end
end
