object REKORDTORLOFORM: TREKORDTORLOFORM
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 190
  BorderStyle = bsNone
  Caption = 'REKORDTORLOFORM'
  ClientHeight = 168
  ClientWidth = 529
  Color = 134744319
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
    Left = 96
    Top = 16
    Width = 368
    Height = 37
    Caption = 'EGY REKORD T'#214'RL'#201'SE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 8
    Top = 72
    Width = 495
    Height = 20
    Caption = 'BIZTOS, HOGY T'#214'R'#214'LJEM A V'#193'LASZTOTT REKORDOT ?'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object TOROLDGOMB: TBitBtn
    Left = 128
    Top = 112
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'IGEN, T'#214'R'#214'LJED'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = TOROLDGOMBClick
    OnEnter = TOROLDGOMBEnter
    OnExit = TOROLDGOMBExit
  end
  object NETOROLDGOMB: TBitBtn
    Left = 288
    Top = 112
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'NE, M'#201'GSEM T'#214'R'#214'LD'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = NETOROLDGOMBClick
    OnEnter = TOROLDGOMBEnter
    OnExit = TOROLDGOMBExit
  end
end
