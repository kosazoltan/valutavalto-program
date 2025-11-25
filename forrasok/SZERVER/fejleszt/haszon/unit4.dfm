object EXCELKESZITES: TEXCELKESZITES
  Left = 206
  Top = 123
  AlphaBlend = True
  AlphaBlendValue = 170
  BorderStyle = bsNone
  Caption = 'EXCELKESZITES'
  ClientHeight = 734
  ClientWidth = 1016
  Color = 16311512
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
    Left = 152
    Top = 248
    Width = 789
    Height = 108
    Caption = 'Excelt'#225'bla k'#233'sz'#237't'#233'se'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object kilepo: TTimer
    Enabled = False
    Interval = 4000
    OnTimer = kilepoTimer
    Left = 32
    Top = 40
  end
end
