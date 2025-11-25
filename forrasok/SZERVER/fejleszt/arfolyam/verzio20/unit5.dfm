object ARFDATAIRAS: TARFDATAIRAS
  Left = 192
  Top = 123
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  ClientHeight = 306
  ClientWidth = 594
  Color = clRed
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
    Left = 96
    Top = 16
    Width = 3
    Height = 13
  end
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 577
    Height = 289
    BorderStyle = bsNone
    Color = 11599871
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 0
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 50
    OnTimer = INDITOTimer
    Left = 24
    Top = 208
  end
end
