object Form1: TForm1
  Left = 391
  Top = 279
  Width = 610
  Height = 162
  Caption = 'K'#214'RLEV'#201'L AUT'#211'START'
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
    Left = 40
    Top = 32
    Width = 539
    Height = 24
    Caption = 'K'#214'RLEV'#201'L AUTOMATIKUS INDIT'#211'J'#193'NAK BE'#193'LL'#205'T'#193'SA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 120
    Top = 72
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'BE'#193'LL'#205'T'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 304
    Top = 72
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = BitBtn2Click
  end
end
