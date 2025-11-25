object KEZIADATPOTLASFORM: TKEZIADATPOTLASFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KEZIADATPOTLASFORM'
  ClientHeight = 386
  ClientWidth = 456
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
    Width = 457
    Height = 385
    BevelInner = bvRaised
    BevelWidth = 2
    Color = clTeal
    TabOrder = 0
    object Label1: TLabel
      Left = 56
      Top = 16
      Width = 336
      Height = 29
      Caption = 'CSOMAG NEM '#201'RKEZETT BE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object P1GOMB: TBitBtn
      Tag = 1
      Left = 72
      Top = 176
      Width = 321
      Height = 33
      Cursor = crHandPoint
      Caption = 'P'#201'NZK'#201'SZLETEK P'#211'TL'#193'SA'
      TabOrder = 1
      OnClick = P1GOMBClick
      OnEnter = P1GOMBEnter
      OnExit = P1GOMBExit
    end
    object P2GOMB: TBitBtn
      Tag = 2
      Left = 72
      Top = 216
      Width = 321
      Height = 33
      Cursor = crHandPoint
      Caption = #220'GYF'#201'LFORGALOM P'#211'TL'#193'SA'
      TabOrder = 2
      OnClick = P2GOMBClick
      OnEnter = P1GOMBEnter
      OnExit = P1GOMBExit
    end
    object POTLASOKEGOMB: TBitBtn
      Left = 32
      Top = 336
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEVITEL K'#214'NYVELHET'#336
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = False
      OnClick = POTLASOKEGOMBClick
    end
    object POTLASKESOBBGOMB: TBitBtn
      Left = 288
      Top = 336
      Width = 139
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#201'S'#214'BB FOLYTATOM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      TabStop = False
      OnClick = POTLASKESOBBGOMBClick
    end
    object PENZTARPANEL: TPanel
      Left = 16
      Top = 56
      Width = 425
      Height = 33
      Caption = '123 ABCDEDFGTR EDSCFRTVE SEDFRGTFR SD'
      Color = clTeal
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object DATUMPANEL: TPanel
      Left = 144
      Top = 96
      Width = 185
      Height = 33
      Caption = '2008.12.22'
      Color = clTeal
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
    object POTMENUPANEL: TPanel
      Left = 48
      Top = 144
      Width = 361
      Height = 137
      Color = clOlive
      TabOrder = 6
      object MANUALISGOMB: TBitBtn
        Left = 24
        Top = 24
        Width = 321
        Height = 33
        Cursor = crHandPoint
        Caption = 'ADATOK MANU'#193'LIS BEVITELE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = MANUALISGOMBClick
        OnEnter = P1GOMBEnter
        OnExit = P1GOMBExit
      end
      object PENZTARZAROGOMB: TBitBtn
        Left = 24
        Top = 72
        Width = 321
        Height = 33
        Cursor = crHandPoint
        Caption = 'A P'#201'NZT'#193'R Z'#193'RVA VOLT A FENTI NAPON'
        TabOrder = 1
        OnClick = PENZTARZAROGOMBClick
        OnEnter = P1GOMBEnter
        OnExit = P1GOMBExit
      end
    end
  end
end
