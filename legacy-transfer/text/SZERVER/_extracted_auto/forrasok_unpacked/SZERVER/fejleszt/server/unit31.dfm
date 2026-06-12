object JUTSZAM: TJUTSZAM
  Left = 398
  Top = 369
  BorderStyle = bsNone
  Caption = 'JUTSZAM'
  ClientHeight = 20
  ClientWidth = 162
  Color = 4473924
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
    Left = 0
    Top = 0
    Width = 152
    Height = 19
    Caption = 'JUTAL'#201'KSZ'#193'M'#205'T'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 176
    Top = 8
  end
end
