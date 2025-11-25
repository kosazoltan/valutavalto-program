object MAKEEXCELTABLA: TMAKEEXCELTABLA
  Left = 192
  Top = 114
  BorderStyle = bsNone
  ClientHeight = 59
  ClientWidth = 472
  Color = clWhite
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
    Left = 56
    Top = 8
    Width = 381
    Height = 24
    Caption = #193'RFOLYAMOK EXCELT'#193'BL'#193'BA IR'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 8
    Top = 32
    Width = 457
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 0
  end
  object KILEPOGOMB: TBitBtn
    Left = 136
    Top = 0
    Width = 217
    Height = 33
    Cursor = crHandPoint
    Cancel = True
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Default = True
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
end
