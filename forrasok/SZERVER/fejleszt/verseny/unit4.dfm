object MAKEEXCEL: TMAKEEXCEL
  Left = 389
  Top = 258
  BorderStyle = bsNone
  Caption = 'MAKEEXCEL'
  ClientHeight = 198
  ClientWidth = 415
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 64
    Top = 48
    Width = 310
    Height = 36
    Caption = 'Excelt'#225'bla '#246'ssze'#225'llit'#225'sa'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object csik: TProgressBar
    Left = 24
    Top = 120
    Width = 369
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object KILEPOGOMB: TBitBtn
    Left = 136
    Top = 152
    Width = 155
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    Visible = False
    OnClick = KILEPOGOMBClick
  end
  object PENZTARTABLA: TIBTable
    Database = PENZTARDBASE
    Transaction = PENZTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'KORZET'
    TableName = 'PENZTAR'
    Left = 8
    Top = 8
  end
  object PENZTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTARDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
  object PENZTARDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\verseny.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PENZTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object PENZTAROSTABLA: TIBTable
    Database = PENZTAROSDBASE
    Transaction = PENZTAROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexName = 'IDX_PENZTAROS1'
    TableName = 'PENZTAROS'
    Left = 152
    Top = 8
  end
  object PENZTAROSDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\verseny.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PENZTAROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 184
    Top = 8
  end
  object PENZTAROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTAROSDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 288
    Top = 8
  end
end
