object CIMLETMENU: TCIMLETMENU
  Left = 366
  Top = 284
  BorderStyle = bsNone
  Caption = 'CIMLETMENU'
  ClientHeight = 422
  ClientWidth = 542
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
    Width = 542
    Height = 422
    Align = alClient
    Brush.Color = clBtnFace
    Pen.Width = 3
  end
  object Label1: TLabel
    Left = 64
    Top = -8
    Width = 423
    Height = 108
    Caption = 'C'#237'mletez'#233's'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KILEPGOMB: TButton
    Left = 136
    Top = 384
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
    OnClick = KILEPGOMBClick
  end
  object PTZARGOMB: TBitBtn
    Tag = 1
    Left = 88
    Top = 136
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = 'ESTI Z'#193'R'#193'S C'#205'MLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = PTZARGOMBClick
  end
  object KEZDIJGOMB: TBitBtn
    Tag = 2
    Left = 88
    Top = 168
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = 'KEZEL'#201'SI D'#205'J C'#205'MLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = PTZARGOMBClick
  end
  object WUGOMB: TBitBtn
    Tag = 3
    Left = 88
    Top = 200
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = 'WESTERN UNION C'#205'MLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = PTZARGOMBClick
  end
  object AFAGOMB: TBitBtn
    Tag = 4
    Left = 88
    Top = 232
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = #193'FA P'#201'NZT'#193'R C'#205'MLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = PTZARGOMBClick
  end
  object FOGLALOGOMB: TBitBtn
    Tag = 5
    Left = 88
    Top = 264
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = 'FOGLAL'#211' K'#201'SZLET C'#205'MLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = PTZARGOMBClick
  end
  object ETRADEGOMB: TBitBtn
    Tag = 6
    Left = 88
    Top = 296
    Width = 377
    Height = 25
    Cursor = crHandPoint
    Caption = 'ELEKTROMOS KERESKED'#201'S CIMLETEZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = PTZARGOMBClick
  end
  object QUITGOMB: TBitBtn
    Left = 288
    Top = 384
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
    OnClick = QUITGOMBClick
  end
  object VALQuery: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
  object EQUERY: TIBQuery
    Database = EDBASE
    Transaction = ETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 384
  end
  object EDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 384
  end
  object ETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = EDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 384
  end
  object AXAQUERY: TIBQuery
    Database = AXADBASE
    Transaction = AXATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 424
    Top = 384
  end
  object AXADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\AXA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = AXATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 456
    Top = 384
  end
  object AXATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = AXADBASE
    AutoStopAction = saNone
    Left = 488
    Top = 384
  end
end
