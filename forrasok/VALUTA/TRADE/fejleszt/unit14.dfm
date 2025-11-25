object ADATKULDES: TADATKULDES
  Left = 575
  Top = 400
  Width = 240
  Height = 131
  Caption = 'ADATKULDES'
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
  object ADATKULDES: TLabel
    Left = 32
    Top = 16
    Width = 141
    Height = 24
    Caption = 'ADATK'#220'LD'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 13000
    OnTimer = KILEPOTimer
    Left = 64
    Top = 56
  end
end
