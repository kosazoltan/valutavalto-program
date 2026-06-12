object Form2: TForm2
  Left = 649
  Top = 280
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 218
  ClientWidth = 549
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
    Width = 549
    Height = 218
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 4
  end
  object CSIK: TProgressBar
    Left = 32
    Top = 128
    Width = 489
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object UZENOPANEL: TPanel
    Left = 24
    Top = 64
    Width = 505
    Height = 25
    BevelOuter = bvNone
    Caption = 'UZENOPANEL'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object VISSZAGOMB: TBitBtn
    Left = 136
    Top = 168
    Width = 257
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'H'#214'Z'
    TabOrder = 2
    Visible = False
    OnClick = VISSZAGOMBClick
  end
  object Panel1: TPanel
    Left = 16
    Top = 8
    Width = 513
    Height = 41
    BevelOuter = bvNone
    Caption = 'A KEZEL'#201'SI- '#201'S TRANZAKCI'#211'S D'#205'JAK LIST'#193'JA'
    Color = clWhite
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 32
    Top = 24
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 24
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
    Left = 96
    Top = 24
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 24
  end
  object DQUERY: TIBQuery
    Database = DDBASE
    Transaction = DTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 24
  end
  object DDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = DTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 24
  end
  object DTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 24
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 56
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
    Left = 200
    Top = 56
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 56
  end
  object KDIJQUERY: TIBQuery
    Database = KDIJDBASE
    Transaction = KDIJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 56
  end
  object KDIJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KEZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KDIJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 56
  end
  object KDIJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDIJDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 56
  end
  object KDIJTABLA: TIBTable
    Database = KDIJDBASE
    Transaction = KDIJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 56
  end
  object TRANZDIJQUERY: TIBQuery
    Database = TRANZDIJDBASE
    Transaction = TRANZDIJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 88
  end
  object TRANZDIJDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TRANZDIJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 88
  end
  object TRANZDIJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRANZDIJDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 88
  end
end
