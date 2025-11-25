object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 121
  ClientWidth = 454
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
  object Panel1: TPanel
    Left = 3
    Top = 3
    Width = 449
    Height = 113
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 449
      Height = 113
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 64
      Top = 24
      Width = 320
      Height = 28
      Caption = 'EZ A TRANZAKCI'#211' AKCI'#211'S ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object IGENGOMB: TBitBtn
      Left = 56
      Top = 64
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'Igen - akci'#243's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IGENGOMBClick
    end
    object NEMGOMB: TBitBtn
      Left = 232
      Top = 64
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'Ez nem akci'#243's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NEMGOMBClick
    end
  end
end
