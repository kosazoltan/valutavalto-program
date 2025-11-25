object IRODANEVLISTA: TIRODANEVLISTA
  Left = 378
  Top = 216
  BorderStyle = bsNone
  Caption = 'IRODANEVLISTA'
  ClientHeight = 536
  ClientWidth = 572
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 572
    Height = 536
    Align = alClient
    Brush.Color = 11599871
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 24
    Top = 32
    Width = 516
    Height = 43
    Caption = 'Csoporton kiv'#252'li p'#233'nzt'#225'rak list'#225'ja'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object VISSZAGOMB: TBitBtn
    Left = 400
    Top = 480
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = VISSZAGOMBClick
  end
  object IRODAVALASZTOGOMB: TBitBtn
    Left = 224
    Top = 480
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'V'#193'LASZT'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = IRODAVALASZTOGOMBClick
  end
  object ListBox1: TListBox
    Left = 88
    Top = 88
    Width = 385
    Height = 377
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 21
    ParentFont = False
    TabOrder = 2
    OnDblClick = ListBox1DblClick
    OnKeyDown = ListBox1KeyDown
  end
  object UJPENZTARGOMB: TBitBtn
    Left = 40
    Top = 480
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'UJ P'#201'NZT'#193'R'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = UJPENZTARGOMBClick
  end
  object UJPPANEL: TPanel
    Left = 16
    Top = 20
    Width = 540
    Height = 209
    TabOrder = 4
    Visible = False
    object Shape2: TShape
      Left = 1
      Top = 1
      Width = 538
      Height = 207
      Align = alClient
      Brush.Color = clSkyBlue
      Pen.Color = clAqua
      Pen.Width = 2
    end
    object Label2: TLabel
      Left = 104
      Top = 24
      Width = 349
      Height = 33
      Caption = #218'J P'#201'NZT'#193'R FELV'#201'TELE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 72
      Top = 72
      Width = 159
      Height = 21
      Caption = 'Az '#250'j p'#233'nzt'#225'r sz'#225'ma:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 72
      Top = 120
      Width = 43
      Height = 21
      Caption = 'Neve:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object SZAMEDIT: TEdit
      Left = 240
      Top = 68
      Width = 49
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      Text = '125'
      OnEnter = SZAMEDITEnter
      OnExit = SZAMEDITExit
      OnKeyDown = SZAMEDITKeyDown
    end
    object NEVEDIT: TEdit
      Left = 120
      Top = 118
      Width = 385
      Height = 29
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      Text = 'NEVEDIT'
      OnEnter = SZAMEDITEnter
      OnExit = SZAMEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object ujptokegomb: TBitBtn
      Left = 72
      Top = 160
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J P'#201'NZT'#193'R RENDBEN'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ujptokegombClick
    end
    object ujmegsemgomb: TBitBtn
      Left = 272
      Top = 160
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ujmegsemgombClick
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTimer
    Left = 32
    Top = 40
  end
end
