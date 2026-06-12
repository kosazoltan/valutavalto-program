object Form1: TForm1
  Left = 427
  Top = 206
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 324
  ClientWidth = 836
  Color = clBlack
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
    Left = -8
    Top = 0
    Width = 841
    Height = 321
    Color = clSilver
    TabOrder = 0
    object Label1: TLabel
      Left = 160
      Top = 16
      Width = 434
      Height = 26
      Caption = 'N'#201'V N'#201'LK'#220'LI BIZALMAS BEJELENT'#201'SEK OLVAS'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 88
      Top = 280
      Width = 91
      Height = 18
      Caption = '(DUPLA-KLIKK)'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object BEJELENTESLISTA: TListBox
      Left = 16
      Top = 48
      Width = 225
      Height = 225
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 0
      OnDblClick = BEJELENTESLISTADblClick
    end
    object BitBtn3: TBitBtn
      Left = 256
      Top = 280
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = #220'ZENET OLVAS'#193'SA'
      TabOrder = 1
      OnClick = BitBtn3Click
    end
    object BitBtn4: TBitBtn
      Left = 432
      Top = 280
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 2
      OnClick = BitBtn4Click
    end
    object DISPABLAK: TListBox
      Left = 256
      Top = 48
      Width = 561
      Height = 225
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 3
    end
  end
end
