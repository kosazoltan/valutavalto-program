object ADATFELTOLTES: TADATFELTOLTES
  Left = 645
  Top = 362
  BorderStyle = bsNone
  Caption = 'ADATFELTOLTES'
  ClientHeight = 162
  ClientWidth = 333
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
    Width = 333
    Height = 162
    Align = alClient
    Brush.Color = clSkyBlue
    Pen.Color = clNavy
    Pen.Width = 4
  end
  object Label1: TLabel
    Left = 40
    Top = 8
    Width = 264
    Height = 29
    Caption = 'ADATOK LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object CSIK: TProgressBar
    Left = 8
    Top = 136
    Width = 313
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object COUNTPANEL: TPanel
    Left = 72
    Top = 92
    Width = 185
    Height = 41
    BevelOuter = bvNone
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -27
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object MENETPANEL: TPanel
    Left = 72
    Top = 48
    Width = 185
    Height = 41
    BevelOuter = bvNone
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -24
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object BQUERY: TIBQuery
    Database = BDBASE
    Transaction = BTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 8
  end
  object BDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 8
  end
  object BTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 200
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 272
    Top = 8
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object VDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\V10.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
end
