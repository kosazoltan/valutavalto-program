object JONEVETVALASZT: TJONEVETVALASZT
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'JONEVETVALASZT'
  ClientHeight = 283
  ClientWidth = 476
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
  object Label1: TLabel
    Left = 120
    Top = 32
    Width = 261
    Height = 16
    Caption = 'AZ ADATB'#193'ZISBAN SZEREPL'#336' N'#201'V:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 120
    Top = 8
    Width = 263
    Height = 25
    Caption = 'V'#193'LASSZA KI A HELYES NEVET'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 16
    Top = 240
    Width = 433
    Height = 25
    Cursor = crHandPoint
    Caption = 'NINCS ILYEN NEV'#220' DOLGOZ'#211
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object JONEVLISTA: TListBox
    Left = 16
    Top = 80
    Width = 433
    Height = 145
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 1
    OnDblClick = JONEVLISTADblClick
    OnKeyUp = JONEVLISTAKeyUp
  end
  object NEVPANEL: TPanel
    Left = 16
    Top = 48
    Width = 433
    Height = 25
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
end
