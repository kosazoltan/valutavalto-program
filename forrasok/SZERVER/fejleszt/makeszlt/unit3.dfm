object EXPRESSEXCEL: TEXPRESSEXCEL
  Left = 440
  Top = 272
  BorderStyle = bsNone
  Caption = 'EXPRESSEXCEL'
  ClientHeight = 40
  ClientWidth = 286
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
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 271
    Height = 24
    BevelOuter = bvNone
    Caption = 'EXPRESSZ EXCEL'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object kilepo: TTimer
    Enabled = False
    Interval = 200
    OnTimer = kilepoTimer
    Left = 240
  end
end
