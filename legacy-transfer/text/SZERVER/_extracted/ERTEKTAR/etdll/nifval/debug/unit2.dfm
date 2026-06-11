object NIFFILEVALASZTO: TNIFFILEVALASZTO
  Left = 192
  Top = 114
  BorderIcons = []
  BorderStyle = bsSingle
  ClientHeight = 466
  ClientWidth = 673
  Color = clRed
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
    Left = 64
    Top = 16
    Width = 560
    Height = 33
    Caption = 'V'#193'LASSZA KI A KIV'#193'NT NAPI JELENT'#201'ST'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KIVALASZTOGOMB: TBitBtn
    Left = 264
    Top = 392
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'V'#193'LASZT'#193'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = VALASZTOLISTADblClick
  end
  object VALASZTOLISTA: TListBox
    Left = 24
    Top = 56
    Width = 625
    Height = 321
    Cursor = crHandPoint
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 21
    ParentFont = False
    TabOrder = 0
    OnDblClick = VALASZTOLISTADblClick
    OnKeyDown = VALASZTOLISTAKeyDown
  end
  object ESCAPEGOMB: TBitBtn
    Left = 496
    Top = 392
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A F'#336'MEN'#220'RE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = EscapeGombClick
  end
  object FRISSITOGOMB: TBitBtn
    Left = 24
    Top = 392
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'FRISSIT'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = FRISSITOGOMBClick
  end
  object MemoTabla: TMemo
    Left = 24
    Top = 16
    Width = 625
    Height = 361
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = 16756991
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 3
  end
  object FILELISTA: TListBox
    Left = 344
    Top = 40
    Width = 201
    Height = 297
    BorderStyle = bsNone
    Color = 16756991
    ItemHeight = 13
    TabOrder = 5
    Visible = False
  end
  object CSIK: TProgressBar
    Left = 24
    Top = 424
    Width = 625
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 6
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 2300
    OnTimer = KILEPOTIMERTimer
    Left = 40
    Top = 32
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 32
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\valuta.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 32
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 32
  end
end
