object Form1: TForm1
  Left = 489
  Top = 325
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 251
  ClientWidth = 399
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
    Width = 399
    Height = 251
    Align = alClient
    Brush.Color = 13697023
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 309
    Height = 41
    Caption = 'NAPI FORGALMAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 152
    Top = 208
    Width = 105
    Height = 25
    Shape = stEllipse
  end
  object Label2: TLabel
    Left = 160
    Top = 208
    Width = 83
    Height = 21
    Caption = 'dekanySoft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object HONAPCOMBO: TComboBox
    Left = 152
    Top = 64
    Width = 185
    Height = 31
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 0
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object EVCOMBO: TComboBox
    Left = 72
    Top = 64
    Width = 81
    Height = 31
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 1
    Text = '2014'
    OnChange = EVCOMBOChange
  end
  object DATUMPANEL: TPanel
    Left = 80
    Top = 112
    Width = 241
    Height = 41
    BevelOuter = bvNone
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object HOOKEGOMB: TBitBtn
    Left = 16
    Top = 168
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'H'#211'NAP RENDBEN'
    TabOrder = 3
    OnClick = HOOKEGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 208
    Top = 168
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 4
    OnClick = Button1Click
  end
end
