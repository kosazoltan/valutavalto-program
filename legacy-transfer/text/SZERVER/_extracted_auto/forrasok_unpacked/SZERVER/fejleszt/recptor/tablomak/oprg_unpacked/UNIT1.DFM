object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
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
    Left = 184
    Top = 144
    Width = 551
    Height = 72
    Caption = 'Havi tabl'#243'k k'#233'sz'#237't'#233'se'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -64
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 264
    Top = 312
    Width = 161
    Height = 21
    Caption = 'A tabl'#243' utols'#243' napja:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object STARTGOMB: TBitBtn
    Left = 264
    Top = 448
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'Tabl'#243' k'#233'sz'#237't'#233'se indul'
    Enabled = False
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 448
    Top = 448
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'Kil'#233'p'#233's'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object DATUMEDIT: TEdit
    Left = 440
    Top = 304
    Width = 137
    Height = 37
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    Text = '2012.12.24'
    OnKeyDown = DATUMEDITKeyDown
  end
end
