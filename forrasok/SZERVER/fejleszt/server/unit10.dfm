object FOMENUFORM: TFOMENUFORM
  Left = 389
  Top = 360
  BorderStyle = bsNone
  Caption = 'FOMENUFORM'
  ClientHeight = 323
  ClientWidth = 520
  Color = clInactiveBorder
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object FOMENUPANEL: TPanel
    Left = 0
    Top = 0
    Width = 521
    Height = 433
    BevelOuter = bvNone
    BevelWidth = 2
    Color = 170
    TabOrder = 0
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 505
      Height = 297
      Brush.Color = 8421631
      Shape = stRoundRect
    end
    object MPanel1: TPanel
      Tag = 1
      Left = 32
      Top = 16
      Width = 225
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'RENDSZERADATOK KARBANTAR'#193'SA'
      TabOrder = 0
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel2: TPanel
      Tag = 2
      Left = 16
      Top = 40
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'NAPI '#193'RFOLYAMOK KARBANTART'#193'SA'
      TabOrder = 1
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel3: TPanel
      Tag = 3
      Left = 16
      Top = 64
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'Z'#193'R'#193'SOK BE'#201'RKEZ'#201'S'#201'NEK FEL'#220'GYELETE'
      TabOrder = 2
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel4: TPanel
      Tag = 4
      Left = 16
      Top = 88
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = #220'ZLETHELYIS'#201'GEK KARBANTART'#193'SA'
      TabOrder = 3
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel5: TPanel
      Tag = 5
      Left = 16
      Top = 112
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'IMPORT-FILE K'#201'SZ'#205'T'#201'SE A BANK R'#201'SZ'#201'RE'
      TabOrder = 4
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel6: TPanel
      Tag = 6
      Left = 16
      Top = 136
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'BE'#201'RKEZETT ADATOK '#193'TTEKINT'#201'SE'
      TabOrder = 5
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel7: TPanel
      Tag = 7
      Left = 16
      Top = 160
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'ADATSZOLG'#193'LTAT'#193'S AZ MNB R'#201'SZ'#201'RE'
      TabOrder = 6
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel8: TPanel
      Tag = 8
      Left = 16
      Top = 184
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'ID'#336'SZAKI '#193'TLAG'#193'RFOLYAMOK'
      TabOrder = 7
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPanel9: TPanel
      Tag = 9
      Left = 16
      Top = 208
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'P'#201'NZT'#193'ROSOK FORGALMI ADATAI'
      TabOrder = 8
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MENUEDIT: TEdit
      Left = 232
      Top = 296
      Width = 49
      Height = 21
      TabOrder = 14
      Text = 'MENUEDIT'
      OnKeyDown = MENUEDITKeyDown
    end
    object NINCSMENUGOMB: TBitBtn
      Left = 208
      Top = 296
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 13
      OnClick = NINCSMENUGOMBClick
    end
    object MPANEL10: TPanel
      Tag = 10
      Left = 16
      Top = 232
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = #193'RFOLYAM ELT'#201'RIT'#201'SEK KIMUTAT'#193'SA'
      TabOrder = 9
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPANEL11: TPanel
      Tag = 11
      Left = 32
      Top = 256
      Width = 225
      Height = 25
      BevelInner = bvRaised
      Caption = 'WU '#201'S '#193'F'#193' ADATOK ELLEN'#214'RZ'#201'SE'
      TabOrder = 10
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPANEL12: TPanel
      Tag = 12
      Left = 264
      Top = 16
      Width = 225
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'DOLGOZ'#211'I ADATKARBANTART'#193'S'
      TabOrder = 11
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPANEL13: TPanel
      Tag = 13
      Left = 264
      Top = 40
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'TRANZAKCI'#211'S D'#205'JAK JELENT'#201'SE'
      TabOrder = 12
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPANEL14: TPanel
      Tag = 14
      Left = 264
      Top = 64
      Width = 241
      Height = 25
      Cursor = crHandPoint
      BevelInner = bvRaised
      Caption = 'JUTAL'#201'K %%% BE'#193'LLIT'#193'SA'
      TabOrder = 15
      OnClick = MPanel1Click
      OnDblClick = MPanel1Click
      OnMouseMove = MPanel1MouseMove
    end
    object MPANEL15: TPanel
      Tag = -1
      Left = 264
      Top = 88
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 16
    end
    object MPANEL16: TPanel
      Tag = -1
      Left = 264
      Top = 112
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 17
    end
    object MPANEL17: TPanel
      Tag = -1
      Left = 264
      Top = 136
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 18
    end
    object MPANEL18: TPanel
      Tag = -1
      Left = 264
      Top = 160
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 19
    end
    object MPANEL19: TPanel
      Tag = -1
      Left = 264
      Top = 184
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 20
    end
    object MPANEL20: TPanel
      Tag = -1
      Left = 264
      Top = 208
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 21
    end
    object MPANEL21: TPanel
      Tag = -1
      Left = 264
      Top = 232
      Width = 241
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 22
    end
    object MPANEL22: TPanel
      Tag = -1
      Left = 264
      Top = 256
      Width = 225
      Height = 25
      BevelInner = bvRaised
      Caption = ' '
      TabOrder = 23
    end
  end
end
