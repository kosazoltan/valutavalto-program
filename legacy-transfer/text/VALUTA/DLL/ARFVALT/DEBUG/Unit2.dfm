object ARFOLYAMVALTOZTATAS: TARFOLYAMVALTOZTATAS
  Left = 358
  Top = 182
  BorderIcons = []
  BorderStyle = bsNone
  Caption = #193'rfolyamkedvezm'#233'ny be'#225'llit'#225'sa ...'
  ClientHeight = 270
  ClientWidth = 411
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
  object Panel2: TPanel
    Left = 5
    Top = 5
    Width = 401
    Height = 260
    BevelInner = bvRaised
    Color = clWhite
    TabOrder = 0
    object Label2: TLabel
      Left = 112
      Top = 75
      Width = 153
      Height = 24
      Caption = 'Eredeti '#225'rfolyam:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 56
      Top = 112
      Width = 213
      Height = 24
      Caption = 'Kedvezm'#233'nyes '#225'rfolyam:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object VALUTANEVPANEL: TPanel
      Left = 0
      Top = 32
      Width = 393
      Height = 25
      BevelOuter = bvNone
      Caption = 'KANADAI DOLL'#193'R'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object ALAPARFOLYAMPANEL: TPanel
      Left = 280
      Top = 72
      Width = 73
      Height = 33
      BevelOuter = bvNone
      Caption = '25500'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel7: TPanel
      Left = 8
      Top = 0
      Width = 385
      Height = 33
      BevelOuter = bvNone
      Caption = 'KEDVEZM'#201'NYES '#193'RFOLYAM'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object UJARFOLYAMEDIT: TEdit
      Left = 283
      Top = 112
      Width = 65
      Height = 36
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      Text = '26500'
      OnEnter = UJARFOLYAMEDITEnter
      OnExit = UJARFOLYAMEDITExit
      OnKeyDown = UJARFOLYAMEDITKeyDown
    end
    object ARFMODIOKEGOMB: TBitBtn
      Left = 16
      Top = 216
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J '#193'RFOLYAM RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = ARFMODIOKEGOMBClick
    end
    object ARFMODICANCELGOMB: TBitBtn
      Left = 208
      Top = 216
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM AD KEDVEZM'#201'NYT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = ARFMODICANCELGOMBClick
    end
    object SZAZALEKPANEL: TPanel
      Left = 275
      Top = 160
      Width = 73
      Height = 33
      BevelOuter = bvNone
      Caption = '1,98 %)'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 6
      Visible = False
    end
    object KEDVTEXTPANEL: TPanel
      Left = 85
      Top = 155
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Caption = '(Kedvezm'#233'ny sz'#225'zal'#233'ka:'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      Visible = False
    end
    object ENGEDELYGOMB: TBitBtn
      Left = 40
      Top = 160
      Width = 329
      Height = 33
      Cursor = crHandPoint
      Caption = 'ENGED'#201'LY K'#201'R'#201'SE'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 8
      OnClick = ENGEDELYGOMBClick
    end
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 8
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 40
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 16
    Top = 72
  end
end
