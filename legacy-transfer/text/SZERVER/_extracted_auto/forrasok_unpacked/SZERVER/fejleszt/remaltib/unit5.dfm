object SZAMSUMMA: TSZAMSUMMA
  Left = 192
  Top = 114
  AlphaBlend = True
  AlphaBlendValue = 240
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'SZ'#193'MADATOK '#214'SSZEGEZ'#201'SE'
  ClientHeight = 585
  ClientWidth = 570
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
    Width = 569
    Height = 585
    Color = clSilver
    TabOrder = 0
    object Label1: TLabel
      Left = 168
      Top = 16
      Width = 239
      Height = 20
      Caption = 'SZ'#193'MADATOK '#214'SSZEGEZ'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object SZAMRACS: TStringGrid
      Left = 16
      Top = 48
      Width = 537
      Height = 481
      Color = clYellow
      ColCount = 2
      FixedColor = clAqua
      FixedCols = 0
      RowCount = 18
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      ParentFont = False
      ScrollBars = ssNone
      TabOrder = 0
      ColWidths = (
        314
        233)
    end
    object BitBtn1: TBitBtn
      Left = 264
      Top = 544
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn1Click
    end
  end
  object STARTTIMER: TTimer
    Enabled = False
    Interval = 50
    OnTimer = STARTTIMERTimer
    Left = 24
    Top = 456
  end
end
