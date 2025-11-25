object GETTANUSITVANY: TGETTANUSITVANY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETTANUSITVANY'
  ClientHeight = 281
  ClientWidth = 599
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 601
    Height = 281
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 585
      Height = 265
      Brush.Color = 41072
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 48
      Top = 40
      Width = 514
      Height = 36
      Caption = 'K'#201'REM A TANUSITV'#193'NY ADATAIT:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 160
      Top = 104
      Width = 144
      Height = 24
      Caption = 'TERMIN'#193'L ID:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 88
      Top = 144
      Width = 213
      Height = 24
      Caption = 'FELHASZN'#193'L'#211'I N'#201'V:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 56
      Top = 184
      Width = 250
      Height = 24
      Caption = 'FELHASZN'#193'L'#211'I JELSZ'#211':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object TERMINALIDEDIT: TEdit
      Left = 312
      Top = 96
      Width = 65
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      TabOrder = 0
      Text = '1699'
      OnEnter = TERMINALIDEDITEnter
      OnExit = TERMINALIDEDITExit
      OnKeyDown = TERMINALIDEDITKeyDown
    end
    object USERNAMEEDIT: TEdit
      Left = 312
      Top = 136
      Width = 241
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 15
      ParentFont = False
      TabOrder = 1
      Text = 'wwwwwwwwwwwwwwx'
      OnEnter = TERMINALIDEDITEnter
      OnExit = TERMINALIDEDITExit
      OnKeyDown = USERNAMEEDITKeyDown
    end
    object PASSWORDEDIT: TEdit
      Left = 312
      Top = 176
      Width = 241
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 15
      ParentFont = False
      TabOrder = 2
      Text = 'edit3'
      OnEnter = TERMINALIDEDITEnter
      OnExit = TERMINALIDEDITExit
      OnKeyDown = PASSWORDEDITKeyDown
    end
    object dataokegomb: TBitBtn
      Left = 144
      Top = 224
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK RENDBEN'
      TabOrder = 3
      OnClick = dataokegombClick
    end
    object cancelgomb: TBitBtn
      Left = 328
      Top = 224
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'MOST NEM ADOM MEG'
      TabOrder = 4
      OnClick = cancelgombClick
    end
  end
  object IBQuery: TIBQuery
    Database = IBDbase
    Transaction = IBTranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 208
  end
  object IBDbase: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 208
  end
  object IBTranz: TIBTransaction
    Active = False
    DefaultDatabase = IBDbase
    AutoStopAction = saNone
    Left = 72
    Top = 208
  end
end
