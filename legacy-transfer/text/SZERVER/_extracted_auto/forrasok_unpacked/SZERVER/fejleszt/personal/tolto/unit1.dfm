object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
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
    Left = 72
    Top = 80
    Width = 737
    Height = 41
    Caption = 'A PERSONAL.FDB FELT'#214'LT'#201'SE ADATOKKAL'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 56
    Top = 528
    Width = 75
    Height = 25
    Caption = 'INDUL'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object Panel1: TPanel
    Left = 80
    Top = 184
    Width = 665
    Height = 41
    Caption = 'Panel1'
    TabOrder = 1
  end
  object Panel2: TPanel
    Left = 80
    Top = 248
    Width = 665
    Height = 41
    Caption = 'Panel2'
    TabOrder = 2
  end
  object CSIK: TProgressBar
    Left = 80
    Top = 312
    Width = 665
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 3
  end
  object Panel3: TPanel
    Left = 80
    Top = 424
    Width = 673
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel4: TPanel
    Left = 328
    Top = 360
    Width = 185
    Height = 41
    Caption = 'Panel4'
    TabOrder = 5
  end
  object BitBtn2: TBitBtn
    Left = 56
    Top = 560
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 6
    OnClick = BitBtn2Click
  end
  object SOURCEQUERY: TIBQuery
    Database = SOURCEDBASE
    Transaction = SOURCETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 24
  end
  object SOURCEDBASE: TIBDatabase
    DatabaseName = 'C:\_UGYFELEK\004\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SOURCETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 24
  end
  object SOURCETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SOURCEDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 24
  end
  object TARGETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\perstemp.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TARGETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 144
  end
  object TARGETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TARGETDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 144
  end
  object TARGETQUERY: TIBQuery
    Database = TARGETDBASE
    Transaction = TARGETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 144
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 24
  end
  object RECEPTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 24
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 24
  end
  object sourcetabla: TIBTable
    Database = SOURCEDBASE
    Transaction = SOURCETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Top = 24
  end
end
