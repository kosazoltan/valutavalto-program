object NAPIKONYV: TNAPIKONYV
  Left = 193
  Top = 115
  BorderStyle = bsNone
  ClientHeight = 570
  ClientWidth = 850
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape4: TShape
    Left = 0
    Top = 0
    Width = 850
    Height = 570
    Align = alClient
    Brush.Color = clRed
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Label3: TLabel
    Left = 64
    Top = 56
    Width = 718
    Height = 33
    Caption = #201'RT'#201'KT'#193'RI FORGALOM NAPI K'#214'NYVEL'#201'SI LIST'#193'JA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 256
    Top = 208
    Width = 353
    Height = 169
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label4: TLabel
    Left = 248
    Top = 104
    Width = 385
    Height = 31
    Caption = 'V'#225'lassza ki a nyomtatand'#243' napot '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Shape3: TShape
    Left = 264
    Top = 424
    Width = 329
    Height = 73
    Brush.Color = 11599871
    Shape = stRoundRect
  end
  object NYOMTATOGOMB: TBitBtn
    Left = 272
    Top = 432
    Width = 313
    Height = 25
    Cursor = crHandPoint
    Caption = 'Napi k'#246'nyvel'#233's nyomtat'#225'sa'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = NYOMTATOGOMBClick
  end
  object VISSZAGOMB: TBitBtn
    Left = 272
    Top = 464
    Width = 313
    Height = 25
    Cursor = crHandPoint
    Caption = 'Vissza a f'#337'men'#252're'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = VISSZAGOMBClick
  end
  object ELOHOGOMB: TBitBtn
    Left = 288
    Top = 365
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'El'#246'z'#337' h'#243'nap'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = elohogombClick
  end
  object KOVHOGOMB: TBitBtn
    Left = 440
    Top = 365
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'K'#246'vetkez'#337' h'#243'nap'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = kovhogombClick
  end
  object EVPANEL: TPanel
    Left = 200
    Top = 160
    Width = 73
    Height = 28
    Caption = '2013'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
  end
  object HONAPPANEL: TPanel
    Left = 280
    Top = 160
    Width = 129
    Height = 28
    Caption = 'szeptember'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object DAYPANEL: TPanel
    Left = 416
    Top = 160
    Width = 57
    Height = 28
    Caption = '25'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
  end
  object NAPNEVPANEL: TPanel
    Left = 480
    Top = 160
    Width = 145
    Height = 28
    Caption = 'cs'#252't'#246'rt'#246'k'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
  end
  object NAPTAR: TCalendar
    Left = 272
    Top = 232
    Width = 320
    Height = 120
    BorderStyle = bsNone
    Color = clYellow
    StartOfWeek = 0
    TabOrder = 8
    OnChange = NAPTARChange
  end
  object CEGNEVPANEL: TPanel
    Left = 24
    Top = 16
    Width = 793
    Height = 41
    BevelOuter = bvNone
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 344
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
    Left = 80
    Top = 344
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 112
    Top = 344
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 384
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 384
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
    Left = 80
    Top = 384
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 112
    Top = 384
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTIMERTimer
    Left = 48
    Top = 160
  end
  object PrintDialog1: TPrintDialog
    Left = 16
    Top = 160
  end
end
