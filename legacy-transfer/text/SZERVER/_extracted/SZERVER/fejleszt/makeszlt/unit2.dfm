object ACEXCELTABLA: TACEXCELTABLA
  Left = 192
  Top = 114
  BorderStyle = bsNone
  ClientHeight = 39
  ClientWidth = 290
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
    Left = 8
    Top = 8
    Width = 271
    Height = 24
    Caption = 'ART-CASH KFT EXCEL-F'#220'L'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentColor = False
    ParentFont = False
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    Left = 112
    Top = 8
  end
end
