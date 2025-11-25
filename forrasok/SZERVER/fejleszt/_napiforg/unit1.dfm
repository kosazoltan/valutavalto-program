object Form1: TForm1
  Left = 541
  Top = 218
  Width = 352
  Height = 533
  Caption = 'FORGALMI ADATOK K'#220'LD'#201'SE'
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
  object Label1: TLabel
    Left = 96
    Top = 32
    Width = 159
    Height = 18
    Caption = 'FORGALMI ADATOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 80
    Top = 56
    Width = 195
    Height = 18
    Caption = 'ELK'#220'LD'#201'SE E-MAILBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Memo1: TMemo
    Left = 32
    Top = 80
    Width = 273
    Height = 385
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 0
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 88
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 88
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 88
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 88
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 128
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
    Left = 80
    Top = 128
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 128
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 168
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
    Left = 80
    Top = 168
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 168
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTimer
    Left = 216
    Top = 88
  end
end
