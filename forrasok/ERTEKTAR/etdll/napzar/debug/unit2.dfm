object NAPZARFORM: TNAPZARFORM
  Left = 349
  Top = 125
  AlphaBlendValue = 180
  BorderStyle = bsNone
  ClientHeight = 504
  ClientWidth = 578
  Color = 3289650
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
    Left = 104
    Top = 8
    Width = 331
    Height = 36
    Caption = 'NAPI P'#201'NZT'#193'RZ'#193'R'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object DATUMPANEL: TPanel
    Left = 8
    Top = 40
    Width = 553
    Height = 41
    BevelOuter = bvNone
    Caption = '2017.05.22'
    Color = 3289650
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object ELLENORPANEL: TPanel
    Left = 20
    Top = 88
    Width = 513
    Height = 361
    TabOrder = 1
    Visible = False
    object Shape3: TShape
      Left = 1
      Top = 1
      Width = 511
      Height = 359
      Align = alClient
      Brush.Color = clMedGray
      Pen.Color = clWhite
      Pen.Width = 5
    end
    object Shape1: TShape
      Left = 24
      Top = 104
      Width = 473
      Height = 153
      Pen.Width = 2
    end
    object Shape2: TShape
      Left = 96
      Top = 32
      Width = 353
      Height = 41
      Brush.Color = clBtnFace
      Pen.Width = 3
    end
    object E1: TPanel
      Left = 40
      Top = 108
      Width = 288
      Height = 28
      Caption = 'P'#233'nzt'#225'rz'#225'r'#225's c'#237'mletez'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object E2: TPanel
      Left = 40
      Top = 136
      Width = 288
      Height = 28
      Caption = 'Kezel'#233'si d'#237'j ellen'#337'rz'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object E3: TPanel
      Left = 40
      Top = 164
      Width = 288
      Height = 28
      Caption = 'W.U. c'#237'mletez'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object E4: TPanel
      Left = 40
      Top = 192
      Width = 288
      Height = 28
      Caption = #193'FA p'#233'nzt'#225'r c'#237'mletez'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object V1: TPanel
      Left = 336
      Top = 108
      Width = 144
      Height = 28
      Caption = 'V1'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object V2: TPanel
      Left = 336
      Top = 136
      Width = 144
      Height = 28
      Caption = 'V2'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object V3: TPanel
      Left = 336
      Top = 164
      Width = 144
      Height = 28
      Caption = 'V3'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
    end
    object V4: TPanel
      Left = 336
      Top = 192
      Width = 144
      Height = 28
      Caption = 'V4'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object Panel1: TPanel
      Left = 104
      Top = 36
      Width = 337
      Height = 33
      BevelOuter = bvNone
      Caption = 'Napi z'#225'r'#225's el'#246'tti ellen'#337'rz'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
    end
    object RENDBENPANEL: TPanel
      Left = 40
      Top = 288
      Width = 457
      Height = 33
      BevelOuter = bvNone
      Caption = 'Ellen'#337'rz'#233'se rendben. Napz'#225'r'#225's indulhat'
      Color = 52634403
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 9
      Visible = False
    end
    object v5: TPanel
      Left = 336
      Top = 220
      Width = 144
      Height = 28
      HelpContext = 25
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 10
    end
    object E5: TPanel
      Left = 40
      Top = 220
      Width = 289
      Height = 28
      Caption = 'E-kereskedelem c'#237'mletez'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 11
    end
  end
  object ZARASMENETPANEL: TPanel
    Left = -2200
    Top = 64
    Width = 553
    Height = 409
    TabOrder = 2
    object Shape4: TShape
      Left = 8
      Top = 24
      Width = 537
      Height = 352
      Brush.Color = 11599871
      Pen.Color = clGray
      Pen.Width = 5
    end
    object Memo1: TMemo
      Left = 32
      Top = 40
      Width = 489
      Height = 281
      BorderStyle = bsNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        'Memo1')
      ParentFont = False
      TabOrder = 0
    end
    object ZOKEGOMB: TBitBtn
      Left = 32
      Top = 336
      Width = 497
      Height = 25
      Cursor = crHandPoint
      Caption = 'A NAPI Z'#193'R'#193'S RENDBEN V'#201'GREHAJTVA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      Visible = False
      OnClick = ZOKEGOMBClick
    end
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 50
    OnTimer = INDITOTimer
    Left = 8
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 48
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
    Left = 72
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 104
    Top = 48
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 448
    Top = 48
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
    Left = 480
    Top = 48
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 512
    Top = 48
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 416
    Top = 48
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 48
  end
  object SOURCEQUERY: TIBQuery
    Database = SOURCEDBASE
    Transaction = SOURCETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 448
    Top = 16
  end
  object SOURCEDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SOURCETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 480
    Top = 16
  end
  object SOURCETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SOURCEDBASE
    AutoStopAction = saNone
    Left = 512
    Top = 16
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 112
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
    Left = 40
    Top = 144
  end
  object HRKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HRKDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 144
  end
end
