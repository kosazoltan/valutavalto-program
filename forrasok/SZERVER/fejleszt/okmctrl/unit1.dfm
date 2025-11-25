object Form1: TForm1
  Left = 192
  Top = 125
  Width = 870
  Height = 640
  Caption = 'HI'#193'NYZ'#211' OKM'#193'NYOK'
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
    Width = 854
    Height = 601
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 304
    Top = 22
    Width = 193
    Height = 22
    Caption = 'D'#193'TUMT'#211'L KEZDVE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object STARTGOMB: TBitBtn
    Left = 504
    Top = 24
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Enabled = False
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 616
    Top = 560
    Width = 171
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object DATUMEDIT: TEdit
    Left = 184
    Top = 16
    Width = 113
    Height = 30
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    MaxLength = 10
    ParentFont = False
    TabOrder = 2
    OnEnter = DATUMEDITEnter
    OnExit = DATUMEDITExit
    OnKeyDown = DATUMEDITKeyDown
  end
  object CSIK: TProgressBar
    Left = 48
    Top = 64
    Width = 737
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 3
  end
  object ALCSIK: TProgressBar
    Left = 48
    Top = 88
    Width = 737
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 4
  end
  object Panel1: TPanel
    Left = 48
    Top = 112
    Width = 121
    Height = 25
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object Panel2: TPanel
    Left = 176
    Top = 112
    Width = 241
    Height = 25
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
  end
  object Panel3: TPanel
    Left = 424
    Top = 112
    Width = 137
    Height = 25
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
  end
  object RACS: TDBGrid
    Left = 48
    Top = 144
    Width = 737
    Height = 409
    Color = 11599871
    DataSource = HIANYSOURCE
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 8
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
  end
  object Panel4: TPanel
    Left = 568
    Top = 112
    Width = 217
    Height = 25
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 9
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
  end
  object BIZDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 712
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 744
  end
  object NEVQUERY: TIBQuery
    Database = NEVDBASE
    Transaction = NEVTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
    Top = 32
  end
  object NEVDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NEVTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 712
    Top = 32
  end
  object NEVTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NEVDBASE
    AutoStopAction = saNone
    Left = 744
    Top = 32
  end
  object OKMQUERY: TIBQuery
    Database = OKMDBASE
    Transaction = OKMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
    Top = 64
  end
  object OKMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\OKMCTRL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = OKMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 712
    Top = 64
  end
  object OKMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = OKMDBASE
    AutoStopAction = saNone
    Left = 744
    Top = 64
  end
  object HIANYSOURCE: TDataSource
    DataSet = OKMQUERY
    Enabled = False
    Left = 128
    Top = 24
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 792
    Top = 176
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
    Left = 792
    Top = 216
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 792
    Top = 256
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 792
    Top = 344
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
    Left = 792
    Top = 384
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 792
    Top = 424
  end
end
