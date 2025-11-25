object FORM2: TFORM2
  Left = 525
  Top = 355
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 3
  Caption = 'SUPERKOD'
  ClientHeight = 168
  ClientWidth = 433
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
    Left = 1
    Top = -1
    Width = 432
    Height = 170
    BevelOuter = bvNone
    BevelWidth = 2
    Color = 16744703
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 433
      Height = 169
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 16
      Width = 392
      Height = 28
      Caption = 'K'#201'REM A SUPERVISORI JELSZ'#211'T !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clPurple
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 128
      Top = 56
      Width = 9
      Height = 37
      Caption = '['
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 288
      Top = 56
      Width = 9
      Height = 37
      Caption = ']'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object PASSWORDEDIT: TEdit
      Left = 152
      Top = 104
      Width = 113
      Height = 45
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 4
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 0
      Text = 'WWWW'
      OnKeyDown = PASSWORDEDITKeyDown
    end
    object REFERPANEL: TPanel
      Left = 144
      Top = 56
      Width = 137
      Height = 41
      Caption = 'ABCD'
      Color = clRed
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -37
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
  end
end
