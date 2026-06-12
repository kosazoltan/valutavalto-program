object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 606
  ClientWidth = 862
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
    Width = 862
    Height = 606
    Align = alClient
    Brush.Color = 11599871
    Pen.Color = clRed
    Pen.Width = 5
  end
  object MEMO: TMemo
    Left = 64
    Top = 104
    Width = 713
    Height = 457
    BorderStyle = bsNone
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'A PROCEDURE LEIR'#193'SA:')
    ParentFont = False
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 32
    Top = 32
    Width = 777
    Height = 41
    BevelOuter = bvNone
    Caption = 'AZ '#193'RFOLYAMOK KIK'#220'LD'#201'SE A F'#201'NY'#218'JS'#193'GRA'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object IDOZITO: TTimer
    Enabled = False
    Interval = 300000
    OnTimer = IDOZITOTimer
    Left = 40
    Top = 40
  end
end
