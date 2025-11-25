object JUTALEK: TJUTALEK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'JUTALEK'
  ClientHeight = 220
  ClientWidth = 421
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
    Left = 32
    Top = 0
    Width = 371
    Height = 36
    Caption = 'P'#233'nzt'#225'rosok forgalmi adatai'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object PROSNEVPANEL: TPanel
    Left = 32
    Top = 88
    Width = 350
    Height = 33
    BevelOuter = bvNone
    Caption = 'PROSNEVPANEL'
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object VALTOPANEL: TPanel
    Left = 88
    Top = 120
    Width = 257
    Height = 33
    BevelOuter = bvNone
    Caption = 'VALTOPANEL'
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object highcsik: TProgressBar
    Left = 16
    Top = 176
    Width = 393
    Height = 25
    Min = 0
    Max = 150
    Smooth = True
    TabOrder = 2
  end
  object smallcsik: TProgressBar
    Left = 16
    Top = 160
    Width = 393
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 3
  end
  object honappanel: TPanel
    Left = 96
    Top = 64
    Width = 225
    Height = 25
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
  end
  object IPANEL: TPanel
    Left = 8
    Top = 40
    Width = 105
    Height = 17
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 5
  end
  object npanel: TPanel
    Left = 120
    Top = 40
    Width = 297
    Height = 17
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 6
  end
  object VFEJTABLA: TIBTable
    Database = VFEJDBASE
    Transaction = VFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 224
    Top = 184
  end
  object VFEJQUERY: TIBQuery
    Database = VFEJDBASE
    Transaction = VFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 184
  end
  object VFEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 128
    Top = 184
  end
  object VFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VFEJDBASE
    AutoStopAction = saNone
    Left = 160
    Top = 184
  end
  object VTETQUERY: TIBQuery
    Database = VTETDBASE
    Transaction = VTETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 184
  end
  object VTETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 184
  end
  object VTETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VTETDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 184
  end
  object START: TTimer
    Enabled = False
    Interval = 150
    OnTimer = STARTTimer
    Left = 256
    Top = 184
  end
end
