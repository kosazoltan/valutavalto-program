object EXCELFORM: TEXCELFORM
  Left = 599
  Top = 439
  Width = 195
  Height = 161
  Caption = 'EXCELFORM'
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
  object Label1: TLabel
    Left = 40
    Top = 16
    Width = 108
    Height = 18
    Caption = 'EXCELTABLA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 48
    Top = 48
    Width = 92
    Height = 18
    Caption = 'K'#201'SZ'#205'T'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 500
    OnTimer = KILEPOTimer
    Left = 8
    Top = 64
  end
end
