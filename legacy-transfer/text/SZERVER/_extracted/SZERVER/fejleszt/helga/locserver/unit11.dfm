object HIANYZOZARASOKFORM: THIANYZOZARASOKFORM
  Left = 250
  Top = 300
  AlphaBlend = True
  AlphaBlendValue = 210
  BorderStyle = bsNone
  Caption = 'HIANYZOZARASOKFORM'
  ClientHeight = 322
  ClientWidth = 496
  Color = clTeal
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
    Width = 497
    Height = 320
    BevelOuter = bvNone
    Color = 170
    TabOrder = 0
    object Shape1: TShape
      Left = 16
      Top = 24
      Width = 473
      Height = 273
      Brush.Color = 8421631
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 72
      Top = 32
      Width = 373
      Height = 24
      Caption = 'M'#201'G NEM '#201'RKEZETT BE MINDEN Z'#193'R'#193'S'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 168
      Top = 56
      Width = 182
      Height = 24
      Caption = 'A TEGNAPI NAPR'#211'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 168
      Top = 88
      Width = 179
      Height = 24
      Caption = 'HI'#193'NYZ'#211' Z'#193'R'#193'SOK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Bevel1: TBevel
      Left = 32
      Top = 115
      Width = 441
      Height = 4
    end
    object TOVABBGOMB: TBitBtn
      Left = 192
      Top = 280
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'TOV'#193'BB'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = TOVABBGOMBClick
    end
    object HIANYLIST: TListBox
      Left = 24
      Top = 128
      Width = 449
      Height = 145
      BorderStyle = bsNone
      Color = 8421631
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      Items.Strings = (
        '010: B'#201'K'#201'SCSABAI V'#193'LT'#211
        '020: NYIREGYH'#193'ZI TESCO')
      ParentFont = False
      TabOrder = 1
    end
  end
end
