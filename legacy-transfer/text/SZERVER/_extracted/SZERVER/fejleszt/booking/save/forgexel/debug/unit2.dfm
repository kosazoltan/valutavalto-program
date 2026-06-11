object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 329
  ClientWidth = 441
  Color = clActiveCaption
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
    Left = 32
    Top = 24
    Width = 385
    Height = 21
    Caption = 'FORGALMI ADATOK EXCELT'#193'BL'#193'BA '
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
  end
  object Label2: TLabel
    Left = 144
    Top = 48
    Width = 116
    Height = 21
    Caption = 'M'#193'SOL'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
  end
  object CSIK2: TProgressBar
    Left = 16
    Top = 280
    Width = 409
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 248
    Width = 409
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object PROCESSPANEL: TPanel
    Left = 16
    Top = 88
    Width = 409
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object PROG2PANEL: TPanel
    Left = 16
    Top = 136
    Width = 409
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object PROG3PANEL: TPanel
    Left = 16
    Top = 184
    Width = 409
    Height = 41
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object kilepo: TTimer
    Enabled = False
    Interval = 200
    OnTimer = kilepoTimer
    Left = 144
    Top = 272
  end
  object BOOKQUERY: TIBQuery
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 312
    Top = 272
  end
  object BOOKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 344
    Top = 272
  end
  object BOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BOOKDBASE
    AutoStopAction = saNone
    Left = 376
    Top = 272
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 272
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 272
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 272
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 272
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 192
    Top = 272
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 224
    Top = 272
  end
end
