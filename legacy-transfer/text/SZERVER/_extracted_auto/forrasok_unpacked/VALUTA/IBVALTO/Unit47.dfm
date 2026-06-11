object FOMENUFORM: TFOMENUFORM
  Left = 215
  Top = 112
  AlphaBlend = True
  AlphaBlendValue = 230
  BorderStyle = bsNone
  BorderWidth = 5
  Caption = 'FOMENUFORM'
  ClientHeight = 346
  ClientWidth = 654
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnKeyUp = FormKeyUp
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 168
    Top = 0
    Width = 325
    Height = 33
    Caption = 'A valutaprogram f'#337'men'#369'je'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object MENUBAR1: TPanel
    Tag = 1
    Left = 8
    Top = 36
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'A NAPI- '#201'S HAVIZ'#193'R'#193'S V'#201'GREHAJT'#193'SA, CIMLETEZ'#201'S'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR2: TPanel
    Tag = 2
    Left = 8
    Top = 68
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'BIZONYLATOK MEGTEKINT'#201'SE A K'#201'PERNY'#336'N'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR3: TPanel
    Tag = 3
    Left = 8
    Top = 100
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'T'#193'RSP'#201'NZT'#193'RAK KARBANTART'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR4: TPanel
    Tag = 4
    Left = 8
    Top = 132
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'K'#220'L'#214'NF'#201'LE LIST'#193'K NYOMTAT'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR5: TPanel
    Tag = 5
    Left = 60
    Top = 164
    Width = 536
    Height = 30
    Cursor = crHandPoint
    Caption = 'P'#201'NZT'#193'ROSOK, JELSZAVAK KARBANTART'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR6: TPanel
    Tag = 6
    Left = 8
    Top = 196
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'NAPI FORGALOM KIMUTAT'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR7: TPanel
    Tag = 7
    Left = 8
    Top = 228
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'R'#201'GEBBI NAP Z'#193'R'#193'S'#193'NAL '#218'JRANYOMTAT'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR8: TPanel
    Tag = 8
    Left = 8
    Top = 260
    Width = 642
    Height = 30
    Cursor = crHandPoint
    Caption = 'A PILLANATNYI '#193'LL'#193'S REGENER'#193'L'#193'SA'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 8
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object MENUBAR9: TPanel
    Tag = 9
    Left = 8
    Top = 292
    Width = 562
    Height = 30
    Cursor = crHandPoint
    Caption = 'HARDWARE BE'#193'LLIT'#193'SOK '#201'S EGY'#201'B PROGRAMOK'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    OnClick = menubar1Click
    OnEnter = menubar1Enter
    OnExit = menubar1Exit
  end
  object JOBBROLBALRAGOMB: TPanel
    Left = 8
    Top = 164
    Width = 50
    Height = 30
    Cursor = crHandPoint
    Caption = '<<<'
    Color = 13421772
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
    OnClick = JobbrolBalra
  end
  object BALROLJOBBRAGOMB: TPanel
    Left = 598
    Top = 164
    Width = 50
    Height = 30
    Cursor = crHandPoint
    Caption = '>>>'
    Color = 13421772
    DragCursor = 30
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 11
    OnClick = BalrolJobbra
  end
  object Panel3: TPanel
    Left = 570
    Top = 292
    Width = 78
    Height = 30
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Color = 13421772
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 12
    OnClick = EscapeGombClick
  end
  object menutakaro: TPanel
    Left = 710
    Top = 32
    Width = 705
    Height = 313
    BevelOuter = bvNone
    Caption = 'Exclusive Change Kft.'
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -48
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
end
