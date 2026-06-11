object IDOSZAKBEFORM: TIDOSZAKBEFORM
  Left = 221
  Top = 261
  BorderStyle = bsNone
  Caption = 'IDOSZAKBEFORM'
  ClientHeight = 198
  ClientWidth = 657
  Color = 8421631
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
    Left = 24
    Top = 24
    Width = 625
    Height = 153
    Brush.Color = clRed
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 48
    Top = 40
    Width = 575
    Height = 37
    Caption = 'K'#201'REM A VIZSG'#193'LAND'#211' ID'#336'SZAKOT'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 416
    Top = 96
    Width = 43
    Height = 24
    Caption = '-T'#214'L'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 528
    Top = 96
    Width = 24
    Height = 24
    Caption = '-IG'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 128
    Top = 96
    Width = 73
    Height = 28
    Cursor = crHandPoint
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 0
    Text = '2008'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 208
    Top = 96
    Width = 145
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 1
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object TOLCOMBO: TComboBox
    Left = 360
    Top = 96
    Width = 49
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 16
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 2
    Text = '21'
    OnChange = TOLCOMBOChange
  end
  object IGCOMBO: TComboBox
    Left = 472
    Top = 96
    Width = 49
    Height = 28
    Cursor = crHandPoint
    DropDownCount = 15
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 3
    Text = '31'
    OnChange = IGCOMBOChange
  end
  object IDSZOKEGOMB: TBitBtn
    Left = 160
    Top = 160
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'ID'#336'SZAK RENDEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = IDSZOKEGOMBClick
    OnEnter = IDSZOKEGOMBEnter
    OnExit = IDSZOKEGOMBExit
    OnMouseMove = IDSZOKEGOMBMouseMove
  end
  object IDSZCANCELGOMB: TBitBtn
    Left = 360
    Top = 160
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'M'#201'GSEM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = IDSZCANCELGOMBClick
    OnEnter = IDSZOKEGOMBEnter
    OnExit = IDSZOKEGOMBExit
    OnMouseMove = IDSZOKEGOMBMouseMove
  end
end
