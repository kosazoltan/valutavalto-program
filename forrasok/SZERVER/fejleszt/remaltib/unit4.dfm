object ZAPPOLOFORM: TZAPPOLOFORM
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 220
  BorderStyle = bsNone
  ClientHeight = 266
  ClientWidth = 668
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
    Width = 665
    Height = 265
    BevelInner = bvRaised
    BevelWidth = 2
    Color = 6316287
    TabOrder = 0
    object Label1: TLabel
      Left = 72
      Top = 24
      Width = 531
      Height = 37
      Caption = 'BIZTOS, HOGY T'#214'R'#214'LNI AKARJA  '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 192
      Top = 136
      Width = 290
      Height = 37
      Caption = 'MINDEN ADAT'#193'T ?'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object ADATBAZISNEVPANEL: TPanel
      Left = 72
      Top = 80
      Width = 513
      Height = 41
      BorderStyle = bsSingle
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object TORLESOKEGOMB: TBitBtn
      Left = 24
      Top = 200
      Width = 297
      Height = 33
      Cursor = crHandPoint
      Caption = 'IGEN, T'#214'R'#214'LNI AKAROM AZ '#214'SSZES ADATOT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = TORLESOKEGOMBClick
      OnEnter = TORLESOKEGOMBEnter
      OnExit = TORLESOKEGOMBExit
    end
    object NEMTORLOKGOMB: TBitBtn
      Left = 328
      Top = 200
      Width = 305
      Height = 33
      Cursor = crHandPoint
      Caption = 'NEM T'#214'RL'#214'K SEMMIT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = NEMTORLOKGOMBClick
      OnEnter = TORLESOKEGOMBEnter
      OnExit = TORLESOKEGOMBExit
    end
  end
end
