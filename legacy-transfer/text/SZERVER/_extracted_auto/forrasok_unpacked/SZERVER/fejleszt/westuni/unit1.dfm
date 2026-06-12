object Form1: TForm1
  Left = 196
  Top = 138
  Width = 876
  Height = 510
  Caption = 'WESTERN UNION FORGALOM LEV'#193'LOGAT'#193'SA EXCEL T'#193'BL'#193'BA '
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
  object IDOSZAKPANEL: TPanel
    Left = -2100
    Top = 0
    Width = 856
    Height = 250
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 128
      Top = 32
      Width = 577
      Height = 185
      Pen.Width = 3
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 152
      Top = 56
      Width = 535
      Height = 32
      Caption = 'WESTERN UNION ADATOK LEGY'#220'JT'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 496
      Top = 115
      Width = 44
      Height = 22
      Caption = '-T'#211'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 624
      Top = 115
      Width = 27
      Height = 22
      Caption = '-IG'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object EVCOMBO: TComboBox
      Left = 192
      Top = 112
      Width = 73
      Height = 30
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 0
      Text = '2019'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 264
      Top = 112
      Width = 177
      Height = 30
      Cursor = crHandPoint
      DropDownCount = 12
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = EVCOMBOChange
    end
    object TOLCOMBO: TComboBox
      Left = 440
      Top = 112
      Width = 49
      Height = 30
      Cursor = crHandPoint
      DropDownCount = 18
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 2
      Text = '30'
      OnChange = TOLCOMBOChange
    end
    object IGCOMBO: TComboBox
      Left = 568
      Top = 112
      Width = 49
      Height = 30
      Cursor = crHandPoint
      DropDownCount = 18
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ItemHeight = 22
      ParentFont = False
      TabOrder = 3
      Text = '30'
      OnChange = IGCOMBOChange
    end
    object IDSZOKEGOMB: TBitBtn
      Left = 192
      Top = 168
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#336'SZAK RENDBEN'
      TabOrder = 4
      OnClick = IDSZOKEGOMBClick
    end
    object QUITGOMB: TBitBtn
      Left = 432
      Top = 168
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'PEK A PROGRAMB'#211'L'
      TabOrder = 5
      OnClick = QUITGOMBClick
    end
  end
  object LEVALOGATOPANEL: TPanel
    Left = 0
    Top = 0
    Width = 858
    Height = 470
    TabOrder = 1
    Visible = False
    object Label4: TLabel
      Left = 192
      Top = 128
      Width = 520
      Height = 24
      Caption = 'EXCEL T'#193'BLA '#214'SSZE'#193'LLIT'#193'SA A FENTI ID'#336'SZAKRA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape2: TShape
      Left = 50
      Top = 176
      Width = 785
      Height = 40
      Pen.Width = 2
      Shape = stRoundRect
    end
    object VALFOCIMPANEL: TPanel
      Left = 8
      Top = 32
      Width = 841
      Height = 41
      BevelOuter = bvNone
      Caption = 
        'A WESTERN UNION FORGALOM LEV'#193'LOGAT'#193'SA 2019.01-11 '#201'S 2019.12.31 K' +
        #214'Z'#214'TT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object CSIK: TProgressBar
      Left = 24
      Top = 88
      Width = 810
      Height = 17
      Smooth = True
      TabOrder = 1
    end
    object KORZETGOMB: TBitBtn
      Left = 208
      Top = 184
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY K'#214'RZETRE'
      TabOrder = 2
      OnClick = KORZETGOMBClick
    end
    object PENZTARGOMB: TBitBtn
      Left = 56
      Top = 184
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY P'#201'NZT'#193'RRA'
      TabOrder = 3
      OnClick = PENZTARGOMBClick
    end
    object KFTGOMB: TBitBtn
      Left = 360
      Top = 184
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY KFTRE'
      TabOrder = 4
      OnClick = KFTGOMBClick
    end
    object MASIDSZGOMB: TBitBtn
      Left = 512
      Top = 184
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#193'S ID'#336'SZAK'
      TabOrder = 5
      OnClick = MASIDSZGOMBClick
    end
    object KILEPESGOMB: TBitBtn
      Left = 664
      Top = 184
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      TabOrder = 6
      OnClick = KILEPESGOMBClick
    end
    object GOMBTAKARO: TPanel
      Left = -1987
      Top = 160
      Width = 822
      Height = 313
      BevelOuter = bvNone
      TabOrder = 7
      object Memo1: TMemo
        Left = 8
        Top = 16
        Width = 425
        Height = 281
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 0
      end
      object Memo2: TMemo
        Left = 448
        Top = 16
        Width = 361
        Height = 281
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Lines.Strings = (
          '')
        ParentFont = False
        TabOrder = 1
      end
    end
    object KFTPANEL: TPanel
      Left = -1987
      Top = 170
      Width = 813
      Height = 290
      BevelOuter = bvNone
      TabOrder = 8
      Visible = False
      object Shape5: TShape
        Left = 216
        Top = 24
        Width = 337
        Height = 201
        Brush.Color = clBtnFace
        Pen.Width = 3
        Shape = stRoundRect
      end
      object Label8: TLabel
        Left = 256
        Top = 16
        Width = 272
        Height = 23
        Caption = 'V'#193'LASSZA KI A KIV'#193'NT KFT-T'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object EBCGOMB: TPanel
        Tag = 1
        Left = 232
        Top = 56
        Width = 305
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXCLUSIVE BEST CHANGE KFT'
        Color = clWhite
        TabOrder = 0
        OnClick = KftValasztott
      end
      object EECGOMB: TPanel
        Tag = 2
        Left = 232
        Top = 88
        Width = 305
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXCLUSIVE EAST CHANGE KFT'
        Color = clWhite
        TabOrder = 1
        OnClick = KftValasztott
      end
      object EPCGPMB: TPanel
        Tag = 3
        Left = 232
        Top = 120
        Width = 305
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXCLUSIVE PANNON CHANGE KFT'
        Color = clWhite
        TabOrder = 2
        OnClick = KftValasztott
      end
      object ECPZGOMB: TPanel
        Tag = 4
        Left = 232
        Top = 152
        Width = 305
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXPRESSZ '#201'KSZERH'#193'Z '#201'S MINBANK KFT'
        Color = clWhite
        TabOrder = 3
        OnClick = KftValasztott
      end
      object BACKKFTGOMB: TPanel
        Left = 232
        Top = 184
        Width = 305
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZAL'#201'P'#201'S AZ EL'#214'Z'#336' SZINTRE'
        Color = clWhite
        TabOrder = 4
        OnClick = BACKKFTGOMBClick
      end
      object KFTTAKARO: TPanel
        Left = -1987
        Top = 8
        Width = 600
        Height = 220
        BevelOuter = bvNone
        Caption = 'EXCELT'#193'BLA '#214'SSZE'#193'LL'#205'T'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGray
        Font.Height = -29
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 5
        Visible = False
      end
    end
    object KORZETPANEL: TPanel
      Left = 24
      Top = 170
      Width = 813
      Height = 290
      BevelOuter = bvNone
      TabOrder = 9
      Visible = False
      object Shape6: TShape
        Left = 144
        Top = 56
        Width = 497
        Height = 193
        Brush.Color = clBtnFace
        Pen.Width = 3
        Shape = stRoundRect
      end
      object Label9: TLabel
        Left = 248
        Top = 48
        Width = 323
        Height = 23
        Caption = 'V'#193'LASSZA KI A KIV'#193'NT K'#214'RZETET'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object K10GOMB: TPanel
        Tag = 10
        Left = 160
        Top = 80
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'SZEKSZ'#193'RDI K'#214'RZET'
        Color = clWhite
        TabOrder = 0
        OnClick = KorzetClick
      end
      object K20GOMB: TPanel
        Tag = 20
        Left = 160
        Top = 112
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'SZEGEDI K'#214'RZET'
        Color = clWhite
        TabOrder = 1
        OnClick = KorzetClick
      end
      object K40GOMB: TPanel
        Tag = 40
        Left = 160
        Top = 144
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'KECSKEM'#201'TI K'#214'RZET'
        Color = clWhite
        TabOrder = 2
        OnClick = KorzetClick
      end
      object K50GOMB: TPanel
        Tag = 50
        Left = 160
        Top = 176
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'DEBRECENI K'#214'RZET'
        Color = clWhite
        TabOrder = 3
        OnClick = KorzetClick
      end
      object K63GOMB: TPanel
        Tag = 63
        Left = 160
        Top = 208
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'NYIREGYH'#193'ZI K'#214'RZET'
        Color = clWhite
        TabOrder = 4
        OnClick = KorzetClick
      end
      object K75GOMB: TPanel
        Tag = 75
        Left = 400
        Top = 80
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'B'#201'K'#201'SCSABAI K'#214'RZET'
        Color = clWhite
        TabOrder = 5
        OnClick = KorzetClick
      end
      object K120GOMB: TPanel
        Tag = 120
        Left = 400
        Top = 112
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'P'#201'CSI K'#214'RZET'
        Color = clWhite
        TabOrder = 6
        OnClick = KorzetClick
      end
      object K145GOMB: TPanel
        Tag = 145
        Left = 400
        Top = 144
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'KAPOSV'#193'RI K'#214'RZET'
        Color = clWhite
        TabOrder = 7
        OnClick = KorzetClick
      end
      object KEXPGOMB: TPanel
        Tag = 180
        Left = 400
        Top = 176
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'EXPRESSZ H'#193'L'#211'ZAT'
        Color = clWhite
        TabOrder = 8
        OnClick = KorzetClick
      end
      object BACKKORZETGOMB: TPanel
        Left = 400
        Top = 208
        Width = 225
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA A F'#336'MEN'#218'RE'
        Color = clWhite
        TabOrder = 9
        OnClick = BACKKORZETGOMBClick
      end
      object KORZETTAKARO: TPanel
        Left = -1987
        Top = 24
        Width = 625
        Height = 233
        BevelOuter = bvNone
        Caption = 'EXCELT'#193'BLA '#214'SSZE'#193'LL'#205'T'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGray
        Font.Height = -29
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 10
        Visible = False
      end
    end
    object PENZTARPANEL: TPanel
      Left = -1987
      Top = 176
      Width = 813
      Height = 281
      BevelOuter = bvNone
      TabOrder = 10
      Visible = False
      object Label10: TLabel
        Left = 256
        Top = 32
        Width = 329
        Height = 23
        Caption = 'V'#193'LASSZA KI A KIV'#193'NT P'#201'NZT'#193'RT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object CHANGEBOX: TListBox
        Left = 256
        Top = 50
        Width = 329
        Height = 191
        Cursor = crHandPoint
        BorderStyle = bsNone
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ItemHeight = 17
        ParentFont = False
        TabOrder = 0
        Visible = False
        OnDblClick = CHANGEBOXDblClick
        OnKeyUp = CHANGEBOXKeyUp
      end
      object EXPBOX: TListBox
        Left = -1987
        Top = 50
        Width = 329
        Height = 191
        BorderStyle = bsNone
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ItemHeight = 17
        ParentFont = False
        TabOrder = 1
        Visible = False
        OnDblClick = EXPBOXDblClick
        OnKeyUp = EXPBOXKeyUp
      end
      object MAKEEXCELPANEL: TPanel
        Left = -1999
        Top = 24
        Width = 801
        Height = 113
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        Visible = False
        object Shape4: TShape
          Left = 1
          Top = 1
          Width = 799
          Height = 111
          Align = alClient
          Brush.Color = clBtnFace
          Pen.Color = clRed
          Pen.Width = 3
        end
        object EXCELCSIK: TProgressBar
          Left = 16
          Top = 72
          Width = 769
          Height = 17
          Smooth = True
          TabOrder = 0
        end
        object EXCELCIMPANEL: TPanel
          Left = 16
          Top = 16
          Width = 769
          Height = 33
          BevelOuter = bvNone
          Caption = 
            'NY'#205'REGYH'#193'ZA PIROSH'#193'Z ADAINAK EXCELT'#193'BL'#193'BA  DOLGOZ'#193'SA FOLYAMATBAN' +
            ' '
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
          TabOrder = 1
        end
      end
      object PENZTARMENUPANEL: TPanel
        Left = -1789
        Top = 56
        Width = 545
        Height = 193
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 3
        Visible = False
        object Shape7: TShape
          Left = 24
          Top = 40
          Width = 497
          Height = 105
          Brush.Color = clBtnFace
          Pen.Width = 3
          Shape = stRoundRect
        end
        object backptvalgomb: TPanel
          Left = 152
          Top = 104
          Width = 233
          Height = 25
          Cursor = crHandPoint
          Caption = 'VISSZA A V'#193'LASZT'#211' MEN'#220'RE'
          Color = clWhite
          TabOrder = 0
          OnClick = backptvalgombClick
        end
        object EXCGOMB: TPanel
          Left = 32
          Top = 56
          Width = 233
          Height = 25
          Cursor = crHandPoint
          Caption = 'EXCLUSIVE CHANGE KFT'
          Color = clWhite
          TabOrder = 1
          OnClick = EXCGOMBClick
        end
        object EXPGOMB: TPanel
          Left = 272
          Top = 56
          Width = 233
          Height = 25
          Cursor = crHandPoint
          Caption = 'EXPRESSZ '#201'KSZERH'#193'Z '#201'S MINIBANK KFT.'
          Color = clWhite
          TabOrder = 2
          OnClick = EXPGOMBClick
        end
      end
      object PTVALMEGSEMGOMB: TBitBtn
        Left = 336
        Top = 250
        Width = 177
        Height = 25
        Cursor = crHandPoint
        Caption = 'VISSZA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        Visible = False
        OnClick = backptvalgombClick
      end
      object PENZTARTAKARO: TPanel
        Left = -1987
        Top = 8
        Width = 801
        Height = 270
        BevelOuter = bvNone
        Caption = 'EXCELT'#193'BLA '#214'SSZE'#193'LL'#205'T'#193'SA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGray
        Font.Height = -29
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 5
        Visible = False
      end
    end
  end
  object PENZTARVALASZTOPANEL: TPanel
    Left = -2200
    Top = -100
    Width = 856
    Height = 250
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 2
    Visible = False
    object Label5: TLabel
      Left = 208
      Top = 8
      Width = 252
      Height = 25
      Caption = 'V'#193'LASSZ  P'#201'NZT'#193'RT'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object PENZTARBOX: TListBox
      Left = 16
      Top = 48
      Width = 609
      Height = 185
      BevelInner = bvNone
      BorderStyle = bsNone
      Color = 11599871
      ItemHeight = 13
      TabOrder = 0
    end
    object PENZTAROKEGOMB: TBitBtn
      Left = 648
      Top = 168
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'R RENDBEN'
      TabOrder = 1
    end
    object PENZTARVISSZAGOMB: TBitBtn
      Left = 648
      Top = 208
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 2
    end
  end
  object KORZETVALASZTOPANEL: TPanel
    Left = -2100
    Top = -240
    Width = 856
    Height = 250
    Color = clWhite
    TabOrder = 3
    object Label6: TLabel
      Left = 224
      Top = 16
      Width = 402
      Height = 25
      Caption = 'JEL'#214'LD KI A KIV'#193'NT K'#214'RZETET'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object RadioButton1: TRadioButton
      Tag = 10
      Left = 40
      Top = 72
      Width = 185
      Height = 17
      Caption = 'SZEKSZ'#193'RDI K'#214'RZET'
      Checked = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      TabStop = True
      Visible = False
    end
    object RadioButton2: TRadioButton
      Tag = 20
      Left = 248
      Top = 72
      Width = 161
      Height = 17
      Caption = 'SZEGEDI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object RadioButton3: TRadioButton
      Tag = 40
      Left = 424
      Top = 72
      Width = 185
      Height = 17
      Caption = 'KECSKEM'#201'TI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object RadioButton4: TRadioButton
      Tag = 50
      Left = 632
      Top = 72
      Width = 185
      Height = 17
      Caption = 'DEBRECEN K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object RadioButton5: TRadioButton
      Tag = 63
      Left = 40
      Top = 104
      Width = 193
      Height = 17
      Caption = 'NY'#205'REGYH'#193'ZI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object RadioButton6: TRadioButton
      Tag = 85
      Left = 248
      Top = 104
      Width = 201
      Height = 17
      Caption = 'B'#201'K'#201'SCSABAI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object RadioButton7: TRadioButton
      Tag = 120
      Left = 464
      Top = 104
      Width = 137
      Height = 17
      Caption = 'P'#201'CSI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 6
    end
    object RadioButton8: TRadioButton
      Tag = 145
      Left = 624
      Top = 104
      Width = 177
      Height = 17
      Caption = 'KAPOSV'#193'RI K'#214'RZET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object RadioButton9: TRadioButton
      Tag = 180
      Left = 312
      Top = 136
      Width = 193
      Height = 17
      Caption = 'EXPRESSZ MINIBANK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 8
    end
    object KORZETOKEGOMB: TBitBtn
      Left = 232
      Top = 192
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'RZET RENDBEN'
      TabOrder = 9
    end
    object KORZETVISSZAGOMB: TBitBtn
      Left = 424
      Top = 192
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 10
    end
  end
  object KFTVALASZTOPANEL: TPanel
    Left = -2400
    Top = -200
    Width = 856
    Height = 250
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 4
    Visible = False
    object Label7: TLabel
      Left = 248
      Top = 8
      Width = 358
      Height = 25
      Caption = 'V'#193'LASSZA KI A KIV'#193'NT KFT-T'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Shape3: TShape
      Left = 240
      Top = 192
      Width = 370
      Height = 40
      Pen.Width = 2
      Shape = stRoundRect
    end
    object RadioButton10: TRadioButton
      Tag = 1
      Left = 240
      Top = 64
      Width = 321
      Height = 17
      Caption = 'Exclusive Best Change Kft'
      Checked = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      TabStop = True
    end
    object RadioButton11: TRadioButton
      Tag = 2
      Left = 240
      Top = 96
      Width = 281
      Height = 17
      Caption = 'Exclusive East Change Kft.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object RadioButton12: TRadioButton
      Tag = 3
      Left = 240
      Top = 128
      Width = 305
      Height = 17
      Caption = 'Exclusive Pannon Change Kft.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object RadioButton13: TRadioButton
      Tag = 4
      Left = 240
      Top = 160
      Width = 369
      Height = 17
      Caption = 'Expressz '#201'kszerh'#225'z '#233's Minibank Kft.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object KFTOKEGOMB: TBitBtn
      Left = 248
      Top = 200
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'KFT RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object KFTVISSZAGOMB: TBitBtn
      Left = 425
      Top = 200
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object RECDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 16
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 16
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 56
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 56
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 56
  end
  object WQUERY: TIBQuery
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 104
  end
  object WDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\V143.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 104
  end
  object WTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 88
    Top = 104
  end
  object GYQUERY: TIBQuery
    Database = GYDBASE
    Transaction = GYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 168
  end
  object GYDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:c:\RECEPTOR\DATABASE\WESTUNI.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 168
  end
  object GYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 88
    Top = 168
  end
  object wTabla: TIBTable
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 112
  end
end
