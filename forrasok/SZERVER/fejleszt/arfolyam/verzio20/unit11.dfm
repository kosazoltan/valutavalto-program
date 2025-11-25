object INTERNETBONGESZO: TINTERNETBONGESZO
  Left = 196
  Top = 114
  BorderStyle = bsNone
  Caption = 'INTERNETBONGESZO'
  ClientHeight = 734
  ClientWidth = 1350
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
  object Label1: TLabel
    Left = 304
    Top = 16
    Width = 399
    Height = 43
    Caption = 'A kiv'#225'nt web-lap kijelz'#233'se.'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlue
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object WebBrowser1: TWebBrowser
    Left = 16
    Top = 72
    Width = 1310
    Height = 609
    TabOrder = 0
    ControlData = {
      4C00000064870000F13E00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object BROWSERBACKGOMB: TBitBtn
    Left = 24
    Top = 696
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A MUNK'#193'HOZ'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = BROWSERBACKGOMBClick
  end
  object WEBCLOSEGOMB: TBitBtn
    Left = 224
    Top = 696
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'WEBLAP BEZ'#193'R'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = WEBCLOSEGOMBClick
  end
end
