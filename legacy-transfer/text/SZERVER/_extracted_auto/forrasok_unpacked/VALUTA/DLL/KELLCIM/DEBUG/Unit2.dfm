object KELLCIMLET: TKELLCIMLET
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KELLCIMLET'
  ClientHeight = 106
  ClientWidth = 389
  Color = clYellow
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object alappanel: TPanel
    Left = 0
    Top = 0
    Width = 385
    Height = 105
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 385
      Height = 105
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label1: TLabel
      Left = 80
      Top = 16
      Width = 243
      Height = 26
      Caption = 'KELL C'#205'MLETEZNI ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object KELLGOMB: TBitBtn
      Left = 48
      Top = 64
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'KELL'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = KELLGOMBClick
    end
    object NEMKELLGOMB: TBitBtn
      Left = 200
      Top = 64
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM KELL'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NEMKELLGOMBClick
    end
  end
end
