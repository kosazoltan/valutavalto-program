object GETELLENOR: TGETELLENOR
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETELLENOR'
  ClientHeight = 266
  ClientWidth = 616
  Color = clWhite
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
    Width = 616
    Height = 266
    Align = alClient
    Brush.Color = clSkyBlue
    Pen.Width = 4
  end
  object Label1: TLabel
    Left = 48
    Top = 32
    Width = 528
    Height = 33
    Caption = 'Z'#193'R'#193'ST ELLEN'#214'RZ'#214' SZEM'#201'LY ADATAI'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object TLabel
    Left = 139
    Top = 120
    Width = 52
    Height = 21
    Caption = 'NEVE:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 80
    Top = 168
    Width = 112
    Height = 21
    Caption = 'BEOSZT'#193'SA:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 224
    Top = 64
    Width = 180
    Height = 16
    Caption = '( A z'#225'r'#243'szalagot k'#233'rem al'#225'irni)'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object BEOEDIT: TEdit
    Left = 216
    Top = 168
    Width = 361
    Height = 24
    CharCase = ecUpperCase
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Text = 'BEOEDIT'
    OnEnter = NEVEDITEnter
    OnExit = NEVEDITExit
    OnKeyDown = BEOEDITKeyDown
  end
  object RENDBENGOMB: TBitBtn
    Left = 56
    Top = 216
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'ELLEN'#214'RZ'#214' SZEM'#201'LY ADATAI RENDBEN'
    TabOrder = 1
    OnClick = RENDBENGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 336
    Top = 216
    Width = 241
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM Z'#193'ROM A NAPOT'
    TabOrder = 2
    OnClick = MEGSEMGOMBClick
  end
  object NEVEDIT: TEdit
    Left = 216
    Top = 120
    Width = 361
    Height = 24
    CharCase = ecUpperCase
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    Text = 'NEVEDIT'
    OnEnter = NEVEDITEnter
    OnExit = NEVEDITExit
    OnKeyDown = NEVEDITKeyDown
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 80
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 80
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 80
  end
end
