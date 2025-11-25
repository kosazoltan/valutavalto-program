object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 104
    Top = 136
    Width = 661
    Height = 36
    Caption = #201'RT'#201'KT'#193'RI KEZEL'#201'SI D'#205'JAK NAPI LIST'#193'JA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 272
    Top = 280
    Width = 345
    Height = 25
    Caption = 'KEZELESI DIJAK LIST'#193'JA'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 272
    Top = 328
    Width = 345
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object RESULTPANEL: TPanel
    Left = 384
    Top = 392
    Width = 97
    Height = 41
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
end
