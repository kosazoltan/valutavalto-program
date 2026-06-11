object ADATLAPFORM: TADATLAPFORM
  Left = 223
  Top = 155
  BorderStyle = bsNone
  Caption = 'ADATLAPFORM'
  ClientHeight = 720
  ClientWidth = 1028
  Color = clGradientActiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Shape8: TShape
    Left = 512
    Top = 168
    Width = 505
    Height = 46
    Brush.Color = 13697023
    Pen.Width = 2
  end
  object Label20: TLabel
    Left = 520
    Top = 178
    Width = 130
    Height = 24
    Caption = 'P'#201'NZT'#193'ROS:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape14: TShape
    Left = 304
    Top = 672
    Width = 401
    Height = 40
    Shape = stRoundRect
  end
  object VISSZAGOMB: TBitBtn
    Left = 584
    Top = 680
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    TabOrder = 0
    OnClick = VISSZAGOMBClick
  end
  object Panel3: TPanel
    Left = 10
    Top = 216
    Width = 495
    Height = 449
    BevelOuter = bvNone
    Color = clGradientActiveCaption
    TabOrder = 1
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 478
      Height = 441
      Brush.Color = clSkyBlue
      Pen.Width = 2
    end
    object Shape2: TShape
      Left = 80
      Top = 24
      Width = 337
      Height = 33
      Brush.Color = 13697023
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape3: TShape
      Left = 128
      Top = 402
      Width = 249
      Height = 36
      Shape = stRoundRect
    end
    object Panel7: TPanel
      Left = 10
      Top = 60
      Width = 474
      Height = 325
      BevelOuter = bvNone
      Color = clSkyBlue
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      object Label31: TLabel
        Left = 40
        Top = 32
        Width = 119
        Height = 19
        Caption = #220'GYF'#201'L NEVE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label40: TLabel
        Left = 32
        Top = 224
        Width = 135
        Height = 19
        Caption = 'OKM'#193'NY TIPUSA:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label41: TLabel
        Left = 56
        Top = 56
        Width = 109
        Height = 19
        Caption = 'EL'#214'Z'#336' NEVE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label42: TLabel
        Left = 16
        Top = 80
        Width = 148
        Height = 19
        Caption = 'LE'#193'NYKORI NEVE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label43: TLabel
        Left = 56
        Top = 104
        Width = 105
        Height = 19
        Caption = 'ANYJA NEVE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label44: TLabel
        Left = 88
        Top = 128
        Width = 78
        Height = 19
        Caption = 'LAKC'#205'ME:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label45: TLabel
        Left = 32
        Top = 152
        Width = 130
        Height = 19
        Caption = 'LAKC'#205'MK'#193'RTYA:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label46: TLabel
        Left = 24
        Top = 176
        Width = 138
        Height = 19
        Caption = 'SZ'#220'LET'#201'SI HELY:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label47: TLabel
        Left = 16
        Top = 200
        Width = 145
        Height = 19
        Caption = 'SZ'#220'LET'#201'SI IDEJE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label48: TLabel
        Left = 32
        Top = 248
        Width = 131
        Height = 19
        Caption = 'OKM'#193'NY SZ'#193'MA:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label49: TLabel
        Left = 40
        Top = 272
        Width = 126
        Height = 19
        Caption = #193'LLAMPOLG'#193'R:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label50: TLabel
        Left = 48
        Top = 296
        Width = 113
        Height = 19
        Caption = 'TART-I HELYE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object UGYFSTORNOLABEL: TLabel
        Left = 184
        Top = 8
        Width = 95
        Height = 28
        Caption = 'STORNO'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object NEVEDIT: TEdit
        Left = 168
        Top = 32
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 0
        Text = 'NEVEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object ELOZOEDIT: TEdit
        Left = 168
        Top = 56
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 1
        Text = 'ELOZOEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object LANYEDIT: TEdit
        Left = 168
        Top = 80
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 2
        Text = 'LANYEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object ANYJAEDIT: TEdit
        Left = 168
        Top = 104
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 3
        Text = 'ANYJAEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object CIMEDIT: TEdit
        Left = 168
        Top = 128
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 4
        Text = 'CIMEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object CIMCARDEDIT: TEdit
        Left = 168
        Top = 152
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 5
        Text = 'CIMCARDEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object SZULHELYEDIT: TEdit
        Left = 168
        Top = 176
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 6
        Text = 'SZULHELYEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object SZULIDOEDIT: TEdit
        Left = 168
        Top = 200
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 7
        Text = 'SZULIDOEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object OKMTIPEDIT: TEdit
        Left = 168
        Top = 224
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 8
        Text = 'OKMTIPEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object AZONOSITOEDIT: TEdit
        Left = 168
        Top = 248
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 9
        Text = 'AZONOSITOEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object ALLAMPOLGEDIT: TEdit
        Left = 168
        Top = 272
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 10
        Text = 'ALLAMPOLGEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
      object TARTHELYEDIT: TEdit
        Left = 168
        Top = 296
        Width = 290
        Height = 27
        CharCase = ecUpperCase
        TabOrder = 11
        Text = 'TARTHELYEDIT'
        OnKeyDown = NEVEDITKeyDown
      end
    end
    object Panel8: TPanel
      Left = 85
      Top = 28
      Width = 325
      Height = 25
      BevelOuter = bvNone
      Caption = #220'GYF'#201'L ADATAI'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object ELOZOGOMB: TBitBtn
      Left = 136
      Top = 408
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'EL'#214'Z'#336
      TabOrder = 2
      OnClick = ELOZOGOMBClick
    end
    object MODRENDBENGOMB: TBitBtn
      Left = 216
      Top = 408
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      TabOrder = 3
      OnClick = MODRENDBENGOMBClick
    end
    object KOVETKEZOGOMB: TBitBtn
      Left = 296
      Top = 408
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'VETKEZ'#336
      TabOrder = 4
      OnClick = KOVETKEZOGOMBClick
    end
  end
  object JOGIPANEL: TPanel
    Left = 452
    Top = 336
    Width = 474
    Height = 325
    BevelOuter = bvNone
    Color = clSkyBlue
    TabOrder = 2
    object Label51: TLabel
      Left = 112
      Top = 24
      Width = 254
      Height = 40
      Caption = 'JOGISZEM'#201'LY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object JOGISTORNOLABEL: TLabel
      Left = 224
      Top = 40
      Width = 137
      Height = 37
      Caption = 'STORNO'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label54: TLabel
      Left = 112
      Top = 80
      Width = 50
      Height = 19
      Caption = 'NEVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label55: TLabel
      Left = 56
      Top = 112
      Width = 110
      Height = 19
      Caption = 'TELEPHELYE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label56: TLabel
      Left = 48
      Top = 144
      Width = 119
      Height = 19
      Caption = 'OKIRATSZ'#193'MA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label57: TLabel
      Left = 32
      Top = 176
      Width = 135
      Height = 19
      Caption = 'TEV'#201'KENYS'#201'GE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label58: TLabel
      Left = 24
      Top = 208
      Width = 145
      Height = 19
      Caption = 'K'#201'PVISEL'#336' NEVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label59: TLabel
      Left = 64
      Top = 240
      Width = 99
      Height = 19
      Caption = 'BEOSZT'#193'SA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object JNEVEDIT: TEdit
      Left = 168
      Top = 80
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 0
      Text = 'JNEVEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
    object JHELYEDIT: TEdit
      Left = 168
      Top = 112
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 1
      Text = 'JHELYEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
    object JOKIRSZAMEDIT: TEdit
      Left = 168
      Top = 144
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 2
      Text = 'JOKIRSZAMEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
    object JTEVEKENYEDIT: TEdit
      Left = 168
      Top = 176
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 3
      Text = 'JTEVEKENYEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
    object JKEPVISEDIT: TEdit
      Left = 168
      Top = 208
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 4
      Text = 'JKEPVISEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
    object JBEOSZTASEDIT: TEdit
      Left = 168
      Top = 240
      Width = 290
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 5
      Text = 'JBEOSZTASEDIT'
      OnKeyDown = NEVEDITKeyDown
    end
  end
  object Panel9: TPanel
    Left = 8
    Top = 168
    Width = 497
    Height = 50
    BevelOuter = bvNone
    Color = clGradientActiveCaption
    TabOrder = 3
    object Shape4: TShape
      Left = 2
      Top = 2
      Width = 490
      Height = 46
      Brush.Color = 13697023
      Pen.Width = 2
    end
    object Label12: TLabel
      Left = 16
      Top = 12
      Width = 103
      Height = 24
      Caption = 'P'#201'NZT'#193'R:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PENZTARPANEL: TPanel
      Left = 136
      Top = 8
      Width = 345
      Height = 33
      Alignment = taLeftJustify
      BevelOuter = bvNone
      Caption = 'NY'#205'REGYH'#193'ZA PRAKTIKER'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object Panel14: TPanel
    Left = 8
    Top = 0
    Width = 250
    Height = 50
    BevelOuter = bvNone
    Color = clGradientActiveCaption
    TabOrder = 4
    object Shape6: TShape
      Left = 2
      Top = 2
      Width = 245
      Height = 46
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label13: TLabel
      Left = 8
      Top = 14
      Width = 106
      Height = 24
      Caption = 'SORSZ'#193'M:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object SORSZAMPANEL: TPanel
      Left = 120
      Top = 8
      Width = 121
      Height = 33
      BevelOuter = bvNone
      Caption = '445678'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object Panel15: TPanel
    Left = 8
    Top = 52
    Width = 1012
    Height = 113
    BevelOuter = bvNone
    Color = clGradientActiveCaption
    TabOrder = 5
    object Shape5: TShape
      Left = 2
      Top = 2
      Width = 1007
      Height = 111
      Brush.Color = 13697023
      Pen.Width = 2
    end
    object Label14: TLabel
      Left = 80
      Top = 16
      Width = 249
      Height = 23
      Caption = 'P'#201'NZ'#220'GYI SZOLG'#193'LTAT'#211':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label15: TLabel
      Left = 272
      Top = 48
      Width = 59
      Height = 23
      Caption = 'C'#205'ME:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label16: TLabel
      Left = 80
      Top = 80
      Width = 249
      Height = 23
      Caption = 'FELEL'#336'S SZEM'#201'LY NEVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object CEGNEVLABEL: TLabel
      Left = 336
      Top = 16
      Width = 314
      Height = 24
      Caption = 'EXCLUSIVE BEST CHANGE KFT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object CEGCIMLABEL: TLabel
      Left = 336
      Top = 48
      Width = 333
      Height = 24
      Caption = 'BUDAPEST, SZENT ISTV'#193'N T'#201'R 3.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object FELELOSLABEL: TLabel
      Left = 336
      Top = 80
      Width = 568
      Height = 24
      Caption = 'NAGY ANNAM'#193'RIA , P'#201'CS, CITROM U 2-6 (06/70-457-75-63)'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
  end
  object Panel17: TPanel
    Left = 264
    Top = 0
    Width = 760
    Height = 50
    BevelOuter = bvNone
    Color = clGradientActiveCaption
    TabOrder = 6
    object Shape7: TShape
      Left = 2
      Top = 2
      Width = 755
      Height = 46
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Panel18: TPanel
      Left = 16
      Top = 8
      Width = 713
      Height = 33
      BevelOuter = bvNone
      Caption = #220'GYF'#201'L ADATLAP'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object PROSPANEL: TPanel
    Left = 672
    Top = 174
    Width = 337
    Height = 33
    Alignment = taLeftJustify
    BevelOuter = bvNone
    Caption = 'SZENTESI BOLDIZS'#193'RN'#201
    Color = 13697023
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object NYOMTATOGOMB: TBitBtn
    Left = 312
    Top = 680
    Width = 121
    Height = 25
    Caption = 'NYOMTAT'#193'S (F8)'
    TabOrder = 9
    OnClick = nyomtatogombClick
  end
  object STORNOGOMB: TBitBtn
    Left = 440
    Top = 680
    Width = 137
    Height = 25
    Caption = 'BIZONYLAT STORN'#211
    TabOrder = 10
    OnClick = STORNOGOMBClick
  end
  object INDEXNEVLISTA: TListBox
    Left = 672
    Top = 344
    Width = 121
    Height = 41
    ItemHeight = 13
    TabOrder = 11
  end
  object Panel20: TPanel
    Left = 512
    Top = 224
    Width = 513
    Height = 441
    BevelOuter = bvNone
    Caption = 'T'
    Color = clGradientActiveCaption
    TabOrder = 8
    object Shape9: TShape
      Left = 0
      Top = 0
      Width = 505
      Height = 441
      Brush.Color = clSkyBlue
      Pen.Width = 2
    end
    object Shape10: TShape
      Left = 80
      Top = 24
      Width = 337
      Height = 33
      Brush.Color = 13697023
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape11: TShape
      Left = 64
      Top = 392
      Width = 369
      Height = 33
      Shape = stRoundRect
    end
    object Shape12: TShape
      Left = 64
      Top = 352
      Width = 369
      Height = 33
      Shape = stRoundRect
    end
    object Label21: TLabel
      Left = 72
      Top = 360
      Width = 197
      Height = 21
      Caption = 'Tranzakci'#243'k '#246'sszes '#233'rt'#233'ke:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape13: TShape
      Left = 168
      Top = 312
      Width = 177
      Height = 33
      Shape = stRoundRect
    end
    object Panel21: TPanel
      Left = 86
      Top = 28
      Width = 325
      Height = 25
      BevelOuter = bvNone
      Caption = 'TRANZAKCI'#211' ADATAI'
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object TRANZRACS: TDBGrid
      Left = 32
      Top = 80
      Width = 449
      Height = 209
      DataSource = GONGYSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Width = 68
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'BIZ.SZ'#193'M'
          Width = 67
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'VALUTANEM'
          Title.Alignment = taCenter
          Title.Caption = 'V.NEM'
          Width = 54
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKJEGY'
          Title.Alignment = taCenter
          Title.Caption = 'B. JEGY'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'FORINTERTEK'
          Title.Alignment = taCenter
          Title.Caption = 'FORINT'
          Width = 79
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'UGYFELSZAM'
          Title.Alignment = taCenter
          Title.Caption = #220'GYF'#201'L SZ'#193'MA'
          Visible = True
        end>
    end
    object GONGYERTEKPANEL: TPanel
      Left = 280
      Top = 356
      Width = 145
      Height = 25
      Caption = '125.500.000 Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object BEJELENT3GOMB: TBitBtn
      Left = 176
      Top = 316
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'MELL'#201'KLETEK'
      TabOrder = 3
      OnClick = BEJELENT3GOMBClick
    end
    object RADATLAP: TRadioButton
      Left = 72
      Top = 400
      Width = 161
      Height = 17
      Caption = 'ADATLAP TRANZAKCI'#211'I'
      Checked = True
      Color = clWhite
      ParentColor = False
      TabOrder = 4
      TabStop = True
      OnClick = RFELEVClick
    end
    object RFELEV: TRadioButton
      Left = 248
      Top = 400
      Width = 177
      Height = 17
      Caption = 'UT'#211'BBI F'#201'L'#201'V TRANZAKCI'#211'I'
      Color = clWhite
      ParentColor = False
      TabOrder = 5
      OnClick = RFELEVClick
    end
  end
  object NYOMTATOPANEL: TPanel
    Left = -304
    Top = 480
    Width = 369
    Height = 153
    BevelInner = bvRaised
    BorderWidth = 1
    Color = clSkyBlue
    TabOrder = 12
    object Label4: TLabel
      Left = 48
      Top = 8
      Width = 298
      Height = 24
      Caption = 'MIT SZERETNE NYOMTATNI ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape15: TShape
      Left = 8
      Top = 40
      Width = 353
      Height = 105
      Brush.Color = 13697023
      Pen.Width = 2
      Shape = stRoundRect
    end
    object AZONOSITONYOMTATOGOMB: TBitBtn
      Left = 16
      Top = 48
      Width = 337
      Height = 25
      Caption = 'AZONOSIT'#193'SI ADATLAPOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = AZONOSITONYOMTATOGOMBClick
    end
    object BEJELENTESNYOMTATOGOMB: TBitBtn
      Left = 16
      Top = 80
      Width = 337
      Height = 25
      Caption = 'BEJELENT'#201'SI LAPOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = BEJELENTESNYOMTATOGOMBClick
    end
    object NYOMTATASVEGEGOMB: TBitBtn
      Left = 16
      Top = 112
      Width = 337
      Height = 25
      Caption = 'NEM NYOMTATOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = NYOMTATASVEGEGOMBClick
    end
  end
  object alappanel: TPanel
    Left = 928
    Top = 600
    Width = 1024
    Height = 768
    Color = clSilver
    TabOrder = 13
    object Label1: TLabel
      Left = 248
      Top = 40
      Width = 566
      Height = 108
      Caption = 'ADATLAPOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = 6316128
      Font.Height = -96
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 232
      Top = 32
      Width = 566
      Height = 108
      Caption = 'ADATLAPOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -96
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Panel2: TPanel
      Left = 248
      Top = 200
      Width = 585
      Height = 400
      BevelOuter = bvNone
      Color = clSilver
      TabOrder = 0
      object Shape17: TShape
        Left = 0
        Top = 5
        Width = 585
        Height = 388
        Brush.Color = clGradientActiveCaption
      end
      object Label5: TLabel
        Left = 160
        Top = 24
        Width = 305
        Height = 29
        Caption = 'KIT'#214'LT'#214'TT ADATLAPOK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -23
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object ADATLAPRACS: TDBGrid
        Left = 16
        Top = 88
        Width = 566
        Height = 257
        Cursor = crHandPoint
        DataSource = ADATLAPSOURCE
        Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnDblClick = ADATLAPRACSDblClick
        OnKeyDown = ADATLAPRACSKeyDown
        Columns = <
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'SORSZAM'
            Title.Alignment = taCenter
            Title.Caption = 'SORSZ'#193'M'
            Width = 102
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'DATUM'
            Title.Alignment = taCenter
            Title.Caption = 'D'#193'TUM'
            Width = 99
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'UGYFELNEV'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L NEVE'
            Width = 224
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'OSSZESFORINT'
            Title.Alignment = taCenter
            Title.Caption = #214'SSZES FT.'
            Width = 104
            Visible = True
          end>
      end
      object BitBtn2: TBitBtn
        Left = 56
        Top = 358
        Width = 113
        Height = 25
        Cursor = crHandPoint
        Caption = #218'J ADATLAP'
        TabOrder = 1
      end
      object MINORTRANSGOMB: TBitBtn
        Left = 176
        Top = 358
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = '300 000 ALATT'
        TabOrder = 2
        OnClick = MINORTRANSGOMBClick
      end
      object MAJORTRANSGOMB: TBitBtn
        Left = 304
        Top = 358
        Width = 121
        Height = 25
        Cursor = crHandPoint
        Caption = '300 000 FELETT'
        TabOrder = 3
        OnClick = MAJORTRANSGOMBClick
      end
      object CANCELGOMB: TBitBtn
        Left = 432
        Top = 358
        Width = 105
        Height = 25
        Cursor = crHandPoint
        Caption = 'F'#336'MEN'#220'RE'
        TabOrder = 4
        OnClick = cancelgombClick
      end
      object TIPUSPANEL: TPanel
        Left = 160
        Top = 56
        Width = 305
        Height = 25
        Caption = 'TIPUSPANEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
      end
    end
  end
  object ADATLAPSOURCE: TDataSource
    DataSet = ADATLAPQUERY
    Left = 744
    Top = 64
  end
  object ADATLAPDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ADATLAPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 864
    Top = 64
  end
  object ADATLAPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ADATLAPDBASE
    AutoStopAction = saNone
    Left = 896
    Top = 64
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 312
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 344
    Top = 8
  end
  object GONGYCSOMAGTABLA: TIBTable
    Database = GONGYCSOMAGDBASE
    Transaction = GONGYCSOMAGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'UGYFELTIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'UGYFELSZAM'
        DataType = ftInteger
      end
      item
        Name = 'UGYFELNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 11
      end
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'BANKJEGY'
        DataType = ftInteger
      end
      item
        Name = 'FORINTERTEK'
        DataType = ftInteger
      end
      item
        Name = 'GONGYCSOMAGSZAM'
        DataType = ftInteger
      end
      item
        Name = 'DATUGYFSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 16
      end
      item
        Name = 'BIZONYLATSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 7
      end
      item
        Name = 'FELADVA'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'IDX_GONGYCSOMAG2'
        Fields = 'DATUGYFSZAM'
      end
      item
        Name = 'IDX_GONGYCSOMAG'
        Fields = 'BIZONYLATSZAM'
      end
      item
        Name = 'IDX_GONGYCSOMAG1'
        Fields = 'GONGYCSOMAGSZAM'
      end>
    IndexFieldNames = 'GONGYCSOMAGSZAM'
    StoreDefs = True
    TableName = 'GONGYCSOMAG'
    Left = 808
    Top = 8
    object GONGYCSOMAGTABLAUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object GONGYCSOMAGTABLAUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
    end
    object GONGYCSOMAGTABLAUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      FixedChar = True
      Size = 25
    end
    object GONGYCSOMAGTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      FixedChar = True
      Size = 11
    end
    object GONGYCSOMAGTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object GONGYCSOMAGTABLABANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      DisplayFormat = '###,###,###'
    end
    object GONGYCSOMAGTABLAFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      DisplayFormat = '###,###,###'
    end
    object GONGYCSOMAGTABLAGONGYCSOMAGSZAM: TIntegerField
      FieldName = 'GONGYCSOMAGSZAM'
    end
    object GONGYCSOMAGTABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      FixedChar = True
      Size = 7
    end
  end
  object GONGYCSOMAGDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = GONGYCSOMAGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 840
    Top = 8
  end
  object GONGYCSOMAGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GONGYCSOMAGDBASE
    AutoStopAction = saNone
    Left = 880
    Top = 8
  end
  object GONGYSOURCE: TDataSource
    DataSet = GONGYCSOMAGQUERY
    Left = 776
    Top = 64
  end
  object FEJDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 96
  end
  object FEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 16
    Top = 128
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 280
    Top = 8
  end
  object ADATLAPQUERY: TIBQuery
    Database = ADATLAPDBASE
    Transaction = ADATLAPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM ADATLAP')
    Left = 832
    Top = 64
    object ADATLAPQUERYUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
      Origin = 'ADATLAP.UGYFELSZAM'
    end
    object ADATLAPQUERYGONGYCSOMAGSZAM: TIntegerField
      FieldName = 'GONGYCSOMAGSZAM'
      Origin = 'ADATLAP.GONGYCSOMAGSZAM'
    end
    object ADATLAPQUERYSORSZAM: TIntegerField
      FieldName = 'SORSZAM'
      Origin = 'ADATLAP.SORSZAM'
    end
    object ADATLAPQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'ADATLAP.DATUM'
      FixedChar = True
      Size = 11
    end
    object ADATLAPQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'ADATLAP.IDO'
      FixedChar = True
      Size = 8
    end
    object ADATLAPQUERYPENZTARKOD: TIBStringField
      FieldName = 'PENZTARKOD'
      Origin = 'ADATLAP.PENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object ADATLAPQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'ADATLAP.PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object ADATLAPQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'ADATLAP.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object ADATLAPQUERYKORULMENY: TIBStringField
      FieldName = 'KORULMENY'
      Origin = 'ADATLAP.KORULMENY'
      FixedChar = True
      Size = 70
    end
    object ADATLAPQUERYEGYEB: TIBStringField
      FieldName = 'EGYEB'
      Origin = 'ADATLAP.EGYEB'
      FixedChar = True
      Size = 70
    end
    object ADATLAPQUERYOSSZESFORINT: TIntegerField
      FieldName = 'OSSZESFORINT'
      Origin = 'ADATLAP.OSSZESFORINT'
      DisplayFormat = '###,###,###'
    end
    object ADATLAPQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'ADATLAP.STORNO'
    end
    object ADATLAPQUERYUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      Origin = 'ADATLAP.UGYFELNEV'
      FixedChar = True
      Size = 25
    end
  end
  object MODQUERY: TIBQuery
    Database = MODDBASE
    Transaction = modtranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 400
    Top = 8
  end
  object MODDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = modtranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 432
    Top = 8
  end
  object modtranz: TIBTransaction
    Active = False
    DefaultDatabase = MODDBASE
    AutoStopAction = saNone
    Left = 464
    Top = 8
  end
  object GONGYCSOMAGQUERY: TIBQuery
    Database = GONGYCSOMAGDBASE
    Transaction = GONGYCSOMAGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 776
    Top = 8
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 64
  end
end
