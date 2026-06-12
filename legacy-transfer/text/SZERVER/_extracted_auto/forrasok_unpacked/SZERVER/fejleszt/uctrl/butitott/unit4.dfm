object MAKEEXCEL: TMAKEEXCEL
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = '['
  ClientHeight = 165
  ClientWidth = 544
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 544
    Height = 165
    Align = alClient
    Brush.Color = clBtnFace
    Pen.Color = clRed
    Pen.Width = 3
  end
  object Label1: TLabel
    Left = 16
    Top = 24
    Width = 516
    Height = 35
    BiDiMode = bdRightToLeft
    Caption = 'EXCELT'#193'BLA '#214'SSZE'#193'LL'#205'T'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentBiDiMode = False
    ParentFont = False
    Transparent = True
  end
  object Panel1: TPanel
    Left = 88
    Top = 64
    Width = 401
    Height = 41
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object CSIK: TProgressBar
    Left = 24
    Top = 120
    Width = 497
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
  object TETQUERY: TIBQuery
    Database = TETDBASE
    Transaction = TETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 8
  end
  object FEJDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 8
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 8
  end
  object FEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 8
  end
  object TETDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 192
    Top = 8
  end
  object TETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETDBASE
    AutoStopAction = saNone
    Left = 224
    Top = 8
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 8
  end
  object UDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:185.43.207.99:C:\RECEPTOR\DATABASE\UGYFEL19'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 8
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 8
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 392
    Top = 8
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 424
    Top = 8
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 464
    Top = 8
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 40
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
    Left = 88
    Top = 40
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 40
  end
end
