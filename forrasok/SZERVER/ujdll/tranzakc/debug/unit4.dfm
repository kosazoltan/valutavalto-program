object hovalasztoform: Thovalasztoform
  Left = 488
  Top = 337
  BorderStyle = bsNone
  Caption = 'hovalasztoform'
  ClientHeight = 232
  ClientWidth = 424
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
    Width = 424
    Height = 232
    Align = alClient
    Brush.Color = clBtnFace
    Pen.Color = clRed
    Pen.Width = 2
  end
  object Label1: TLabel
    Left = 24
    Top = 24
    Width = 366
    Height = 37
    Caption = 'V'#225'lassza ki a kiv'#225'nt h'#243'napot'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 112
    Top = 80
    Width = 89
    Height = 35
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 27
    ParentFont = False
    TabOrder = 0
    Text = '2013'
    OnChange = EVCOMBOChange
  end
  object HONAPCOMBO: TComboBox
    Left = 200
    Top = 80
    Width = 145
    Height = 35
    DropDownCount = 12
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 27
    ParentFont = False
    TabOrder = 1
    Text = 'szeptember'
    OnChange = EVCOMBOChange
  end
  object HOOKEGOMB: TBitBtn
    Left = 48
    Top = 152
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'H'#243'nap rendben'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = HOOKEGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 208
    Top = 152
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#233'gsem'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = MEGSEMGOMBClick
  end
  object BANDISP: TCheckBox
    Left = 120
    Top = 192
    Width = 225
    Height = 17
    Caption = 'Folyamatos kijelz'#233's tiltva'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
  end
end
