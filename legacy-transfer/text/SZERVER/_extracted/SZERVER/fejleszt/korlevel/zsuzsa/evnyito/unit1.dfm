object Form1: TForm1
  Left = 488
  Top = 277
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 392
  ClientWidth = 336
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 329
    Height = 385
  end
  object Label1: TLabel
    Left = 24
    Top = 64
    Width = 277
    Height = 22
    Caption = 'K'#214'RLEVELEK '#201'VES NYIT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 128
    Top = 16
    Width = 84
    Height = 42
    Caption = '2023'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Stencil'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Memo: TMemo
    Left = 16
    Top = 96
    Width = 297
    Height = 249
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'K'#214'RLEVELEK '#201'VES NYIT'#193'SA')
    ParentFont = False
    TabOrder = 0
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 352
    Width = 297
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 1
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 1800
    OnTimer = KILEPOTimer
    Left = 104
    Top = 216
  end
end
