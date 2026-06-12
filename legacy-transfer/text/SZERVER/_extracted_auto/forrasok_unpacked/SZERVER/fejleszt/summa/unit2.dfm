object MAKEEXCEL: TMAKEEXCEL
  Left = 418
  Top = 249
  BorderStyle = bsNone
  Caption = 'MAKEEXCEL'
  ClientHeight = 122
  ClientWidth = 614
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
    Width = 614
    Height = 122
    Align = alClient
    Brush.Color = 4539717
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 16
    Width = 566
    Height = 43
    Caption = 'EXCEL T'#193'BLA ELK'#201'SZ'#205'T'#201'SE  ....'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object backgomb: TBitBtn
    Left = 216
    Top = 80
    Width = 209
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = backgombClick
  end
end
