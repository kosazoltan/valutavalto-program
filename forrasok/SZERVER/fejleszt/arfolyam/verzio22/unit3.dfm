object GETFUGGVENY: TGETFUGGVENY
  Left = 300
  Top = 154
  BorderIcons = []
  BorderStyle = bsNone
  ClientHeight = 115
  ClientWidth = 277
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
    Left = 4
    Top = 4
    Width = 265
    Height = 95
    Color = clInactiveCaptionText
    TabOrder = 0
    object FUGGVENYSHAPE: TShape
      Left = 4
      Top = 64
      Width = 140
      Height = 23
      Shape = stRoundRect
    end
    object ERTEKSHAPE: TShape
      Left = 4
      Top = 20
      Width = 140
      Height = 23
      Shape = stRoundRect
    end
    object MINTAHATTER: TShape
      Left = 148
      Top = 40
      Width = 33
      Height = 41
      Shape = stRoundSquare
    end
    object Label1: TLabel
      Left = 32
      Top = 45
      Width = 91
      Height = 19
      Caption = 'F'#220'GGV'#201'NY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 48
      Top = 1
      Width = 54
      Height = 19
      Caption = #201'RT'#201'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object MINTABETU: TLabel
      Left = 157
      Top = 46
      Width = 17
      Height = 26
      Caption = 'A'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object betuszingomb: TBitBtn
      Left = 186
      Top = 26
      Width = 73
      Height = 21
      Cursor = crHandPoint
      Caption = 'BET'#220'SZ'#205'N'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = betuszingombClick
    end
    object HATTERSZINGOMB: TBitBtn
      Left = 186
      Top = 48
      Width = 73
      Height = 21
      Cursor = crHandPoint
      Caption = 'H'#193'TT'#201'R'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = HATTERSZINGOMBClick
    end
    object ERTEKEDIT: TEdit
      Left = 8
      Top = 21
      Width = 130
      Height = 21
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 7
      ParentFont = False
      TabOrder = 2
      Text = 'ERTEKEDIT'
      OnEnter = ERTEKEDITEnter
      OnExit = ERTEKEDITExit
      OnKeyDown = ERTEKEDITKeyDown
    end
    object RENDBENGOMB: TBitBtn
      Left = 186
      Top = 5
      Width = 73
      Height = 21
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = RENDBENGOMBClick
    end
    object megsemgomb: TBitBtn
      Left = 186
      Top = 70
      Width = 73
      Height = 21
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = megsemgombClick
    end
    object fuggvenyedit: TEdit
      Left = 8
      Top = 65
      Width = 130
      Height = 21
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      Text = 'FUGGVENYEDIT'
      OnChange = fuggvenyeditChange
      OnKeyDown = fuggvenyeditKeyDown
    end
  end
  object ColorDialog1: TColorDialog
    Ctl3D = True
    Left = 144
    Top = 8
  end
end
