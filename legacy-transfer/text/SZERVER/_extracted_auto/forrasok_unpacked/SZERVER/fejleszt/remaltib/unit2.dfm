object ROGZITESFORM: TROGZITESFORM
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 170
  BorderStyle = bsNone
  ClientHeight = 146
  ClientWidth = 378
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
    Width = 377
    Height = 145
    BevelInner = bvRaised
    BevelWidth = 2
    Color = 5263615
    TabOrder = 0
    object Label1: TLabel
      Left = 40
      Top = 32
      Width = 301
      Height = 24
      Caption = 'R'#214'GZITSEM A V'#193'LTOZ'#193'SOKAT ?'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object ROGZITSDGOMB: TBitBtn
      Left = 48
      Top = 80
      Width = 131
      Height = 25
      Cursor = crHandPoint
      Caption = 'R'#214'GZITSD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = ROGZITSDGOMBClick
      OnEnter = ROGZITSDGOMBEnter
      OnExit = ROGZITSDGOMBExit
    end
    object NEROGZITSDGOMB: TBitBtn
      Left = 192
      Top = 80
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'NE R'#214'GZITSD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = NEROGZITSDGOMBClick
      OnEnter = ROGZITSDGOMBEnter
      OnExit = ROGZITSDGOMBExit
    end
  end
end
