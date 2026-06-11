object KELLTEGNAP: TKELLTEGNAP
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KELLTEGNAP'
  ClientHeight = 142
  ClientWidth = 560
  Color = 170
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 8
    Top = 8
    Width = 545
    Height = 129
    Brush.Color = 8421631
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 24
    Top = 16
    Width = 518
    Height = 33
    Caption = 'VIZSG'#193'LJAM A TEGNAPI ADATOKAT ?'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object IGENGOMB: TBitBtn
    Left = 64
    Top = 80
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'IGEN VIZSG'#193'LJUK MEG'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = IGENGOMBClick
    OnEnter = IGENGOMBEnter
    OnExit = IGENGOMBExit
    OnMouseMove = IGENGOMBMouseMove
  end
  object NEMGOMB: TBitBtn
    Left = 272
    Top = 80
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'HAGYJUK KI A VIZSG'#193'LATOT'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = NEMGOMBClick
    OnEnter = IGENGOMBEnter
    OnExit = IGENGOMBExit
    OnMouseMove = IGENGOMBMouseMove
  end
end
