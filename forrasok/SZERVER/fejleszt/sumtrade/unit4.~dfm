object UJADATGYUJTO: TUJADATGYUJTO
  Left = 348
  Top = 339
  BorderStyle = bsNone
  Caption = 'UJADATGYUJTO'
  ClientHeight = 78
  ClientWidth = 478
  Color = 4539717
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
    Left = 56
    Top = 16
    Width = 358
    Height = 33
    Caption = 'ADATOK '#214'SSZEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = INDITOTimer
    Left = 8
    Top = 8
  end
  object SQUERY: TIBQuery
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object SDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object STRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SDBASE
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
    Top = 40
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 40
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
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
    Top = 40
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 40
  end
  object STABLA: TIBTable
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 8
  end
end
