object ATTEKINTES: TATTEKINTES
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'ATTEKINTES'
  ClientHeight = 530
  ClientWidth = 749
  Color = 11599871
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
    Width = 750
    Height = 530
    Color = 11599871
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 750
      Height = 530
      Brush.Color = 8421631
      Pen.Color = clYellow
      Pen.Width = 8
    end
    object Label1: TLabel
      Left = 66
      Top = 40
      Width = 603
      Height = 40
      Caption = 'BE'#201'RKEZETT ADATOK '#193'TTEKINT'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object BitBtn1: TBitBtn
      Left = 552
      Top = 472
      Width = 171
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA A MEN'#220'RE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = Button1Click
    end
  end
end
