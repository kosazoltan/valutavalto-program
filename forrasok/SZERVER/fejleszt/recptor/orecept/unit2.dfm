object MENTES: TMENTES
  Left = 8
  Top = 114
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'MENTES'
  ClientHeight = 179
  ClientWidth = 1272
  Color = clInactiveCaptionText
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
    Left = 440
    Top = 8
    Width = 433
    Height = 73
    Caption = 'ADATMENT'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -64
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Edit1: TEdit
    Left = 440
    Top = 72
    Width = 425
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object Edit2: TEdit
    Left = 440
    Top = 104
    Width = 425
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object CSIK: TProgressBar
    Left = 24
    Top = 144
    Width = 1217
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 2
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 2000
    OnTimer = Timer1Timer
    Left = 40
    Top = 56
  end
end
