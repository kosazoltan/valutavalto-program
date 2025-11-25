object Form1: TForm1
  Left = 201
  Top = 121
  BorderStyle = bsNone
  ClientHeight = 638
  ClientWidth = 864
  Color = 5592405
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
    Left = 248
    Top = 24
    Width = 435
    Height = 41
    Caption = 'Mikor frissitettek a p'#233'nzt'#225'rak'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 56
    Top = 98
    Width = 59
    Height = 25
    Caption = 'Verzio:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object verziolabel: TLabel
    Left = 128
    Top = 96
    Width = 59
    Height = 29
    Caption = '00.00'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object quitgomb: TBitBtn
    Left = 628
    Top = 600
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'Kil'#233'p'#233's a programb'#243'l'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = quitgombClick
  end
  object KOCKAPANEL: TPanel
    Left = 48
    Top = 192
    Width = 769
    Height = 390
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnMouseMove = KOCKAPANELMouseMove
    object P1: TPanel
      Tag = 1
      Left = 40
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '1'
      TabOrder = 0
      OnMouseMove = P1MouseMove
    end
    object P18: TPanel
      Tag = 18
      Left = 40
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '18'
      TabOrder = 1
      OnMouseMove = P1MouseMove
    end
    object P35: TPanel
      Tag = 35
      Left = 40
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '35'
      TabOrder = 2
      OnMouseMove = P1MouseMove
    end
    object P52: TPanel
      Tag = 52
      Left = 40
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '52'
      TabOrder = 3
      OnMouseMove = P1MouseMove
    end
    object P69: TPanel
      Tag = 69
      Left = 40
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '69'
      TabOrder = 4
      OnMouseMove = P1MouseMove
    end
    object P86: TPanel
      Tag = 86
      Left = 40
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '86'
      TabOrder = 5
      OnMouseMove = P1MouseMove
    end
    object P103: TPanel
      Tag = 103
      Left = 40
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '103'
      TabOrder = 6
      OnMouseMove = P1MouseMove
    end
    object P120: TPanel
      Tag = 120
      Left = 40
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '120'
      TabOrder = 7
      OnMouseMove = P1MouseMove
    end
    object P137: TPanel
      Tag = 137
      Left = 40
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '137'
      TabOrder = 8
      OnMouseMove = P1MouseMove
    end
    object P154: TPanel
      Tag = 154
      Left = 40
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '154'
      TabOrder = 9
      OnMouseMove = P1MouseMove
    end
    object P19: TPanel
      Tag = 19
      Left = 81
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '19'
      TabOrder = 10
      OnMouseMove = P1MouseMove
    end
    object P9: TPanel
      Tag = 9
      Left = 368
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '9'
      TabOrder = 11
      OnMouseMove = P1MouseMove
    end
    object P8: TPanel
      Tag = 8
      Left = 327
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '8'
      TabOrder = 12
      OnMouseMove = P1MouseMove
    end
    object P12: TPanel
      Tag = 12
      Left = 491
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '12'
      TabOrder = 13
      OnMouseMove = P1MouseMove
    end
    object P10: TPanel
      Tag = 10
      Left = 409
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '10'
      TabOrder = 14
      OnMouseMove = P1MouseMove
    end
    object P11: TPanel
      Tag = 11
      Left = 450
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '11'
      TabOrder = 15
      OnMouseMove = P1MouseMove
    end
    object P7: TPanel
      Tag = 7
      Left = 286
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '7'
      TabOrder = 16
      OnMouseMove = P1MouseMove
    end
    object P6: TPanel
      Tag = 6
      Left = 245
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '6'
      TabOrder = 17
      OnMouseMove = P1MouseMove
    end
    object P5: TPanel
      Tag = 5
      Left = 204
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '5'
      TabOrder = 18
      OnMouseMove = P1MouseMove
    end
    object P4: TPanel
      Tag = 4
      Left = 163
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '4'
      TabOrder = 19
      OnMouseMove = P1MouseMove
    end
    object P2: TPanel
      Tag = 2
      Left = 81
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '2'
      FullRepaint = False
      TabOrder = 20
      OnMouseMove = P1MouseMove
    end
    object P15: TPanel
      Tag = 15
      Left = 614
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '15'
      TabOrder = 21
      OnMouseMove = P1MouseMove
    end
    object P13: TPanel
      Tag = 13
      Left = 532
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '13'
      TabOrder = 22
      OnMouseMove = P1MouseMove
    end
    object P16: TPanel
      Tag = 16
      Left = 655
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '16'
      TabOrder = 23
      OnMouseMove = P1MouseMove
    end
    object P17: TPanel
      Tag = 17
      Left = 696
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '17'
      TabOrder = 24
      OnMouseMove = P1MouseMove
    end
    object P14: TPanel
      Tag = 14
      Left = 573
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '14'
      TabOrder = 25
      OnMouseMove = P1MouseMove
    end
    object P3: TPanel
      Tag = 3
      Left = 122
      Top = 24
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '3'
      TabOrder = 26
      OnMouseMove = P1MouseMove
    end
    object P23: TPanel
      Tag = 23
      Left = 245
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '23'
      TabOrder = 27
      OnMouseMove = P1MouseMove
    end
    object P42: TPanel
      Tag = 42
      Left = 327
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '42'
      Color = clLime
      TabOrder = 29
      OnMouseMove = P1MouseMove
    end
    object P58: TPanel
      Tag = 58
      Left = 286
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '58'
      TabOrder = 30
      OnMouseMove = P1MouseMove
    end
    object P74: TPanel
      Tag = 74
      Left = 245
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '74'
      TabOrder = 31
      OnMouseMove = P1MouseMove
    end
    object P57: TPanel
      Tag = 57
      Left = 245
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '57'
      TabOrder = 32
      OnMouseMove = P1MouseMove
    end
    object P40: TPanel
      Tag = 40
      Left = 245
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '40'
      Color = clRed
      TabOrder = 33
      OnMouseMove = P1MouseMove
    end
    object P97: TPanel
      Tag = 97
      Left = 491
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '97'
      TabOrder = 34
      OnMouseMove = P1MouseMove
    end
    object P90: TPanel
      Tag = 90
      Left = 204
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '90'
      TabOrder = 35
      OnMouseMove = P1MouseMove
    end
    object P39: TPanel
      Tag = 39
      Left = 204
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '39'
      TabOrder = 36
      OnMouseMove = P1MouseMove
    end
    object P162: TPanel
      Tag = 162
      Left = 368
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '162'
      TabOrder = 37
      OnMouseMove = P1MouseMove
    end
    object P25: TPanel
      Tag = 25
      Left = 327
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '25'
      TabOrder = 40
      OnMouseMove = P1MouseMove
    end
    object P161: TPanel
      Tag = 161
      Left = 327
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '161'
      TabOrder = 38
      OnMouseMove = P1MouseMove
    end
    object P160: TPanel
      Tag = 160
      Left = 286
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '160'
      TabOrder = 39
      OnMouseMove = P1MouseMove
    end
    object P159: TPanel
      Tag = 159
      Left = 245
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '159'
      TabOrder = 41
      OnMouseMove = P1MouseMove
    end
    object P158: TPanel
      Tag = 158
      Left = 204
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '158'
      TabOrder = 42
      OnMouseMove = P1MouseMove
    end
    object P92: TPanel
      Tag = 92
      Left = 286
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '92'
      TabOrder = 43
      OnMouseMove = P1MouseMove
    end
    object P73: TPanel
      Tag = 73
      Left = 204
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '73'
      TabOrder = 44
      OnMouseMove = P1MouseMove
    end
    object P56: TPanel
      Tag = 56
      Left = 204
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '56'
      TabOrder = 45
      OnMouseMove = P1MouseMove
    end
    object P98: TPanel
      Tag = 98
      Left = 532
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '98'
      TabOrder = 46
      OnMouseMove = P1MouseMove
    end
    object P89: TPanel
      Tag = 89
      Left = 163
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '89'
      TabOrder = 47
      OnMouseMove = P1MouseMove
    end
    object P72: TPanel
      Tag = 72
      Left = 163
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '72'
      TabOrder = 48
      OnMouseMove = P1MouseMove
    end
    object P146: TPanel
      Tag = 146
      Left = 409
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '146'
      TabOrder = 49
      OnMouseMove = P1MouseMove
    end
    object P145: TPanel
      Tag = 145
      Left = 368
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '145'
      TabOrder = 50
      OnMouseMove = P1MouseMove
    end
    object P144: TPanel
      Tag = 144
      Left = 327
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '144'
      TabOrder = 51
      OnMouseMove = P1MouseMove
    end
    object P109: TPanel
      Tag = 109
      Left = 286
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '109'
      TabOrder = 52
      OnMouseMove = P1MouseMove
    end
    object P142: TPanel
      Tag = 142
      Left = 245
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '142'
      TabOrder = 53
      OnMouseMove = P1MouseMove
    end
    object P141: TPanel
      Tag = 141
      Left = 204
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '141'
      TabOrder = 54
      OnMouseMove = P1MouseMove
    end
    object P157: TPanel
      Tag = 157
      Left = 163
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '157'
      TabOrder = 55
      OnMouseMove = P1MouseMove
    end
    object P156: TPanel
      Tag = 156
      Left = 122
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '156'
      TabOrder = 56
      OnMouseMove = P1MouseMove
    end
    object P139: TPanel
      Tag = 139
      Left = 122
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '139'
      TabOrder = 57
      OnMouseMove = P1MouseMove
    end
    object P99: TPanel
      Tag = 99
      Left = 573
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '99'
      TabOrder = 58
      OnMouseMove = P1MouseMove
    end
    object P88: TPanel
      Tag = 88
      Left = 122
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '88'
      TabOrder = 59
      OnMouseMove = P1MouseMove
    end
    object P84: TPanel
      Tag = 84
      Left = 655
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '84'
      TabOrder = 60
      OnMouseMove = P1MouseMove
    end
    object P85: TPanel
      Tag = 85
      Left = 696
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '85'
      TabOrder = 61
      OnMouseMove = P1MouseMove
    end
    object P153: TPanel
      Tag = 153
      Left = 696
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '153'
      TabOrder = 62
      OnMouseMove = P1MouseMove
    end
    object P152: TPanel
      Tag = 152
      Left = 655
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '152'
      TabOrder = 63
      OnMouseMove = P1MouseMove
    end
    object P151: TPanel
      Tag = 151
      Left = 614
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '151'
      TabOrder = 64
      OnMouseMove = P1MouseMove
    end
    object P167: TPanel
      Tag = 167
      Left = 573
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '167'
      TabOrder = 65
      OnMouseMove = P1MouseMove
    end
    object P150: TPanel
      Tag = 150
      Left = 573
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '150'
      TabOrder = 66
      OnMouseMove = P1MouseMove
    end
    object P149: TPanel
      Tag = 149
      Left = 532
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '149'
      TabOrder = 67
      OnMouseMove = P1MouseMove
    end
    object P148: TPanel
      Tag = 148
      Left = 491
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '148'
      TabOrder = 68
      OnMouseMove = P1MouseMove
    end
    object P147: TPanel
      Tag = 147
      Left = 450
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '147'
      TabOrder = 69
      OnMouseMove = P1MouseMove
    end
    object P166: TPanel
      Tag = 166
      Left = 532
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '166'
      TabOrder = 70
      OnMouseMove = P1MouseMove
    end
    object P82: TPanel
      Tag = 82
      Left = 573
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '82'
      TabOrder = 71
      OnMouseMove = P1MouseMove
    end
    object P91: TPanel
      Tag = 91
      Left = 245
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '91'
      TabOrder = 72
      OnMouseMove = P1MouseMove
    end
    object P93: TPanel
      Tag = 93
      Left = 327
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '93'
      TabOrder = 73
      OnMouseMove = P1MouseMove
    end
    object P140: TPanel
      Tag = 140
      Left = 163
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '140'
      TabOrder = 74
      OnMouseMove = P1MouseMove
    end
    object P164: TPanel
      Tag = 164
      Left = 450
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '164'
      TabOrder = 75
      OnMouseMove = P1MouseMove
    end
    object P163: TPanel
      Tag = 163
      Left = 409
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '163'
      TabOrder = 76
      OnMouseMove = P1MouseMove
    end
    object P55: TPanel
      Tag = 55
      Left = 163
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '55'
      TabOrder = 77
      OnMouseMove = P1MouseMove
    end
    object P37: TPanel
      Tag = 37
      Left = 122
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '37'
      TabOrder = 78
      OnMouseMove = P1MouseMove
    end
    object P24: TPanel
      Tag = 24
      Left = 286
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '24'
      TabOrder = 79
      OnMouseMove = P1MouseMove
    end
    object P71: TPanel
      Tag = 71
      Left = 122
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '71'
      TabOrder = 80
      OnMouseMove = P1MouseMove
    end
    object P22: TPanel
      Tag = 22
      Left = 204
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '22'
      TabOrder = 81
      OnMouseMove = P1MouseMove
    end
    object P20: TPanel
      Tag = 20
      Left = 122
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '20'
      TabOrder = 82
      OnMouseMove = P1MouseMove
    end
    object P21: TPanel
      Tag = 21
      Left = 163
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '21'
      TabOrder = 83
      OnMouseMove = P1MouseMove
    end
    object P36: TPanel
      Tag = 36
      Left = 81
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '36'
      TabOrder = 84
      OnMouseMove = P1MouseMove
    end
    object P53: TPanel
      Tag = 53
      Left = 81
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '53'
      TabOrder = 85
      OnMouseMove = P1MouseMove
    end
    object P70: TPanel
      Tag = 70
      Left = 81
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '70'
      TabOrder = 86
      OnMouseMove = P1MouseMove
    end
    object P87: TPanel
      Tag = 87
      Left = 81
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '87'
      TabOrder = 87
      OnMouseMove = P1MouseMove
    end
    object P100: TPanel
      Tag = 100
      Left = 614
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '100'
      TabOrder = 88
      OnMouseMove = P1MouseMove
    end
    object P38: TPanel
      Tag = 38
      Left = 163
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '38'
      TabOrder = 89
      OnMouseMove = P1MouseMove
    end
    object P54: TPanel
      Tag = 54
      Left = 122
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '54'
      TabOrder = 90
      OnMouseMove = P1MouseMove
    end
    object P155: TPanel
      Tag = 155
      Left = 81
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '155'
      TabOrder = 91
      OnMouseMove = P1MouseMove
    end
    object P121: TPanel
      Tag = 121
      Left = 81
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '121'
      TabOrder = 92
      OnMouseMove = P1MouseMove
    end
    object P138: TPanel
      Tag = 138
      Left = 81
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '138'
      TabOrder = 93
      OnMouseMove = P1MouseMove
    end
    object P33: TPanel
      Tag = 33
      Left = 655
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '33'
      TabOrder = 94
      OnMouseMove = P1MouseMove
    end
    object P31: TPanel
      Tag = 31
      Left = 573
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '31'
      TabOrder = 95
      OnMouseMove = P1MouseMove
    end
    object P30: TPanel
      Tag = 30
      Left = 532
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '30'
      TabOrder = 96
      OnMouseMove = P1MouseMove
    end
    object P80: TPanel
      Tag = 80
      Left = 491
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '80'
      TabOrder = 97
      OnMouseMove = P1MouseMove
    end
    object P67: TPanel
      Tag = 67
      Left = 655
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '67'
      TabOrder = 98
      OnMouseMove = P1MouseMove
    end
    object P46: TPanel
      Tag = 46
      Left = 491
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '46'
      TabOrder = 99
      OnMouseMove = P1MouseMove
    end
    object P45: TPanel
      Tag = 45
      Left = 450
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '45'
      TabOrder = 100
      OnMouseMove = P1MouseMove
    end
    object P44: TPanel
      Tag = 44
      Left = 409
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '44'
      Color = clLime
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clPurple
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 101
      OnMouseMove = P1MouseMove
    end
    object P43: TPanel
      Tag = 43
      Left = 368
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '43'
      Color = clLime
      TabOrder = 102
      OnMouseMove = P1MouseMove
    end
    object P77: TPanel
      Tag = 77
      Left = 368
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '77'
      TabOrder = 103
      OnMouseMove = P1MouseMove
    end
    object P78: TPanel
      Tag = 78
      Left = 409
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '78'
      TabOrder = 104
      OnMouseMove = P1MouseMove
    end
    object P83: TPanel
      Tag = 83
      Left = 614
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '83'
      TabOrder = 105
      OnMouseMove = P1MouseMove
    end
    object P96: TPanel
      Tag = 96
      Left = 450
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '96'
      TabOrder = 106
      OnMouseMove = P1MouseMove
    end
    object P79: TPanel
      Tag = 79
      Left = 450
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '79'
      TabOrder = 107
      OnMouseMove = P1MouseMove
    end
    object P76: TPanel
      Tag = 76
      Left = 327
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '76'
      TabOrder = 108
      OnMouseMove = P1MouseMove
    end
    object P169: TPanel
      Tag = 169
      Left = 655
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '169'
      TabOrder = 109
      OnMouseMove = P1MouseMove
    end
    object P170: TPanel
      Tag = 170
      Left = 696
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '170'
      TabOrder = 110
      OnMouseMove = P1MouseMove
    end
    object P136: TPanel
      Tag = 136
      Left = 696
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '136'
      TabOrder = 111
      OnMouseMove = P1MouseMove
    end
    object P119: TPanel
      Tag = 119
      Left = 696
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '119'
      TabOrder = 112
      OnMouseMove = P1MouseMove
    end
    object P68: TPanel
      Tag = 68
      Left = 696
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '68'
      TabOrder = 113
      OnMouseMove = P1MouseMove
    end
    object P34: TPanel
      Tag = 34
      Left = 696
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '34'
      TabOrder = 114
      OnMouseMove = P1MouseMove
    end
    object P51: TPanel
      Tag = 51
      Left = 696
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '51'
      TabOrder = 115
      OnMouseMove = P1MouseMove
    end
    object P94: TPanel
      Tag = 94
      Left = 368
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '94'
      TabOrder = 116
      OnMouseMove = P1MouseMove
    end
    object P95: TPanel
      Tag = 95
      Left = 409
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '95'
      TabOrder = 117
      OnMouseMove = P1MouseMove
    end
    object P64: TPanel
      Tag = 64
      Left = 532
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '64'
      TabOrder = 118
      OnMouseMove = P1MouseMove
    end
    object P66: TPanel
      Tag = 66
      Left = 614
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '66'
      TabOrder = 119
      OnMouseMove = P1MouseMove
    end
    object P81: TPanel
      Tag = 81
      Left = 532
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '81'
      TabOrder = 120
      OnMouseMove = P1MouseMove
    end
    object P168: TPanel
      Tag = 168
      Left = 614
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '168'
      TabOrder = 121
      OnMouseMove = P1MouseMove
    end
    object P65: TPanel
      Tag = 65
      Left = 573
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '65'
      TabOrder = 122
      OnMouseMove = P1MouseMove
    end
    object P63: TPanel
      Tag = 63
      Left = 491
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '63'
      TabOrder = 123
      OnMouseMove = P1MouseMove
    end
    object P62: TPanel
      Tag = 62
      Left = 450
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '62'
      TabOrder = 124
      OnMouseMove = P1MouseMove
    end
    object P47: TPanel
      Tag = 47
      Left = 532
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '47'
      TabOrder = 125
      OnMouseMove = P1MouseMove
    end
    object P48: TPanel
      Tag = 48
      Left = 573
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '48'
      TabOrder = 126
      OnMouseMove = P1MouseMove
    end
    object P49: TPanel
      Tag = 49
      Left = 614
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '49'
      TabOrder = 127
      OnMouseMove = P1MouseMove
    end
    object P32: TPanel
      Tag = 32
      Left = 614
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '32'
      TabOrder = 128
      OnMouseMove = P1MouseMove
    end
    object P50: TPanel
      Tag = 50
      Left = 655
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '50'
      TabOrder = 129
      OnMouseMove = P1MouseMove
    end
    object P165: TPanel
      Tag = 165
      Left = 491
      Top = 330
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '165'
      TabOrder = 130
      OnMouseMove = P1MouseMove
    end
    object P108: TPanel
      Tag = 108
      Left = 245
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '108'
      TabOrder = 131
      OnMouseMove = P1MouseMove
    end
    object P143: TPanel
      Tag = 143
      Left = 286
      Top = 296
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '143'
      TabOrder = 132
      OnMouseMove = P1MouseMove
    end
    object P110: TPanel
      Tag = 110
      Left = 327
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '110'
      TabOrder = 133
      OnMouseMove = P1MouseMove
    end
    object P111: TPanel
      Tag = 111
      Left = 368
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '111'
      TabOrder = 134
      OnMouseMove = P1MouseMove
    end
    object P107: TPanel
      Tag = 107
      Left = 204
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '107'
      TabOrder = 135
      OnMouseMove = P1MouseMove
    end
    object P104: TPanel
      Tag = 104
      Left = 81
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '104'
      TabOrder = 136
      OnMouseMove = P1MouseMove
    end
    object P113: TPanel
      Tag = 113
      Left = 450
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '113'
      TabOrder = 137
      OnMouseMove = P1MouseMove
    end
    object P122: TPanel
      Tag = 122
      Left = 122
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '122'
      DragMode = dmAutomatic
      TabOrder = 138
      OnMouseMove = P1MouseMove
    end
    object P112: TPanel
      Tag = 112
      Left = 409
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '112'
      TabOrder = 139
      OnMouseMove = P1MouseMove
    end
    object P105: TPanel
      Tag = 105
      Left = 122
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '105'
      TabOrder = 140
      OnMouseMove = P1MouseMove
    end
    object P106: TPanel
      Tag = 106
      Left = 163
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '106'
      TabOrder = 141
      OnMouseMove = P1MouseMove
    end
    object P114: TPanel
      Tag = 114
      Left = 491
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '114'
      TabOrder = 142
      OnMouseMove = P1MouseMove
    end
    object P116: TPanel
      Tag = 116
      Left = 573
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '116'
      TabOrder = 143
      OnMouseMove = P1MouseMove
    end
    object P115: TPanel
      Tag = 115
      Left = 532
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '115'
      TabOrder = 144
      OnMouseMove = P1MouseMove
    end
    object P117: TPanel
      Tag = 117
      Left = 614
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '117'
      TabOrder = 145
      OnMouseMove = P1MouseMove
    end
    object P123: TPanel
      Tag = 123
      Left = 163
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '123'
      TabOrder = 146
      OnMouseMove = P1MouseMove
    end
    object P124: TPanel
      Tag = 124
      Left = 204
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '124'
      TabOrder = 147
      OnMouseMove = P1MouseMove
    end
    object P125: TPanel
      Tag = 125
      Left = 245
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '125'
      TabOrder = 148
      OnMouseMove = P1MouseMove
    end
    object P29: TPanel
      Tag = 29
      Left = 491
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '29'
      TabOrder = 149
      OnMouseMove = P1MouseMove
    end
    object P28: TPanel
      Tag = 28
      Left = 450
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '28'
      TabOrder = 150
      OnMouseMove = P1MouseMove
    end
    object P27: TPanel
      Tag = 27
      Left = 409
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '27'
      TabOrder = 151
      OnMouseMove = P1MouseMove
    end
    object P61: TPanel
      Tag = 61
      Left = 409
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '61'
      TabOrder = 152
      OnMouseMove = P1MouseMove
    end
    object P60: TPanel
      Tag = 60
      Left = 368
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '60'
      TabOrder = 153
      OnMouseMove = P1MouseMove
    end
    object P26: TPanel
      Tag = 26
      Left = 368
      Top = 58
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '26'
      TabOrder = 154
      OnMouseMove = P1MouseMove
    end
    object P41: TPanel
      Tag = 41
      Left = 286
      Top = 92
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '41'
      Color = clBlack
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 155
      OnMouseMove = P1MouseMove
    end
    object P59: TPanel
      Tag = 59
      Left = 327
      Top = 126
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '59'
      TabOrder = 156
      OnMouseMove = P1MouseMove
    end
    object P101: TPanel
      Tag = 101
      Left = 655
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '101'
      TabOrder = 157
      OnMouseMove = P1MouseMove
    end
    object P118: TPanel
      Tag = 118
      Left = 655
      Top = 228
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '118'
      TabOrder = 158
      OnMouseMove = P1MouseMove
    end
    object P126: TPanel
      Tag = 126
      Left = 286
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '126'
      Ctl3D = False
      ParentCtl3D = False
      TabOrder = 159
      OnMouseMove = P1MouseMove
    end
    object P131: TPanel
      Tag = 131
      Left = 491
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '131'
      TabOrder = 160
      OnMouseMove = P1MouseMove
    end
    object P129: TPanel
      Tag = 129
      Left = 409
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '129'
      TabOrder = 161
      OnMouseMove = P1MouseMove
    end
    object P127: TPanel
      Tag = 127
      Left = 327
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '127'
      TabOrder = 162
      OnMouseMove = P1MouseMove
    end
    object P128: TPanel
      Tag = 128
      Left = 368
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '128'
      TabOrder = 163
      OnMouseMove = P1MouseMove
    end
    object P102: TPanel
      Tag = 102
      Left = 696
      Top = 194
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '102'
      TabOrder = 164
      TabStop = True
      OnMouseMove = P1MouseMove
    end
    object P130: TPanel
      Tag = 130
      Left = 450
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '130'
      TabOrder = 165
      OnMouseMove = P1MouseMove
    end
    object P134: TPanel
      Tag = 134
      Left = 614
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '134'
      TabOrder = 166
      OnMouseMove = P1MouseMove
    end
    object P135: TPanel
      Tag = 135
      Left = 655
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '135'
      TabOrder = 167
      OnMouseMove = P1MouseMove
    end
    object P133: TPanel
      Tag = 133
      Left = 573
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '133'
      TabOrder = 168
      OnMouseMove = P1MouseMove
    end
    object P132: TPanel
      Tag = 132
      Left = 532
      Top = 262
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '132'
      TabOrder = 169
      OnMouseMove = P1MouseMove
    end
    object P75: TPanel
      Tag = 75
      Left = 286
      Top = 160
      Width = 40
      Height = 33
      Cursor = crHandPoint
      Caption = '75'
      TabOrder = 28
      OnMouseMove = P1MouseMove
    end
  end
  object VERZIOCOMBO: TComboBox
    Left = 56
    Top = 136
    Width = 97
    Height = 27
    Cursor = crHandPoint
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 2
    OnChange = VERZIOCOMBOChange
  end
  object VERZIOVALTOGOMB: TBitBtn
    Left = 48
    Top = 134
    Width = 145
    Height = 33
    Cursor = crHandPoint
    Caption = 'VERZI'#211' V'#193'LT'#193'S'
    TabOrder = 3
    OnClick = VERZIOVALTOGOMBClick
  end
  object Panel1: TPanel
    Left = 216
    Top = 80
    Width = 601
    Height = 89
    BevelOuter = bvNone
    Color = 5592405
    TabOrder = 4
    object Label3: TLabel
      Left = 16
      Top = 18
      Width = 171
      Height = 22
      Caption = 'P'#233'nzt'#225'r megnevez'#233'se:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 32
      Top = 56
      Width = 152
      Height = 22
      Caption = 'Frissit'#233's id'#337'pontja:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 336
      Top = 56
      Width = 34
      Height = 24
      Caption = 'id'#337':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object PNEVEDIT: TEdit
      Left = 192
      Top = 16
      Width = 393
      Height = 32
      BorderStyle = bsNone
      Color = 5592405
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object DATUMPANEL: TPanel
      Left = 184
      Top = 56
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Color = 5592405
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object IDOPANEL: TPanel
      Left = 376
      Top = 56
      Width = 57
      Height = 25
      BevelOuter = bvNone
      Color = 5592405
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 16
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 16
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 16
  end
  object FRISSQUERY: TIBQuery
    Database = FRISSDBASE
    Transaction = FRISSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 120
    Top = 16
  end
  object FRISSDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\FRISSITO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FRISSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 152
    Top = 16
  end
  object FRISSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FRISSDBASE
    AutoStopAction = saNone
    Left = 184
    Top = 16
  end
  object ALTQUERY: TIBQuery
    Database = ALTDBASE
    Transaction = ALTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 48
  end
  object ALTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ALTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 48
  end
  object ALTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ALTDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 48
  end
  object FRISSTABLA: TIBTable
    Database = FRISSDBASE
    Transaction = FRISSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'FRISSITESEK'
    Left = 120
    Top = 48
  end
  object CIKLUS: TTimer
    Enabled = False
    Interval = 120000
    OnTimer = CIKLUSTimer
    Left = 768
    Top = 32
  end
end
