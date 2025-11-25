object Form1: TForm1
  Left = 460
  Top = 366
  Width = 410
  Height = 193
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
    Left = 32
    Top = 32
    Width = 339
    Height = 24
    Caption = 'E-KERESKEDELEM REGENER'#193'L'#211
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 120
    Top = 64
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'REGENER'#193'L'#211
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 120
    Top = 96
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
end
