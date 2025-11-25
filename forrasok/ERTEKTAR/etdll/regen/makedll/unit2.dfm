object REGENERALO: TREGENERALO
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'B'
  ClientHeight = 313
  ClientWidth = 536
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 537
    Height = 313
    BevelOuter = bvNone
    Color = 10726813
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 537
      Height = 313
      Align = alClient
      Brush.Color = 4473924
      Pen.Color = clWhite
      Pen.Width = 6
    end
    object Label1: TLabel
      Left = 32
      Top = 16
      Width = 475
      Height = 55
      Caption = 'A PILLANATNYI '#193'LL'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -48
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 72
      Top = 72
      Width = 422
      Height = 34
      Caption = 'KEZEL'#201'SI D'#205'J -WESTERN UNION'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 64
      Top = 112
      Width = 424
      Height = 34
      Caption = 'E-KERESKEDELEM-AFAK'#201'SZLET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 152
      Top = 152
      Width = 253
      Height = 41
      Caption = 'REGENER'#193'L'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape2: TShape
      Left = 32
      Top = 200
      Width = 473
      Height = 89
      Brush.Color = 8947848
      Pen.Color = clWhite
      Pen.Width = 3
      Shape = stRoundRect
    end
    object CSIK: TProgressBar
      Left = 40
      Top = 206
      Width = 457
      Height = 22
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 0
    end
    object FASTCSIK: TProgressBar
      Left = 40
      Top = 260
      Width = 457
      Height = 22
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 1
    end
    object regeninfopanel: TPanel
      Left = 40
      Top = 232
      Width = 457
      Height = 25
      BevelOuter = bvNone
      Color = 8947848
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object IDOZITO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = IdozitoTimer
    Left = 136
    Top = 8
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
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
    Top = 8
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
    Top = 8
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 160
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 160
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 160
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    AutoStopAction = saNone
    Left = 104
    Top = 160
  end
end
