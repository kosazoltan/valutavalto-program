object Form1: TForm1
  Left = 190
  Top = 111
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 740
  ClientWidth = 1014
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 1014
    Height = 740
    Align = alClient
    Brush.Color = clTeal
    Pen.Color = clWhite
    Pen.Width = 8
  end
  object Shape3: TShape
    Left = 808
    Top = 648
    Width = 145
    Height = 49
    Pen.Width = 2
    Shape = stEllipse
  end
  object Shape1: TShape
    Left = 256
    Top = 288
    Width = 537
    Height = 225
    Shape = stRoundRect
  end
  object Label3: TLabel
    Left = 824
    Top = 656
    Width = 111
    Height = 28
    Caption = 'dekanySoft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label4: TLabel
    Left = 56
    Top = 40
    Width = 145
    Height = 33
    Caption = '18.50 verzi'#243
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape4: TShape
    Left = 312
    Top = 488
    Width = 449
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape5: TShape
    Left = 64
    Top = 642
    Width = 177
    Height = 35
    Shape = stRoundRect
  end
  object TELEFONGOMB: TBitBtn
    Left = 272
    Top = 296
    Width = 505
    Height = 41
    Cursor = crHandPoint
    Caption = 'TELEFON FELT'#214'LT'#336
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = TelefonGombClick
    OnEnter = TELEFONGOMBEnter
    OnExit = TELEFONGOMBExit
    OnMouseMove = TELEFONGOMBMouseMove
  end
  object MATRICAGOMB: TBitBtn
    Left = 272
    Top = 344
    Width = 505
    Height = 41
    Cursor = crHandPoint
    Caption = 'AUT'#211'P'#193'LYA MATRICA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = MatricaGombClick
    OnEnter = TELEFONGOMBEnter
    OnExit = TELEFONGOMBExit
    OnMouseMove = TELEFONGOMBMouseMove
  end
  object KILEPESGOMB: TBitBtn
    Left = 272
    Top = 440
    Width = 505
    Height = 41
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = KilepesGombClick
    OnEnter = TELEFONGOMBEnter
    OnExit = TELEFONGOMBExit
    OnMouseMove = TELEFONGOMBMouseMove
  end
  object LISTAGOMB: TBitBtn
    Left = 272
    Top = 392
    Width = 505
    Height = 41
    Cursor = crHandPoint
    Caption = 'FELAD'#193'S  '#201'S  LIST'#193'K'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = LISTAGOMBClick
    OnEnter = TELEFONGOMBEnter
    OnExit = TELEFONGOMBExit
    OnMouseMove = TELEFONGOMBMouseMove
  end
  object KFTNEVPANEL: TPanel
    Left = 104
    Top = 120
    Width = 817
    Height = 81
    BevelOuter = bvNone
    Caption = 'Exclusive Change'
    Color = clTeal
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -64
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object CSIK: TProgressBar
    Left = 120
    Top = 210
    Width = 769
    Height = 5
    Min = 0
    Max = 123
    Smooth = True
    TabOrder = 5
  end
  object TANUSITVANYGOMB: TBitBtn
    Left = 320
    Top = 496
    Width = 433
    Height = 33
    Cursor = crHandPoint
    Caption = 'TANUSITV'#193'NY BE'#193'LLIT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
    OnClick = TANUSITVANYGOMBClick
  end
  object BitBtn1: TBitBtn
    Left = 72
    Top = 648
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'LOG OLVAS'#193'S'
    TabOrder = 7
    OnClick = BitBtn1Click
  end
  object FUGGONY: TPanel
    Left = -864
    Top = 72
    Width = 945
    Height = 625
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 8
    object Label2: TLabel
      Left = 144
      Top = 88
      Width = 642
      Height = 72
      Caption = 'Elektronikus keresked'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -64
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 392
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 392
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 112
    Top = 392
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 50
    OnTimer = KILEPOTIMERTimer
    Left = 80
    Top = 312
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 360
  end
  object TRADEDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 360
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 360
  end
  object TRADETABLA: TIBTable
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 360
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 300
    OnTimer = INDITOTimer
    Left = 48
    Top = 312
  end
end
