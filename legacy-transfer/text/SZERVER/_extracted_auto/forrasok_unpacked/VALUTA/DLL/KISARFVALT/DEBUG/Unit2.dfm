object Form2: TForm2
  Left = 203
  Top = 118
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 745
  ClientWidth = 1008
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object VISSZAGOMB: TBitBtn
    Left = 376
    Top = 726
    Width = 257
    Height = 33
    Cursor = crHandPoint
    Cancel = True
    Caption = 'Nem adok kedvezm'#233'nyt'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = ESCAPEGOMBClick
  end
  object FEJCIM1: TPanel
    Left = 8
    Top = 8
    Width = 220
    Height = 66
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    object Label1: TLabel
      Left = 32
      Top = 16
      Width = 71
      Height = 31
      Caption = 'Valuta'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 112
      Top = 16
      Width = 70
      Height = 31
      Caption = 'nemek'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object CIMVA: TPanel
    Left = 230
    Top = 44
    Width = 96
    Height = 30
    Caption = 'V'#233'tel'
    Color = 14745599
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object CIMEA1: TPanel
    Left = 327
    Top = 44
    Width = 96
    Height = 30
    Caption = 'Elad'#225's'
    Color = 16769279
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object CIMVK1: TPanel
    Left = 424
    Top = 44
    Width = 96
    Height = 30
    Caption = 'V'#233'tel'
    Color = 14745599
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object CIMEK1: TPanel
    Left = 521
    Top = 44
    Width = 96
    Height = 30
    Caption = 'Elad'#225's'
    Color = 16769279
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object CIMVF1: TPanel
    Left = 618
    Top = 44
    Width = 96
    Height = 30
    Caption = 'V'#233'tel'
    Color = 14745599
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object CIMEF1: TPanel
    Left = 715
    Top = 44
    Width = 96
    Height = 30
    Caption = 'Elad'#225's'
    Color = 16769279
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object LIMPANEL1: TPanel
    Left = 230
    Top = 8
    Width = 193
    Height = 34
    Caption = '50.000 Ft-IG'
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
  object LIMPANEL2: TPanel
    Left = 425
    Top = 8
    Width = 192
    Height = 34
    Caption = '50.001 - 300.000 Ft'
    Color = 11599871
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
  end
  object LIMPANEL3: TPanel
    Left = 618
    Top = 8
    Width = 193
    Height = 34
    Caption = '300.001 - 1.000.000 Ft'
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
  end
  object CIMSHKVETEL: TPanel
    Left = 812
    Top = 44
    Width = 96
    Height = 30
    Color = 14745599
    TabOrder = 12
    object Label6: TLabel
      Left = 4
      Top = 6
      Width = 87
      Height = 17
      Caption = 'Max v'#233'teli '#225'rf.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
    end
  end
  object CIMSHKEX: TPanel
    Left = 909
    Top = 44
    Width = 96
    Height = 30
    Color = 16769279
    TabOrder = 13
    object Label9: TLabel
      Left = 8
      Top = 6
      Width = 84
      Height = 17
      Caption = 'Min elad-i '#225'rf.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
    end
  end
  object SHKCIMPANEL: TPanel
    Left = 812
    Top = 8
    Width = 193
    Height = 34
    Caption = 'Saj'#225't hat'#225'sk'#246'r'#252' '#225'rfolyamok'
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 14
  end
  object SP2: TPanel
    Left = 8
    Top = 100
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 17
    OnMouseMove = SP1MouseMove
    object D2: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N2: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA2: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object EA2: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK2: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF2: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK2: TPanel
      Left = 515
      Top = 2
      Width = 93
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX2: TPanel
      Left = 805
      Top = 2
      Width = 93
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 7
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object VF2: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EX2: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP3: TPanel
    Left = 8
    Top = 124
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 18
    OnMouseMove = SP1MouseMove
    object D3: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 0
    end
    object N3: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA3: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA3: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK3: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK3: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF3: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF3: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX3: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX3: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP4: TPanel
    Left = 8
    Top = 148
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 19
    OnMouseMove = SP1MouseMove
    object D4: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 0
    end
    object N4: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA4: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA4: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK4: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK4: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF4: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF4: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX4: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX4: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP5: TPanel
    Left = 8
    Top = 172
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 20
    OnMouseMove = SP1MouseMove
    object D5: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N5: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK5: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK5: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA5: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA5: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF5: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF5: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX5: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX5: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP6: TPanel
    Left = 8
    Top = 196
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 21
    OnMouseMove = SP1MouseMove
    object D6: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N6: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA6: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA6: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK6: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK6: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF6: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF6: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX6: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX6: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP7: TPanel
    Left = 8
    Top = 220
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 22
    OnMouseMove = SP1MouseMove
    object D7: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N7: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK7: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK7: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA7: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA7: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF7: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF7: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX7: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX7: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP8: TPanel
    Left = 8
    Top = 244
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 23
    OnMouseMove = SP1MouseMove
    object D8: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N8: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA8: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA8: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK8: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK8: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF8: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF8: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX8: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX8: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP9: TPanel
    Left = 8
    Top = 268
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 24
    OnMouseMove = SP1MouseMove
    object D9: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N9: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK9: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK9: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA9: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseMove = VK2MouseMove
    end
    object EA9: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF9: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF9: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX9: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX9: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP20: TPanel
    Left = 8
    Top = 532
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 25
    OnMouseMove = SP1MouseMove
    object D20: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N20: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA20: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA20: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK20: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK20: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF20: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF20: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX20: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX20: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP21: TPanel
    Left = 8
    Top = 556
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 26
    OnMouseMove = SP1MouseMove
    object D21: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N21: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VK21: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK21: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA21: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA21: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF21: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF21: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX21: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX21: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP13: TPanel
    Left = 8
    Top = 364
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 27
    OnMouseMove = SP1MouseMove
    object D13: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N13: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK13: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK13: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA13: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA13: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF13: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF13: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX13: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX13: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP12: TPanel
    Left = 8
    Top = 340
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 28
    OnMouseMove = SP1MouseMove
    object D12: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N12: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA12: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA12: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK12: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK12: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF12: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF12: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX12: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX12: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP19: TPanel
    Left = 8
    Top = 508
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 29
    OnMouseMove = SP1MouseMove
    object D19: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N19: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VK19: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK19: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA19: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA19: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF19: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF19: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX19: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX19: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP15: TPanel
    Left = 8
    Top = 412
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 30
    OnMouseMove = SP1MouseMove
    object D15: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N15: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK15: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK15: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA15: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA15: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF15: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF15: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX15: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX15: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP11: TPanel
    Left = 8
    Top = 316
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 31
    OnMouseMove = SP1MouseMove
    object D11: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N11: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VK11: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK11: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA11: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA11: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF11: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF11: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX11: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX11: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP14: TPanel
    Left = 8
    Top = 388
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 32
    OnMouseMove = SP1MouseMove
    object D14: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N14: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA14: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA14: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK14: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK14: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF14: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF14: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX14: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX14: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP18: TPanel
    Left = 8
    Top = 484
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 33
    OnMouseMove = SP1MouseMove
    object D18: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N18: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA18: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA18: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK18: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK18: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF18: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF18: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX18: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX18: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP17: TPanel
    Left = 8
    Top = 460
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 34
    OnMouseMove = SP1MouseMove
    object D17: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N17: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VK17: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK17: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VA17: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
    end
    object EA17: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
    end
    object VF17: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF17: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX17: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX17: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP16: TPanel
    Left = 8
    Top = 436
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 35
    OnMouseMove = SP1MouseMove
    object D16: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N16: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA16: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA16: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK16: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK16: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF16: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF16: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX16: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX16: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP10: TPanel
    Left = 8
    Top = 292
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 36
    OnMouseMove = SP1MouseMove
    object D10: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N10: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      TabOrder = 1
    end
    object VA10: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA10: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK10: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK10: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF10: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF10: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX10: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX10: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP23: TPanel
    Left = 8
    Top = 604
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 37
    OnMouseMove = SP1MouseMove
    object D23: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N23: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA23: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object EA23: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object VK23: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK23: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF23: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF23: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX23: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX23: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP22: TPanel
    Left = 8
    Top = 580
    Width = 999
    Height = 23
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 38
    OnMouseMove = SP1MouseMove
    object D22: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N22: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA22: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 2
    end
    object EA22: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 3
    end
    object VK22: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK22: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF22: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF22: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX22: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX22: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object SP1: TPanel
    Left = 8
    Top = 76
    Width = 999
    Height = 23
    Color = clGray
    TabOrder = 40
    OnMouseMove = SP1MouseMove
    object D1: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = 'D1'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N1: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = 'N1'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA1: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = 'VA1'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object EA1: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = 'EA1'
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object VK1: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = 'VK1'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK1: TPanel
      Left = 515
      Top = 2
      Width = 93
      Height = 21
      Caption = 'EK1'
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF1: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = 'VF1'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF1: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = 'EF1'
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX1: TPanel
      Left = 805
      Top = 2
      Width = 93
      Height = 21
      Caption = 'VX1'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX1: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = 'EX1'
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object HINTPANEL: TPanel
    Left = 354
    Top = 256
    Width = 241
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 39
    object Shape3: TShape
      Left = 1
      Top = 1
      Width = 239
      Height = 39
      Align = alClient
    end
    object Label3: TLabel
      Left = 8
      Top = 10
      Width = 216
      Height = 22
      Caption = #193'rfolyamm'#243'dos'#237't'#225's > klikk'
      Transparent = True
    end
  end
  object SP24: TPanel
    Left = 8
    Top = 628
    Width = 999
    Height = 23
    Color = clGray
    TabOrder = 41
    object D24: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object N24: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object VA24: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object EA24: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object VK24: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK24: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF24: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EF24: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VX24: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EX24: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
  end
  object CUPPANEL: TPanel
    Left = 100
    Top = 108
    Width = 430
    Height = 85
    BevelInner = bvRaised
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 11
    object Shape1: TShape
      Left = 2
      Top = 2
      Width = 426
      Height = 81
      Align = alClient
      Brush.Color = clYellow
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label7: TLabel
      Left = 32
      Top = 16
      Width = 298
      Height = 22
      Caption = 'M'#211'DOS'#205'TOTT            '#193'RFOLYAM:'
    end
    object CUPPOKEGOMB: TBitBtn
      Left = 120
      Top = 48
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = CUPPOKEGOMBClick
    end
    object CUPPMEGSEMGOMB: TBitBtn
      Left = 224
      Top = 48
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ESCAPEGOMBClick
    end
    object DNEMPANEL: TPanel
      Left = 165
      Top = 8
      Width = 50
      Height = 38
      BevelOuter = bvNone
      Caption = 'EUR'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object UJARFPANEL: TPanel
      Left = 340
      Top = 8
      Width = 73
      Height = 37
      BevelOuter = bvNone
      Caption = '22,560'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
  end
  object SP25: TPanel
    Left = 8
    Top = 652
    Width = 999
    Height = 23
    Color = clGray
    TabOrder = 42
    object EX25: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object VX25: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EF25: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF25: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK25: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VK25: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EA25: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object VA25: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
    object N25: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object D25: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
    end
  end
  object SP27: TPanel
    Left = 8
    Top = 700
    Width = 999
    Height = 25
    Color = clGray
    TabOrder = 43
    object EX27: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object VX27: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EF27: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF27: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK27: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VK27: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EA27: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object VA27: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
    object N27: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object D27: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
    end
  end
  object SP26: TPanel
    Left = 8
    Top = 676
    Width = 999
    Height = 23
    Caption = ' '
    Color = clGray
    TabOrder = 44
    object EX26: TPanel
      Left = 901
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object VX26: TPanel
      Left = 805
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnMouseDown = VX2MouseDown
      OnMouseMove = VX2MouseMove
    end
    object EF26: TPanel
      Left = 708
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VF26: TPanel
      Left = 611
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EK26: TPanel
      Left = 515
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object VK26: TPanel
      Left = 418
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnMouseDown = VK2MouseDown
      OnMouseMove = VK2MouseMove
    end
    object EA26: TPanel
      Left = 320
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 16765183
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object VA26: TPanel
      Left = 223
      Top = 2
      Width = 94
      Height = 21
      Caption = ' '
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
    object N26: TPanel
      Left = 45
      Top = 2
      Width = 175
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object D26: TPanel
      Left = 2
      Top = 2
      Width = 40
      Height = 21
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
    end
  end
  object SHKFUGGONY: TPanel
    Left = -1489
    Top = 8
    Width = 195
    Height = 714
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 16
    Visible = False
    object Label14: TLabel
      Left = 32
      Top = 296
      Width = 123
      Height = 31
      Caption = 'Nincs t'#246'bb'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label15: TLabel
      Left = 16
      Top = 352
      Width = 171
      Height = 31
      Caption = 'saj'#225'that'#225'sk'#246'r'#252
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label16: TLabel
      Left = 32
      Top = 400
      Width = 127
      Height = 31
      Caption = 'engedm'#233'ny'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object CUPPANEL2: TPanel
    Left = 96
    Top = 310
    Width = 409
    Height = 185
    TabOrder = 15
    object Shape2: TShape
      Left = 1
      Top = 1
      Width = 407
      Height = 183
      Align = alClient
      Brush.Color = clYellow
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label10: TLabel
      Left = 64
      Top = 16
      Width = 294
      Height = 22
      Caption = 'SAJ'#193'T HAT'#193'SK'#214'RBEN ADHAT'#211' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label12: TLabel
      Left = 217
      Top = 48
      Width = 12
      Height = 42
      Caption = '-'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label11: TLabel
      Left = 200
      Top = 40
      Width = 112
      Height = 22
      Caption = #193'RFOLYAM:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label13: TLabel
      Left = 32
      Top = 104
      Width = 240
      Height = 22
      Caption = 'KIALKUDOTT '#193'RFOLYAM:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object DNEM2PANEL: TPanel
      Left = 144
      Top = 38
      Width = 49
      Height = 25
      BevelOuter = bvNone
      Caption = 'EUR'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object TOLARFPANEL: TPanel
      Left = 112
      Top = 64
      Width = 89
      Height = 25
      BevelOuter = bvNone
      Caption = '22,560'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object IGARFPANEL: TPanel
      Left = 232
      Top = 64
      Width = 89
      Height = 25
      BevelOuter = bvNone
      Caption = '22.660'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object UJARFEDIT: TEdit
      Left = 280
      Top = 100
      Width = 89
      Height = 25
      BorderStyle = bsNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      Text = '22.565'
      OnKeyDown = UJARFEDITKeyDown
    end
    object SHKOKEGOMB: TBitBtn
      Left = 10
      Top = 136
      Width = 201
      Height = 25
      Caption = 'KIALKUDOTT '#193'RFOLYAM RENDBEN'
      TabOrder = 4
      OnClick = SHKOKEGOMBClick
    end
    object SHKMEGSEMGOMB: TBitBtn
      Left = 216
      Top = 136
      Width = 177
      Height = 25
      Caption = 'M'#201'GSEM'
      TabOrder = 5
      OnClick = ESCAPEGOMBClick
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 48
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 160
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 192
    Top = 48
  end
  object NYUJTO: TTimer
    Enabled = False
    Interval = 20
    OnTimer = NYUJTOTimer
    Left = 48
    Top = 48
  end
  object NYUJTO2: TTimer
    Enabled = False
    Interval = 10
    OnTimer = NYUJTO2Timer
    Left = 88
    Top = 48
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 8
    Top = 48
  end
end
