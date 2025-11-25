object Form1: TForm1
  Left = 576
  Top = 328
  Width = 187
  Height = 217
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
    Left = 24
    Top = 24
    Width = 139
    Height = 16
    Caption = 'NYOMTAT'#211' TESZT'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 48
    Top = 64
    Width = 75
    Height = 25
    Caption = 'TEST'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 48
    Top = 104
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
end
