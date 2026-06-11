object TRANZDIJ: TTRANZDIJ
  Left = 191
  Top = 141
  Width = 1237
  Height = 770
  Caption = 'TRANZDIJ'
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
  object Shape4: TShape
    Left = 904
    Top = 548
    Width = 73
    Height = 25
    Brush.Color = clBtnFace
    Shape = stEllipse
  end
  object Label2: TLabel
    Left = 192
    Top = 8
    Width = 732
    Height = 41
    Caption = 'A TRANZAKCI'#211'S ILLET'#201'KEK MEGHAT'#193'ROZ'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 912
    Top = 552
    Width = 54
    Height = 13
    Caption = 'dekanySoft'
  end
  object MENUPANEL: TPanel
    Left = 750
    Top = 88
    Width = 441
    Height = 260
    TabOrder = 0
    object Shape3: TShape
      Left = 1
      Top = 1
      Width = 439
      Height = 258
      Align = alClient
      Pen.Color = clRed
    end
    object HAVIBEDOLGGOMB: TBitBtn
      Left = 8
      Top = 40
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY H'#211'NAP BEDOLGOZ'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = HAVIBEDOLGGOMBClick
    end
    object NAPIBEDOLGGOMB: TBitBtn
      Left = 8
      Top = 80
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY NAP BEDOLGOZ'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NAPIBEDOLGGOMBClick
    end
    object SETMNBGOMB: TBitBtn
      Left = 72
      Top = 160
      Width = 321
      Height = 25
      Cursor = crHandPoint
      Caption = 'MNB '#193'RFOLYAM BEIR'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = SETMNBGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 120
      Top = 200
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
    object BitBtn3: TBitBtn
      Left = 8
      Top = 120
      Width = 425
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK KIMUTAT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = BitBtn3Click
    end
  end
  object NAPTARPANEL: TPanel
    Left = 16
    Top = 300
    Width = 385
    Height = 273
    TabOrder = 1
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 383
      Height = 271
      Pen.Color = clRed
    end
    object NAPTAR: TCalendar
      Left = 40
      Top = 56
      Width = 320
      Height = 120
      StartOfWeek = 0
      TabOrder = 0
      OnChange = NAPTARChange
    end
    object BitBtn1: TBitBtn
      Left = 24
      Top = 16
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = '<<     el'#246'z'#337' h'#243'nap'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn1Click
    end
    object BitBtn2: TBitBtn
      Left = 200
      Top = 16
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'k'#246'vetkez'#337' h'#243'nap   >>'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = BitBtn2Click
    end
    object NAPTARDATUMPANEL: TPanel
      Left = 40
      Top = 184
      Width = 321
      Height = 33
      Caption = '2013 szeptember 30'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object DATUMOKEGOMB: TBitBtn
      Left = 40
      Top = 232
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#193'TUM RENDBEN'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = DATUMOKEGOMBClick
    end
    object DATUMMEGSEMGOMB: TBitBtn
      Left = 216
      Top = 232
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = DATUMMEGSEMGOMBClick
    end
  end
  object memopanel: TPanel
    Left = 52
    Top = 80
    Width = 473
    Height = 513
    BevelOuter = bvNone
    TabOrder = 2
    object Label1: TLabel
      Left = 112
      Top = 8
      Width = 245
      Height = 27
      Caption = 'Az adatgy'#252'jt'#233's folyamata'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object MemoTabla: TMemo
      Left = 8
      Top = 40
      Width = 449
      Height = 441
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        'MemoTabla')
      ParentFont = False
      TabOrder = 0
    end
  end
  object CSIKPANEL: TPanel
    Left = 56
    Top = 608
    Width = 881
    Height = 97
    BevelOuter = bvNone
    TabOrder = 3
    object Shape2: TShape
      Left = 16
      Top = 24
      Width = 849
      Height = 60
      Pen.Width = 2
      Shape = stRoundRect
    end
    object CSIK: TProgressBar
      Left = 32
      Top = 56
      Width = 817
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 0
    end
    object CSIK2: TProgressBar
      Left = 32
      Top = 32
      Width = 817
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 1
    end
  end
  object DISPLAYMENUPANEL: TPanel
    Left = 416
    Top = 408
    Width = 457
    Height = 193
    TabOrder = 4
    object Shape5: TShape
      Left = 1
      Top = 1
      Width = 455
      Height = 191
      Align = alClient
      Pen.Color = clRed
    end
    object Label4: TLabel
      Left = 200
      Top = 40
      Width = 52
      Height = 23
      Caption = 'VAGY.'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 112
      Top = 80
      Width = 217
      Height = 23
      Caption = 'ADATAIT MUTASSAM KI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object EGYNAPADATAIGOMB: TBitBtn
      Left = 40
      Top = 40
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY NAP'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = EGYNAPADATAIGOMBClick
    end
    object EGYHOADATAIGOMB: TBitBtn
      Left = 264
      Top = 40
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY H'#211'NAP'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = EGYHOADATAIGOMBClick
    end
    object DMEGSEMGOMB: TBitBtn
      Left = 160
      Top = 128
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = DMEGSEMGOMBClick
    end
  end
  object DISPLAYPANEL: TPanel
    Left = 24
    Top = -256
    Width = 945
    Height = 665
    BevelOuter = bvNone
    TabOrder = 5
    object displayracs: TDBGrid
      Left = 8
      Top = 40
      Width = 921
      Height = 502
      BorderStyle = bsNone
      Color = 11599871
      DataSource = DISPLAYSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'CASHIER'
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'R'
          Width = 58
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'NAP'
          Title.Alignment = taCenter
          Width = 34
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BUYLOW'
          Title.Alignment = taCenter
          Title.Caption = 'V'#201'TEL'
          Width = 71
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BUYHIPIECE'
          Title.Alignment = taCenter
          Title.Caption = '3 M FELETT'
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BUYHI'
          Title.Alignment = taCenter
          Title.Caption = 'NAGYV'#201'T'
          Width = 85
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SELLLOW'
          Title.Alignment = taCenter
          Title.Caption = 'ELAD'#193'S'
          Width = 67
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SELLHIPIECE'
          Title.Alignment = taCenter
          Title.Caption = '3M FELETT'
          Width = 51
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SELLHI'
          Title.Alignment = taCenter
          Title.Caption = 'NAGYELAD'
          Width = 74
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'CONVLOW'
          Title.Alignment = taCenter
          Title.Caption = 'KONVER'
          Width = 71
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'CONVHIPIECE'
          Title.Alignment = taCenter
          Title.Caption = '3M FELETT'
          Width = 51
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'CONVHI'
          Title.Alignment = taCenter
          Title.Caption = 'NAGYKONV'
          Width = 76
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TRANSFEE'
          Title.Alignment = taCenter
          Title.Caption = 'TRANZ.D'#205'J'
          Width = 91
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'HIBASE'
          Title.Alignment = taCenter
          Title.Caption = 'NAGY-ALAP'
          Width = 77
          Visible = True
        end>
    end
    object DISPVISSZAGOMB: TBitBtn
      Left = 744
      Top = 576
      Width = 171
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = DISPVISSZAGOMBClick
    end
    object SSELLHI: TPanel
      Left = 509
      Top = 515
      Width = 78
      Height = 25
      Caption = '123.235.000'
      Color = clMoneyGreen
      TabOrder = 2
    end
    object SBUY: TPanel
      Left = 108
      Top = 515
      Width = 83
      Height = 25
      Caption = 'SBUY'
      Color = clMoneyGreen
      TabOrder = 3
    end
    object SBUYHI: TPanel
      Left = 261
      Top = 515
      Width = 90
      Height = 25
      Caption = 'SBUYHI'
      Color = clMoneyGreen
      TabOrder = 4
    end
    object SSELL: TPanel
      Left = 355
      Top = 515
      Width = 85
      Height = 25
      Caption = 'SSELL'
      Color = clMoneyGreen
      TabOrder = 5
    end
    object SCONV: TPanel
      Left = 590
      Top = 515
      Width = 82
      Height = 25
      Caption = 'SCONV'
      Color = clMoneyGreen
      TabOrder = 6
    end
    object SCONVHI: TPanel
      Left = 741
      Top = 515
      Width = 81
      Height = 25
      Caption = 'SCONVHI'
      Color = clMoneyGreen
      TabOrder = 7
    end
    object SSFEE: TPanel
      Left = 824
      Top = 515
      Width = 89
      Height = 25
      Caption = 'SSFEE'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object SBUYHP: TPanel
      Left = 194
      Top = 515
      Width = 64
      Height = 25
      Caption = 'SBUYHP'
      Color = clMoneyGreen
      TabOrder = 9
    end
    object SSELLHP: TPanel
      Left = 444
      Top = 515
      Width = 61
      Height = 25
      Caption = 'SSELLHP'
      Color = clMoneyGreen
      TabOrder = 10
    end
    object SCONVHP: TPanel
      Left = 675
      Top = 515
      Width = 62
      Height = 25
      Caption = 'SCONVHP'
      Color = clMoneyGreen
      TabOrder = 11
    end
    object Panel11: TPanel
      Left = 8
      Top = 515
      Width = 98
      Height = 25
      Caption = #214'SSZESEN:'
      Color = clMoneyGreen
      TabOrder = 12
    end
    object ALLGOMB: TBitBtn
      Left = 16
      Top = 576
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'MINDEN P'#201'NZT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 13
      OnClick = ALLGOMBClick
    end
    object BESTGOMB: TBitBtn
      Left = 208
      Top = 576
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEST CHANGE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 14
      OnClick = BESTGOMBClick
    end
    object EASTGOMB: TBitBtn
      Left = 384
      Top = 576
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'EAST CHANGE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 15
      OnClick = EASTGOMBClick
    end
    object PANNONGOMB: TBitBtn
      Left = 568
      Top = 576
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'PANNON CHANGE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 16
      OnClick = PANNONGOMBClick
    end
    object UGYFELPANEL: TPanel
      Left = 160
      Top = 543
      Width = 89
      Height = 30
      Color = 11599871
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 17
    end
    object Panel2: TPanel
      Left = 13
      Top = 543
      Width = 145
      Height = 30
      Caption = #220'gyfelek sz'#225'ma:'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 18
    end
    object HIBASEPANEL: TPanel
      Left = 768
      Top = 543
      Width = 145
      Height = 30
      Caption = '123 456 789'
      Color = 16756991
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 19
    end
    object Panel3: TPanel
      Left = 632
      Top = 543
      Width = 129
      Height = 30
      Caption = '3 milli'#243' felett:'
      Color = 16756991
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 20
    end
    object Panel1: TPanel
      Left = 296
      Top = 544
      Width = 121
      Height = 30
      Caption = '3 milli'#243' alatt:'
      Color = 16777136
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 21
    end
    object LOBASEPANEL: TPanel
      Left = 424
      Top = 544
      Width = 161
      Height = 30
      Caption = '123 000 000'
      Color = 16777136
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 22
    end
    object Panel4: TPanel
      Left = 16
      Top = 616
      Width = 121
      Height = 25
      Caption = #220'gyf'#233'l v'#233'teln'#233'l:'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 23
    end
    object VUGYFELPANEL: TPanel
      Left = 144
      Top = 616
      Width = 97
      Height = 25
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
    end
    object Panel6: TPanel
      Left = 256
      Top = 616
      Width = 121
      Height = 25
      Caption = #220'gyfel el'#225'd'#225'sn'#225'l:'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 25
    end
    object EUGYFELPANEL: TPanel
      Left = 384
      Top = 616
      Width = 97
      Height = 25
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
    end
    object VLOBASEPANEL: TPanel
      Left = 576
      Top = 604
      Width = 97
      Height = 25
      Color = 16777136
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 27
    end
    object VHIBASEPANEL: TPanel
      Left = 576
      Top = 632
      Width = 97
      Height = 25
      Color = 16756991
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 28
    end
    object EHIBASEPANEL: TPanel
      Left = 816
      Top = 632
      Width = 97
      Height = 25
      Color = 16756991
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 29
    end
    object ELOBASEPANEL: TPanel
      Left = 816
      Top = 604
      Width = 97
      Height = 25
      Color = 16777136
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 30
    end
    object Panel10: TPanel
      Left = 492
      Top = 616
      Width = 81
      Height = 25
      Caption = 'V'#201'TEL'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 31
    end
    object Panel12: TPanel
      Left = 732
      Top = 616
      Width = 81
      Height = 25
      Caption = 'ELAD'#193'S'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 32
    end
  end
  object focimpanel: TPanel
    Left = 136
    Top = 48
    Width = 833
    Height = 25
    BevelOuter = bvNone
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object CEGVALTOPANEL: TPanel
    Left = 440
    Top = 152
    Width = 289
    Height = 57
    Caption = 'C'#201'GV'#193'LT'#193'S'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object TRANZTABLA: TIBTable
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'CASHIER'
        DataType = ftSmallint
      end
      item
        Name = 'DISTRICT'
        DataType = ftSmallint
      end
      item
        Name = 'FIRMLETTER'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'NAP'
        DataType = ftSmallint
      end
      item
        Name = 'NAPKESZ'
        DataType = ftSmallint
      end
      item
        Name = 'BUYLOW'
        DataType = ftFloat
      end
      item
        Name = 'BUYHIPIECE'
        DataType = ftInteger
      end
      item
        Name = 'BUYHI'
        DataType = ftFloat
      end
      item
        Name = 'SELLLOW'
        DataType = ftFloat
      end
      item
        Name = 'SELLHIPIECE'
        DataType = ftInteger
      end
      item
        Name = 'SELLHI'
        DataType = ftFloat
      end
      item
        Name = 'CONVLOW'
        DataType = ftFloat
      end
      item
        Name = 'CONVHIPIECE'
        DataType = ftInteger
      end
      item
        Name = 'CONVHI'
        DataType = ftFloat
      end
      item
        Name = 'TRANSFEE'
        DataType = ftFloat
      end
      item
        Name = 'UGYFEL'
        DataType = ftInteger
      end
      item
        Name = 'HIBASE'
        DataType = ftFloat
      end
      item
        Name = 'LOBASE'
        DataType = ftFloat
      end>
    IndexDefs = <
      item
        Name = 'IDX_TRANZDIJ1301'
        Fields = 'CASHIER;NAP'
      end
      item
        Name = 'ALTXTRANZDIJ1301'
        Fields = 'UGYFEL'
      end>
    IndexFieldNames = 'CASHIER;NAP'
    StoreDefs = True
    TableName = 'TRANZDIJ1301'
    Left = 504
    Top = 80
    object TRANZTABLACASHIER: TSmallintField
      FieldName = 'CASHIER'
    end
    object TRANZTABLADISTRICT: TSmallintField
      FieldName = 'DISTRICT'
    end
    object TRANZTABLAFIRMLETTER: TIBStringField
      FieldName = 'FIRMLETTER'
      FixedChar = True
      Size = 1
    end
    object TRANZTABLANAP: TSmallintField
      FieldName = 'NAP'
    end
    object TRANZTABLANAPKESZ: TSmallintField
      FieldName = 'NAPKESZ'
    end
    object TRANZTABLABUYLOW: TFloatField
      FieldName = 'BUYLOW'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLABUYHIPIECE: TIntegerField
      FieldName = 'BUYHIPIECE'
    end
    object TRANZTABLABUYHI: TFloatField
      FieldName = 'BUYHI'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLASELLLOW: TFloatField
      FieldName = 'SELLLOW'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLASELLHIPIECE: TIntegerField
      FieldName = 'SELLHIPIECE'
    end
    object TRANZTABLASELLHI: TFloatField
      FieldName = 'SELLHI'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLACONVLOW: TFloatField
      FieldName = 'CONVLOW'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLACONVHIPIECE: TIntegerField
      FieldName = 'CONVHIPIECE'
    end
    object TRANZTABLACONVHI: TFloatField
      FieldName = 'CONVHI'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLATRANSFEE: TFloatField
      FieldName = 'TRANSFEE'
      DisplayFormat = '### ### ###'
    end
    object TRANZTABLAUGYFEL: TIntegerField
      FieldName = 'UGYFEL'
    end
    object TRANZTABLAHIBASE: TFloatField
      FieldName = 'HIBASE'
      DisplayFormat = '### ### ### ###'
    end
  end
  object TRANZQUERY: TIBQuery
    Database = TRANZDBASE
    Transaction = TRANZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 536
    Top = 80
  end
  object TRANZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRANZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 568
    Top = 80
  end
  object TRANZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRANZDBASE
    AutoStopAction = saNone
    Left = 600
    Top = 80
  end
  object BFTABLA: TIBTable
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 272
  end
  object BFQUERY: TIBQuery
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 272
  end
  object BFDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 272
  end
  object BFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 280
  end
  object BTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BTDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 160
  end
  object BTDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 160
  end
  object BTQUERY: TIBQuery
    Database = BTDBASE
    Transaction = BTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
    Top = 160
  end
  object ELSZAMQUERY: TIBQuery
    Database = ELSZAMDBASE
    Transaction = ELSZAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
    Top = 200
  end
  object ELSZAMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ELSZAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 200
  end
  object ELSZAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ELSZAMDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 200
  end
  object DISPLAYSOURCE: TDataSource
    DataSet = TRANZTABLA
    Left = 760
    Top = 216
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object RECEPTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECEPTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
end
