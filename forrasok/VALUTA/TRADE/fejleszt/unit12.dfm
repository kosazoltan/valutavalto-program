object SelectCounty: TSelectCounty
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 481
  ClientWidth = 604
  Color = 11702634
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object vaszon: TPaintBox
    Left = 8
    Top = 56
    Width = 590
    Height = 366
    Cursor = crHandPoint
    Color = 11702634
    ParentColor = False
    OnMouseDown = vaszonMouseDown
  end
  object ESCAPEGOMB: TBitBtn
    Left = 464
    Top = 400
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'M'#201'GSEM V'#193'LASZTOK'
    TabOrder = 0
    OnClick = ESCAPEGOMBClick
  end
  object Panel1: TPanel
    Left = 8
    Top = 432
    Width = 593
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object Panel2: TPanel
    Left = 8
    Top = 8
    Width = 593
    Height = 41
    Caption = 'V'#225'lassza ki a k'#237'v'#225'nt megy'#233't !'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object VALASZTOGOMB: TBitBtn
    Left = 464
    Top = 368
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'EZT V'#193'LASZTOM'
    TabOrder = 3
    OnClick = VALASZTOGOMBClick
  end
end
