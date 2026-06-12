object Form2: TForm2
  Left = -500
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 44
  ClientWidth = 120
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object KILEPO: TTimer
    Enabled = False
    Interval = 20
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
end
