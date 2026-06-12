object PTARKESZ: TPTARKESZ
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'PTARKESZ'
  ClientHeight = 738
  ClientWidth = 478
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 480
    Height = 737
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 480
      Height = 737
      Align = alClient
      Brush.Color = clAqua
      Brush.Style = bsDiagCross
      Pen.Width = 4
    end
    object Panel2: TPanel
      Left = 24
      Top = 16
      Width = 433
      Height = 41
      BevelOuter = bvNone
      Caption = 'Az '#233'rt'#233'kt'#225'r k'#233'szletei '
      Color = 3289650
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel3: TPanel
      Left = 48
      Top = 64
      Width = 201
      Height = 25
      Caption = 'Forint k'#233'szlet:'
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel4: TPanel
      Left = 48
      Top = 96
      Width = 201
      Height = 25
      Caption = 'Valut'#225'k forint'#233'rt'#233'ke:'
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object Panel5: TPanel
      Left = 16
      Top = 168
      Width = 449
      Height = 4
      Color = clBlack
      TabOrder = 3
    end
    object FTKESZLET: TPanel
      Left = 256
      Top = 64
      Width = 185
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object VALUTAKESZLET: TPanel
      Left = 256
      Top = 96
      Width = 185
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object Panel8: TPanel
      Left = 40
      Top = 184
      Width = 417
      Height = 33
      Caption = 'Western Union'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 6
    end
    object Panel9: TPanel
      Left = 72
      Top = 248
      Width = 49
      Height = 25
      Caption = 'USD'
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object WUUSDKESZLET: TPanel
      Left = 136
      Top = 248
      Width = 121
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 8
    end
    object Panel11: TPanel
      Left = 72
      Top = 288
      Width = 49
      Height = 25
      Caption = 'HUF'
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object WUHUFKESZLET: TPanel
      Left = 136
      Top = 288
      Width = 121
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 10
    end
    object Panel13: TPanel
      Left = 32
      Top = 344
      Width = 417
      Height = 33
      Caption = #193'fa p'#233'nzt'#225'r'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 11
    end
    object AFAKESZLET: TPanel
      Left = 160
      Top = 408
      Width = 185
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 12
    end
    object Panel15: TPanel
      Left = 32
      Top = 472
      Width = 417
      Height = 33
      Caption = 'Elektromos keresked'#233's'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 13
    end
    object TRADEKESZLET: TPanel
      Left = 160
      Top = 528
      Width = 185
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 14
    end
    object Panel17: TPanel
      Left = 8
      Top = 576
      Width = 465
      Height = 8
      Color = clBlack
      TabOrder = 15
    end
    object Panel18: TPanel
      Left = 24
      Top = 600
      Width = 433
      Height = 33
      Caption = 'TELJES P'#201'NZT'#193'RK'#201'SZLET '#201'RT'#201'KE'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 16
    end
    object SUMKESZLET: TPanel
      Left = 136
      Top = 648
      Width = 233
      Height = 25
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 17
    end
    object VISSZAGOMB: TBitBtn
      Left = 184
      Top = 688
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 18
      OnClick = VisszaGombClick
    end
    object Panel1: TPanel
      Left = 48
      Top = 128
      Width = 201
      Height = 25
      Caption = 'Kezel'#233'si d'#237'j'
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 19
    end
    object KEZELESIDIJ: TPanel
      Left = 256
      Top = 128
      Width = 185
      Height = 25
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 20
    end
    object WUSDFORINT: TPanel
      Left = 264
      Top = 248
      Width = 177
      Height = 25
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 21
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 520
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
    Left = 48
    Top = 520
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 80
    Top = 528
  end
  object BELEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Start
    Left = 384
    Top = 296
  end
end
