object SELECTPENZTAROS: TSELECTPENZTAROS
  Left = 397
  Top = 181
  BorderStyle = bsNone
  Caption = 'SELECTPENZTAROS'
  ClientHeight = 516
  ClientWidth = 361
  Color = clSilver
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
  object PROSBOX: TListBox
    Left = 32
    Top = 72
    Width = 297
    Height = 385
    ItemHeight = 13
    TabOrder = 0
    OnKeyDown = PROSBOXKeyDown
  end
  object KERNEVPANEL: TPanel
    Left = 24
    Top = 24
    Width = 305
    Height = 41
    BevelOuter = bvNone
    Color = clSilver
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object EZAJOKODGOMB: TBitBtn
    Left = 32
    Top = 464
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'EZ A J'#211' K'#211'D'
    TabOrder = 2
    OnClick = EZAJOKODGOMBClick
  end
  object LESZAMOLTGOMB: TBitBtn
    Left = 184
    Top = 464
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'R LESZ'#193'MOLT'
    TabOrder = 3
    OnClick = LESZAMOLTGOMBClick
  end
end
