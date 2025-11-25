object NAPZARNYOMTATOFORM: TNAPZARNYOMTATOFORM
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'NAPZARNYOMTATOFORM'
  ClientHeight = 201
  ClientWidth = 431
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object NYOMFORMPANEL: TPanel
    Left = 0
    Top = 0
    Width = 430
    Height = 201
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clSilver
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 430
      Height = 201
      Align = alClient
      Brush.Color = clSilver
      Pen.Color = clWhite
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 64
      Top = 24
      Width = 311
      Height = 28
      Caption = 'NAPI Z'#193'R'#193'S NYOMTAT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object DATUMPANEL: TPanel
      Left = 32
      Top = 72
      Width = 377
      Height = 41
      BevelOuter = bvNone
      Color = clSilver
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object CSIK: TProgressBar
      Left = 32
      Top = 120
      Width = 377
      Height = 17
      Min = 0
      Max = 120
      Smooth = True
      TabOrder = 1
    end
  end
  object IDOZITO: TTimer
    Enabled = False
    Interval = 4000
    OnTimer = IDOZITOTimer
    Left = 8
    Top = 160
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 160
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 160
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 144
    Top = 160
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 328
    Top = 160
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 360
    Top = 160
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 392
    Top = 160
  end
  object VALUTATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'ELOLEGARCHIVE'
    Left = 48
    Top = 160
  end
  object XTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = XDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 128
    Top = 64
  end
  object XDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = XTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 64
  end
  object XQUERY: TIBQuery
    Database = XDBASE
    Transaction = XTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 64
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 296
    Top = 160
  end
  object XTABLA: TIBTable
    Database = XDBASE
    Transaction = XTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 64
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 160
  end
  object HRKDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\hazihrk.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 160
  end
  object HRKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HRKDBASE
    AutoStopAction = saNone
    Left = 256
    Top = 160
  end
  object NAPLOQUERY: TIBQuery
    Database = NAPLODBASE
    Transaction = NAPLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 64
  end
  object NAPLODBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\hazihrk.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NAPLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 64
  end
  object NAPLOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPLODBASE
    AutoStopAction = saNone
    Left = 280
    Top = 64
  end
end
