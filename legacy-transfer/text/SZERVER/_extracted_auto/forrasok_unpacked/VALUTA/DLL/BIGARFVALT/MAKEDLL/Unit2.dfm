object Form2: TForm2
  Left = 193
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 421
  ClientWidth = 557
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
  object ALAPLAP: TPanel
    Left = 0
    Top = 0
    Width = 553
    Height = 417
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 553
      Height = 417
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 64
      Top = 32
      Width = 446
      Height = 27
      Caption = #193'RFOLYAM KEDVEZM'#201'NY  AD'#193'SA'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object ARFNEVLABEL: TLabel
      Left = 176
      Top = 136
      Width = 181
      Height = 21
      Caption = '.V'#201'TELI '#193'RFOLYAM: '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 112
      Top = 200
      Width = 254
      Height = 21
      Caption = 'KEDVEZM'#201'NYES '#193'RFOLYAM:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 128
      Top = 168
      Width = 235
      Height = 21
      Caption = 'ELSZ'#193'MOL'#193'SI '#193'RFOLYAM: '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 128
      Top = 232
      Width = 237
      Height = 21
      Caption = 'KEDVEZM'#201'NY SZ'#193'ZAL'#201'KA:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object VALUTANEVPANEL: TPanel
      Left = 48
      Top = 72
      Width = 473
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object AKTARFOLYAMPANEL: TPanel
      Left = 368
      Top = 136
      Width = 73
      Height = 22
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = HEBREW_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object KEDVARFOLYAMEDIT: TEdit
      Left = 376
      Top = 200
      Width = 65
      Height = 22
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 5
      ParentFont = False
      TabOrder = 2
      OnEnter = KEDVARFOLYAMEDITEnter
      OnExit = KEDVARFOLYAMEDITExit
      OnKeyDown = KEDVARFOLYAMEDITKeyDown
    end
    object ELSZAMOLOPANEL: TPanel
      Left = 368
      Top = 168
      Width = 73
      Height = 22
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object JELSZOKEROGOMB: TBitBtn
      Left = 192
      Top = 320
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'JELSZ'#211' BEK'#201'R'#201'SE'
      Enabled = False
      TabOrder = 4
      OnClick = JELSZOKEROGOMBClick
    end
    object ENGEDELYGOMB: TBitBtn
      Left = 56
      Top = 352
      Width = 217
      Height = 25
      Cursor = crHandPoint
      Caption = 'ENGED'#201'LYEZEM A KEDVEZM'#201'NYT'
      Enabled = False
      TabOrder = 5
      OnClick = ENGEDELYGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 280
      Top = 352
      Width = 217
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM ADOK KEDVEZM'#201'NYT'
      TabOrder = 6
      OnClick = MEGSEMGOMBClick
    end
    object UZENOPANEL: TPanel
      Left = 48
      Top = 280
      Width = 473
      Height = 21
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object SZAZALEKPANEL: TPanel
      Left = 376
      Top = 232
      Width = 65
      Height = 22
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object fuggony: TPanel
      Left = -1897
      Top = 64
      Width = 513
      Height = 201
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 9
    end
  end
  object BIGPERCENTPANEL: TPanel
    Left = -1897
    Top = 10
    Width = 497
    Height = 115
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 1
    Visible = False
    object Label2: TLabel
      Left = 56
      Top = 32
      Width = 388
      Height = 24
      Caption = 'MAGAS KEDVEZM'#201'NY-SZ'#193'ZAL'#201'K '#39
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 40
      Top = 72
      Width = 407
      Height = 24
      Caption = 'JELSZAVAS MEGER'#336'SIT'#201'S SZ'#220'KS'#201'GES !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object KQUERY: TIBQuery
    Database = KDBASE
    Transaction = KTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 320
  end
  object KDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 320
  end
  object KTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 320
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 144
    Top = 320
  end
end
