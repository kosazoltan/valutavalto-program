object Form1: TForm1
  Left = 192
  Top = 114
  Width = 868
  Height = 530
  Caption = #711#711
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
  object Label1: TLabel
    Left = 88
    Top = 32
    Width = 528
    Height = 33
    Caption = 'A KEZEL'#201'SI K'#214'LTS'#201'GEK KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object MENUPANEL: TPanel
    Left = -56
    Top = 320
    Width = 473
    Height = 153
    BevelOuter = bvNone
    TabOrder = 0
    object Shape2: TShape
      Left = 16
      Top = 24
      Width = 441
      Height = 105
      Shape = stRoundRect
    end
    object EGYNAPBEGOMB: TBitBtn
      Left = 24
      Top = 32
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY NAP BEDOLGOZ'#193'SA A NYILV'#193'NTART'#193'SBA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = EGYNAPBEGOMBClick
    end
    object BitBtn7: TBitBtn
      Left = 24
      Top = 64
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY H'#211'NAP ADATAINAK EXCELT'#193'BL'#193'BA T'#214'LT'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn7Click
    end
    object BitBtn8: TBitBtn
      Left = 24
      Top = 96
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = BitBtn8Click
    end
  end
  object naptarpanel: TPanel
    Left = 366
    Top = -34
    Width = 489
    Height = 329
    BevelOuter = bvNone
    TabOrder = 1
    object Label2: TLabel
      Left = 64
      Top = 24
      Width = 380
      Height = 23
      Caption = 'V'#193'LASSZA KI A BEDOLGOZAND'#211' NAPOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Shape1: TShape
      Left = 72
      Top = 120
      Width = 345
      Height = 153
      Brush.Color = 11599871
      Pen.Width = 2
      Shape = stRoundRect
    end
    object NAPTAR: TCalendar
      Left = 88
      Top = 144
      Width = 320
      Height = 120
      BorderStyle = bsNone
      Color = 11599871
      StartOfWeek = 0
      TabOrder = 0
    end
    object EVPANEL: TPanel
      Left = 208
      Top = 56
      Width = 65
      Height = 33
      BevelOuter = bvNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object HONAPPANEL: TPanel
      Left = 168
      Top = 96
      Width = 137
      Height = 33
      BevelOuter = bvNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object ELOHOGOMB: TBitBtn
      Left = 80
      Top = 104
      Width = 89
      Height = 25
      Cursor = crHandPoint
      Caption = '<< el'#246'z'#337' h'#243
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ELOHOGOMBClick
    end
    object KOVHOGOMB: TBitBtn
      Left = 304
      Top = 104
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Caption = 'k'#246'vetkez'#337' h'#243'>>'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = KOVHOGOMBClick
    end
    object DATUMOKEGOMB: TBitBtn
      Left = 72
      Top = 280
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#225'tum rendben'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = DATUMOKEGOMBClick
    end
    object DATUMMEGSEMGOMB: TBitBtn
      Left = 272
      Top = 280
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = DATUMMEGSEMGOMBClick
    end
  end
  object UZENOPANEL: TPanel
    Left = 168
    Top = 296
    Width = 465
    Height = 385
    BevelOuter = bvNone
    TabOrder = 2
    object Label3: TLabel
      Left = 64
      Top = 8
      Width = 320
      Height = 33
      Caption = 'A PROGRAM '#220'ZENETEI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object MEMOPANEL: TPanel
      Left = 40
      Top = 56
      Width = 385
      Height = 265
      BevelOuter = bvNone
      Color = 11599871
      TabOrder = 0
      object Memo1: TMemo
        Left = 16
        Top = 24
        Width = 345
        Height = 233
        BorderStyle = bsNone
        Color = 11599871
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 0
      end
    end
    object visszagomb: TBitBtn
      Left = 176
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 1
      OnClick = visszagombClick
    end
  end
  object LOGOPANEL: TPanel
    Left = 536
    Top = 416
    Width = 129
    Height = 57
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    object Shape3: TShape
      Left = 8
      Top = 8
      Width = 113
      Height = 41
      Shape = stEllipse
    end
    object Label4: TLabel
      Left = 24
      Top = 18
      Width = 83
      Height = 21
      Caption = 'dekanySoft'
      Transparent = True
    end
  end
  object HONAPKEROPANEL: TPanel
    Left = 176
    Top = 104
    Width = 385
    Height = 177
    BevelOuter = bvNone
    TabOrder = 4
    object Shape4: TShape
      Left = 40
      Top = 48
      Width = 305
      Height = 97
      Pen.Width = 2
      Shape = stRoundRect
    end
    object EVCOMBO: TComboBox
      Left = 88
      Top = 72
      Width = 81
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      Text = '2012'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 176
      Top = 72
      Width = 137
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 1
      Text = 'szeptember'
      OnChange = EVCOMBOChange
    end
    object hookegomb: TBitBtn
      Left = 72
      Top = 128
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'H'#211'NAP RENDBEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = hookegombClick
    end
    object homegsemgomb: TBitBtn
      Left = 208
      Top = 128
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = homegsemgombClick
    end
    object Panel1: TPanel
      Left = 56
      Top = 32
      Width = 273
      Height = 33
      BevelOuter = bvNone
      Caption = 'V'#225'lassza ki a kiv'#225'nt h'#243'napot'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
    end
  end
  object DAYBQUERY: TIBQuery
    Database = DAYBDBASE
    Transaction = DAYBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
    Top = 128
  end
  object DAYBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = DAYBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 160
  end
  object DAYBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 192
  end
  object BFTABLA: TIBTable
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 128
  end
  object BFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 224
  end
  object BFDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 160
  end
  object BFQUERY: TIBQuery
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 192
  end
  object KEZDQUERY: TIBQuery
    Database = KEZDDBASE
    Transaction = KEZDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
    Top = 64
  end
  object KEZDDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KEZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = KEZDTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 96
  end
  object KEZDTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KEZDDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 96
  end
  object KEZDTABLA: TIBTable
    Database = KEZDDBASE
    Transaction = KEZDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 64
  end
  object DAYBTABLA: TIBTable
    Database = DAYBDBASE
    Transaction = DAYBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 224
  end
end
