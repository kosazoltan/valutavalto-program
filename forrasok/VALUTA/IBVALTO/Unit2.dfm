object OPENKERDOFORM: TOPENKERDOFORM
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'OPENKERDOFORM'
  ClientHeight = 130
  ClientWidth = 629
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 129
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 625
      Height = 129
      Cursor = crHandPoint
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 582
      Height = 22
      Caption = 'KINYOMTATTA A NAV-P'#201'NZT'#193'RG'#201'P A NAPNYIT'#193'S LIST'#193'J'#193'T  ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object IGENGOMB: TBitBtn
      Left = 112
      Top = 72
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN KINYOMTATTA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IGENGOMBClick
    end
    object UJRAGOMB: TBitBtn
      Left = 320
      Top = 72
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = #218'JRA MEGPR'#211'B'#193'LOM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = UJRAGOMBClick
    end
  end
end
