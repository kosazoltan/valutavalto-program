object ADATGYUJTES: TADATGYUJTES
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 547
  ClientWidth = 664
  Color = 11702634
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object vaszon: TPaintBox
    Left = 8
    Top = 64
    Width = 590
    Height = 366
    Cursor = crHandPoint
    Color = 11702634
    ParentColor = False
  end
  object Panel1: TPanel
    Left = 8
    Top = 448
    Width = 593
    Height = 41
    BevelOuter = bvNone
    Color = 11702634
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object FOCIMPANEL: TPanel
    Left = 8
    Top = 8
    Width = 593
    Height = 41
    BevelOuter = bvNone
    Caption = '2015 SZEPTEMBER HAVI BESZ'#193'MOL'#211
    Color = 11702634
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object REKORDCSIK: TProgressBar
    Left = 16
    Top = 512
    Width = 633
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 2
  end
  object csik: TProgressBar
    Left = 16
    Top = 488
    Width = 633
    Height = 17
    Min = 0
    Max = 8
    Smooth = True
    TabOrder = 3
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = INDITOTimer
    Left = 8
    Top = 8
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 464
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 464
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
    Left = 80
    Top = 464
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 112
    Top = 464
  end
  object V2QUERY: TIBQuery
    Database = V2DBASE
    Transaction = V2TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 496
  end
  object V2DBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = V2TRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 496
  end
  object V2TRANZ: TIBTransaction
    Active = False
    DefaultDatabase = V2DBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 112
    Top = 496
  end
  object TRANZQUERY: TIBQuery
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 504
  end
  object TRANZTABLA: TIBTable
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 480
    Top = 504
  end
  object TRANZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TRANZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 544
    Top = 504
  end
  object TRANZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRANZDBASE
    AutoStopAction = saNone
    Left = 576
    Top = 504
  end
  object BESZTABLA: TIBTable
    Database = BESZDBASE
    Transaction = BESZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 8
  end
  object BESZQUERY: TIBQuery
    Database = BESZDBASE
    Transaction = BESZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 544
    Top = 8
  end
  object BESZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\BESZAMOLO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BESZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 576
    Top = 8
  end
  object BESZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BESZDBASE
    AutoStopAction = saNone
    Left = 608
    Top = 8
  end
end
