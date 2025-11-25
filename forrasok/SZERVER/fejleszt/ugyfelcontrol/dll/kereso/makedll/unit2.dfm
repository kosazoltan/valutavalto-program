object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 498
  ClientWidth = 1001
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
  object MENUPANEL: TPanel
    Left = 100
    Top = 80
    Width = 369
    Height = 241
    BevelOuter = bvNone
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 369
      Height = 241
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 136
      Top = 16
      Width = 93
      Height = 31
      Caption = 'MEN'#368
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object KERESOGOMB: TPanel
      Left = 24
      Top = 72
      Width = 321
      Height = 33
      Cursor = crHandPoint
      Caption = 'Egy '#252'gyf'#233'l megkeres'#233'se'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = Nevkereses
    end
    object LETILTOGOMB: TPanel
      Left = 24
      Top = 112
      Width = 321
      Height = 33
      Cursor = crHandPoint
      Caption = #220'gyfelek letilt'#225'sa, felold'#225'sa'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = LetiltoGombClick
    end
    object KILEPOGOMB: TPanel
      Left = 24
      Top = 184
      Width = 321
      Height = 33
      Cursor = crHandPoint
      Caption = 'Vissza a f'#337'men'#369're'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = Button1Click
    end
  end
  object KERESOPANEL: TPanel
    Left = -1998
    Top = 100
    Width = 641
    Height = 273
    BevelOuter = bvNone
    Color = 16311512
    TabOrder = 1
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 641
      Height = 273
      Align = alClient
      Brush.Color = 16311512
      Pen.Color = clNavy
      Pen.Width = 2
    end
    object Label2: TLabel
      Left = 112
      Top = 16
      Width = 397
      Height = 31
      Caption = 'Egy '#252'gyf'#233'l adatainak megtekint'#233'se'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 24
      Top = 80
      Width = 251
      Height = 22
      Caption = 'V'#225'lassza ki a vizsg'#225'land'#243' '#233'vet:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 296
      Top = 168
      Width = 271
      Height = 21
      Caption = 'A keresend'#337' '#252'gyf'#233'l nev'#233'nek kezdete:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Panel1: TPanel
      Left = 16
      Top = 128
      Width = 241
      Height = 129
      BevelOuter = bvNone
      Color = 13697023
      TabOrder = 0
      object Label4: TLabel
        Left = 16
        Top = 16
        Width = 216
        Height = 27
        Caption = #220'GYF'#201'L T'#205'PUSA'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Elephant'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object NRADIO: TRadioButton
        Left = 24
        Top = 64
        Width = 209
        Height = 17
        Caption = 'Term'#233'szetes szem'#233'ly'
        Checked = True
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
        TabStop = True
        OnClick = JRADIOClick
      end
      object JRADIO: TRadioButton
        Left = 24
        Top = 96
        Width = 153
        Height = 17
        Caption = 'Jogi szem'#233'ly'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = JRADIOClick
      end
    end
    object evcombo: TComboBox
      Left = 288
      Top = 76
      Width = 73
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 1
      Text = '2022'
      OnChange = evcomboChange
    end
    object nevedit: TEdit
      Left = 304
      Top = 192
      Width = 253
      Height = 30
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnEnter = NEVEDITEnter
      OnExit = NEVEDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object BitBtn3: TBitBtn
      Left = 520
      Top = 240
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = BitBtn3Click
    end
  end
  object NATURPANEL: TPanel
    Left = -1999
    Top = 24
    Width = 913
    Height = 441
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object Label6: TLabel
      Left = 128
      Top = 16
      Width = 346
      Height = 24
      Caption = 'A keresett szem'#233'ly nev'#233'nek eleje:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 40
      Top = 408
      Width = 420
      Height = 24
      Caption = #220'gyf'#233'l kiv'#225'laszt'#225'sa -> dupla-klikk vagy ENTER'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object NATURRACS: TDBGrid
      Left = 16
      Top = 48
      Width = 881
      Height = 353
      Cursor = crHandPoint
      DataSource = NATURSOURCE
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = NATURRACSDblClick
      OnKeyDown = NATURRACSKeyDown
    end
    object EVPANEL: TPanel
      Left = 16
      Top = 16
      Width = 81
      Height = 25
      Caption = '2022'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object KERNEVEDIT: TEdit
      Left = 480
      Top = 16
      Width = 209
      Height = 28
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel2: TPanel
      Left = 696
      Top = 16
      Width = 201
      Height = 25
      Caption = 'TERM'#201'SZETES SZEM'#201'LY'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object NATURVISSZAGOMB: TPanel
      Left = 712
      Top = 408
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      Color = clWhite
      TabOrder = 4
      OnClick = NATURVISSZAGOMBClick
    end
  end
  object JOGIPANEL: TPanel
    Left = -1999
    Top = 16
    Width = 913
    Height = 441
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 3
    Visible = False
    object Label8: TLabel
      Left = 176
      Top = 8
      Width = 291
      Height = 23
      Caption = 'Jogi szem'#233'ly nev'#233'nek kezdete:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label9: TLabel
      Left = 48
      Top = 408
      Width = 418
      Height = 24
      Caption = #220'gyf'#233'l kiv'#225'laszt'#225'sa -> dupla klikk vagy ENTER'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object JOGIRACS: TDBGrid
      Left = 16
      Top = 40
      Width = 881
      Height = 361
      Cursor = crHandPoint
      DataSource = JOGISOURCE
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = NATURRACSDblClick
      OnKeyDown = NATURRACSKeyDown
    end
    object JEVPANEL: TPanel
      Left = 24
      Top = 8
      Width = 81
      Height = 25
      Caption = '2020'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object JKERNEVEDIT: TEdit
      Left = 472
      Top = 8
      Width = 209
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel3: TPanel
      Left = 688
      Top = 8
      Width = 209
      Height = 25
      Caption = 'JOGI SZEM'#201'LY'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object JOGIVISSZAGOMB: TBitBtn
      Left = 712
      Top = 408
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 4
      OnClick = Button1Click
    end
  end
  object INFORMACIOPANEL: TPanel
    Left = -1999
    Top = 8
    Width = 985
    Height = 481
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 4
    Visible = False
    object NATURDATAPANEL: TPanel
      Left = -1999
      Top = 16
      Width = 481
      Height = 450
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      object Label10: TLabel
        Left = 48
        Top = 53
        Width = 96
        Height = 16
        Caption = #220'GYF'#201'L NEVE:'
      end
      object Label11: TLabel
        Left = 56
        Top = 82
        Width = 88
        Height = 16
        Caption = 'EL'#214'Z'#336' NEVE:'
      end
      object Label12: TLabel
        Left = 24
        Top = 111
        Width = 119
        Height = 16
        Caption = 'LE'#193'NYKORI NEVE:'
      end
      object Label13: TLabel
        Left = 56
        Top = 140
        Width = 87
        Height = 16
        Caption = 'ANYJA NEVE:'
      end
      object Label14: TLabel
        Left = 24
        Top = 169
        Width = 122
        Height = 16
        Caption = 'SZ'#220'LET'#201'SI HELYE:'
      end
      object Label15: TLabel
        Left = 40
        Top = 198
        Width = 103
        Height = 16
        Caption = 'SZ'#220'LET'#201'SI ID'#336':'
      end
      object Label16: TLabel
        Left = 48
        Top = 227
        Width = 96
        Height = 16
        Caption = #193'LLAMPOLG'#193'R'
      end
      object Label17: TLabel
        Left = 88
        Top = 256
        Width = 52
        Height = 16
        Caption = 'LAKC'#205'M:'
      end
      object Label18: TLabel
        Left = 48
        Top = 285
        Width = 99
        Height = 16
        Caption = 'OKM'#193'NYTIPUS:'
      end
      object Label19: TLabel
        Left = 64
        Top = 314
        Width = 77
        Height = 16
        Caption = 'AZONOSIT'#211
      end
      object Label20: TLabel
        Left = 64
        Top = 343
        Width = 81
        Height = 16
        Caption = 'TART-I HELY:'
      end
      object Label21: TLabel
        Left = 32
        Top = 372
        Width = 108
        Height = 16
        Caption = 'LAKCIM K'#193'RTYA:'
      end
      object Label22: TLabel
        Left = 80
        Top = 401
        Width = 64
        Height = 16
        Caption = 'ST'#193'TUSZ:'
      end
      object Label23: TLabel
        Left = 48
        Top = 16
        Width = 375
        Height = 24
        Caption = 'TERM'#201'SZETES SZEM'#201'LY ADATAI'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object UGYNEVEDIT: TEdit
        Left = 152
        Top = 50
        Width = 313
        Height = 27
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
        Text = 'UGYNEVEDIT'
      end
      object ELONEVEDIT: TEdit
        Left = 152
        Top = 79
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 1
        Text = 'ELONEVEDIT'
      end
      object LEANYEDIT: TEdit
        Left = 152
        Top = 108
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 2
        Text = 'LEANYEDIT'
      end
      object ANYJAEDIT: TEdit
        Left = 152
        Top = 137
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 3
        Text = 'ANYJAEDIT'
      end
      object SZULHELYEDIT: TEdit
        Left = 152
        Top = 166
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 4
        Text = 'SZULHELYEDIT'
      end
      object SZULIDOEDIT: TEdit
        Left = 152
        Top = 195
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 5
        Text = 'SZULIDOEDIT'
      end
      object ALLAMPOLGAREDIT: TEdit
        Left = 152
        Top = 224
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 6
        Text = 'ALLAMPOLGAREDIT'
      end
      object LAKCIMEDIT: TEdit
        Left = 152
        Top = 253
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 7
        Text = 'LAKCIMEDIT'
      end
      object OKMTIPEDIT: TEdit
        Left = 152
        Top = 282
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 8
        Text = 'OKMTIPEDIT'
      end
      object AZONOSITOEDIT: TEdit
        Left = 152
        Top = 311
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 9
        Text = 'AZONOSITOEDIT'
      end
      object TARTHELYEDIT: TEdit
        Left = 152
        Top = 340
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 10
        Text = 'TARTHELYEDIT'
      end
      object LCIMCARDEDIT: TEdit
        Left = 152
        Top = 369
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 11
        Text = 'LCIMCARDEDIT'
      end
      object STATUSZEDIT: TEdit
        Left = 152
        Top = 398
        Width = 313
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        TabOrder = 12
        Text = 'STATUSZEDIT'
      end
    end
    object BIZPANEL: TPanel
      Left = 528
      Top = 256
      Width = 436
      Height = 209
      BevelOuter = bvNone
      TabOrder = 1
      object Label25: TLabel
        Left = 64
        Top = 16
        Width = 333
        Height = 24
        Caption = 'TRANZAKCI'#211'K BIZONYLATAI'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object Label31: TLabel
        Left = 64
        Top = 184
        Width = 321
        Height = 18
        Caption = 'BIZONYLAT MEGMUTAT'#193'SA -> DUPLA KLIKK'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object BIZRACS: TDBGrid
        Left = 16
        Top = 48
        Width = 401
        Height = 129
        Cursor = crHandPoint
        DataSource = BIZSOURCE
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        OnCellClick = BIZRACSCellClick
        OnDblClick = BizRacsDblClick
        OnKeyUp = BIZRACSKeyUp
      end
    end
    object TRANZPANEL: TPanel
      Left = 528
      Top = 16
      Width = 433
      Height = 233
      BevelOuter = bvNone
      TabOrder = 2
      object Label24: TLabel
        Left = 88
        Top = 16
        Width = 267
        Height = 24
        Caption = 'TRANZAKCI'#211'K ADATAI'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object Label26: TLabel
        Left = 40
        Top = 64
        Width = 220
        Height = 16
        Caption = #220'GYF'#201'L TRANZAKCI'#211'INAK SZ'#193'MA:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label27: TLabel
        Left = 40
        Top = 96
        Width = 186
        Height = 16
        Caption = 'AZ '#201'VES MAXIM'#193'LIS V'#193'LT'#193'S:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label28: TLabel
        Left = 48
        Top = 128
        Width = 155
        Height = 16
        Caption = 'AZ '#201'VI '#214'SSZES V'#193'LT'#193'S:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label29: TLabel
        Left = 136
        Top = 160
        Width = 158
        Height = 22
        Caption = 'UTOLS'#211' V'#193'LT'#193'S'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label30: TLabel
        Left = 200
        Top = 192
        Width = 23
        Height = 24
        Caption = '-->'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object TDBPANEL: TPanel
        Left = 264
        Top = 56
        Width = 103
        Height = 25
        BevelOuter = bvNone
        Caption = ' '
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object EVIMAXPANEL: TPanel
        Left = 232
        Top = 88
        Width = 145
        Height = 25
        BevelOuter = bvNone
        Caption = ' '
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object EVISUMPANEL: TPanel
        Left = 208
        Top = 120
        Width = 153
        Height = 25
        BevelOuter = bvNone
        Caption = ' '
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object Panel4: TPanel
        Left = 16
        Top = 158
        Width = 401
        Height = 2
        BevelOuter = bvNone
        Caption = ' '
        Color = clRed
        TabOrder = 3
      end
      object QDATUMPANEL: TPanel
        Left = 40
        Top = 192
        Width = 145
        Height = 25
        BevelOuter = bvNone
        Caption = ' '
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object LASTTRANZPANEL: TPanel
        Left = 240
        Top = 192
        Width = 145
        Height = 25
        BevelOuter = bvNone
        Caption = ' '
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
      end
    end
    object BACKGOMB: TPanel
      Left = 568
      Top = 240
      Width = 177
      Height = 25
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Vissza a list'#225'hoz'
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGreen
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = BACKGOMBClick
    end
    object SCANGOMB: TPanel
      Left = 760
      Top = 240
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'Szkennelt okm'#225'nyai'
      Color = clMoneyGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = SCANGOMBClick
    end
    object TILTOTTPANEL: TPanel
      Left = -1999
      Top = 88
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Caption = 'TILTOTT !'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
      Visible = False
    end
    object JOGIDATAPANEL: TPanel
      Left = 32
      Top = 16
      Width = 481
      Height = 450
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      object Label32: TLabel
        Left = 112
        Top = 24
        Width = 263
        Height = 24
        Caption = 'JOGI SZEM'#201'LY ADATAI'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object Label33: TLabel
        Left = 62
        Top = 83
        Width = 104
        Height = 16
        Caption = 'MEGNEVEZ'#201'SE:'
      end
      object Label34: TLabel
        Left = 56
        Top = 114
        Width = 115
        Height = 16
        Caption = 'TELEPHELY C'#205'ME:'
      end
      object Label35: TLabel
        Left = 72
        Top = 146
        Width = 97
        Height = 16
        Caption = 'OKIRATSZ'#193'MA:'
      end
      object Label36: TLabel
        Left = 40
        Top = 178
        Width = 134
        Height = 16
        Caption = 'F'#336' TEV'#201'KENYS'#201'GE:'
      end
      object Label37: TLabel
        Left = 62
        Top = 242
        Width = 120
        Height = 16
        Cursor = 242
        Caption = 'MEGBIZOTT NEVE:'
      end
      object Label38: TLabel
        Left = 16
        Top = 274
        Width = 164
        Height = 16
        Caption = 'MEGBIZOTT BEOSZT'#193'SA:'
      end
      object Label39: TLabel
        Left = 62
        Top = 306
        Width = 119
        Height = 16
        Caption = 'K'#201'PVISEL'#336' NEVE:'
      end
      object Label40: TLabel
        Left = 16
        Top = 338
        Width = 163
        Height = 16
        Caption = 'K'#201'PVISEL'#336' BEOSZT'#193'SA:'
      end
      object Label41: TLabel
        Left = 104
        Top = 370
        Width = 73
        Height = 16
        Caption = 'ST'#193'TUSZA:'
      end
      object JOGINEVEDIT: TEdit
        Left = 176
        Top = 82
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
        Text = 'JOGINEVEDIT'
      end
      object TELEPHELYEDIT: TEdit
        Left = 176
        Top = 114
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
        Text = 'TELEPHELYEDIT'
      end
      object OKIRATEDIT: TEdit
        Left = 176
        Top = 146
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 2
        Text = 'OKIRATEDIT'
      end
      object FOTEVEKENYEDIT: TEdit
        Left = 176
        Top = 178
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 3
        Text = 'FOTEVEKENYEDIT'
      end
      object MBNEVEDIT: TEdit
        Left = 184
        Top = 242
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 4
        Text = 'MBNEVEDIT'
      end
      object MBBEOEDIT: TEdit
        Left = 184
        Top = 274
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 5
        Text = 'MBBEOEDIT'
      end
      object KEPVISNEVEDIT: TEdit
        Left = 184
        Top = 306
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 6
        Text = 'KEPVISNEVEDIT'
      end
      object KEPVISBEOEDIT: TEdit
        Left = 184
        Top = 338
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 7
        Text = 'KEPVISBEOEDIT'
      end
      object JSTATUSZEDIT: TEdit
        Left = 184
        Top = 370
        Width = 273
        Height = 24
        BorderStyle = bsNone
        Color = clBtnFace
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 8
        Text = 'JSTATUSZEDIT'
      end
      object Panel5: TPanel
        Left = 16
        Top = 220
        Width = 449
        Height = 3
        Caption = ' '
        TabOrder = 9
      end
      object SCANASKPANEL: TPanel
        Left = -1999
        Top = 232
        Width = 457
        Height = 201
        BevelOuter = bvNone
        Color = clWhite
        TabOrder = 10
        object Label42: TLabel
          Left = 96
          Top = 48
          Width = 275
          Height = 24
          Caption = 'K'#201'REM A RECEPTORT'#211'L'
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -21
          Font.Name = 'Cooper Black'
          Font.Style = []
          ParentFont = False
        end
        object Label43: TLabel
          Left = 64
          Top = 104
          Width = 337
          Height = 24
          Caption = 'A BESZKENNELT OKM'#193'NYAIT'
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -21
          Font.Name = 'Cooper Black'
          Font.Style = []
          ParentFont = False
        end
      end
    end
  end
  object blokkpanel: TPanel
    Left = -2224
    Top = 16
    Width = 593
    Height = 480
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 5
    Visible = False
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 593
      Height = 480
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label44: TLabel
      Left = 32
      Top = 112
      Width = 105
      Height = 19
      Caption = 'P'#201'NZT'#193'ROS:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label49: TLabel
      Left = 72
      Top = 216
      Width = 70
      Height = 21
      Caption = 'Valut'#225'k'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label45: TLabel
      Left = 32
      Top = 144
      Width = 107
      Height = 19
      Caption = 'Bizonylatsz'#225'm:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label46: TLabel
      Left = 88
      Top = 176
      Width = 52
      Height = 19
      Caption = 'D'#225'tum:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label47: TLabel
      Left = 360
      Top = 144
      Width = 86
      Height = 19
      Caption = 'Kezel'#233'si d'#237'j:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label48: TLabel
      Left = 352
      Top = 176
      Width = 95
      Height = 19
      Caption = #214'sszes forint:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label50: TLabel
      Left = 208
      Top = 216
      Width = 82
      Height = 21
      Caption = #193'rfolyam'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label51: TLabel
      Left = 320
      Top = 216
      Width = 101
      Height = 21
      Caption = 'Elsz'#225'mol'#225'si'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label52: TLabel
      Left = 456
      Top = 216
      Width = 95
      Height = 21
      Caption = 'Forint'#233'rt'#233'k'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object TTPANEL: TPanel
      Left = 32
      Top = 24
      Width = 537
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object PTPANEL: TPanel
      Left = 32
      Top = 64
      Width = 537
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object PROSPANEL: TPanel
      Left = 144
      Top = 104
      Width = 305
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object FIZESZKOZPANEL: TPanel
      Left = 456
      Top = 104
      Width = 113
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object Panel6: TPanel
      Left = 24
      Top = 202
      Width = 553
      Height = 3
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 4
    end
    object Panel7: TPanel
      Left = 200
      Top = 208
      Width = 3
      Height = 241
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 5
    end
    object Panel8: TPanel
      Left = 310
      Top = 208
      Width = 3
      Height = 241
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 6
    end
    object Panel9: TPanel
      Left = 432
      Top = 208
      Width = 3
      Height = 241
      BevelOuter = bvNone
      Color = clRed
      TabOrder = 7
    end
    object V1: TPanel
      Left = 8
      Top = 240
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
    end
    object V2: TPanel
      Left = 8
      Top = 272
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 9
    end
    object V3: TPanel
      Left = 8
      Top = 304
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 10
    end
    object V5: TPanel
      Left = 8
      Top = 368
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 11
    end
    object V6: TPanel
      Left = 8
      Top = 400
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 12
    end
    object V4: TPanel
      Left = 8
      Top = 336
      Width = 185
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 13
    end
    object A1: TPanel
      Left = 216
      Top = 240
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 14
    end
    object A2: TPanel
      Left = 216
      Top = 272
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 15
    end
    object A4: TPanel
      Left = 216
      Top = 336
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 16
    end
    object A5: TPanel
      Left = 216
      Top = 368
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 17
    end
    object A6: TPanel
      Left = 216
      Top = 400
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 18
    end
    object A3: TPanel
      Left = 216
      Top = 304
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 19
    end
    object E1: TPanel
      Left = 336
      Top = 240
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 20
    end
    object E2: TPanel
      Left = 336
      Top = 272
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 21
    end
    object E3: TPanel
      Left = 336
      Top = 304
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 22
    end
    object E4: TPanel
      Left = 336
      Top = 336
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 23
    end
    object E5: TPanel
      Left = 336
      Top = 368
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 24
    end
    object E6: TPanel
      Left = 336
      Top = 400
      Width = 73
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 25
    end
    object F2: TPanel
      Left = 448
      Top = 272
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 26
    end
    object F1: TPanel
      Left = 448
      Top = 240
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 27
    end
    object F3: TPanel
      Left = 448
      Top = 304
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 28
    end
    object F4: TPanel
      Left = 448
      Top = 336
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 29
    end
    object F5: TPanel
      Left = 448
      Top = 368
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 30
    end
    object F6: TPanel
      Left = 448
      Top = 400
      Width = 129
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 31
    end
    object BLOKKVISSZAGOMB: TBitBtn
      Left = 240
      Top = 448
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 32
      OnClick = BLOKKVISSZAGOMBClick
    end
    object WBIZPANEL: TPanel
      Left = 144
      Top = 144
      Width = 115
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 33
    end
    object WDATIDO: TPanel
      Left = 144
      Top = 174
      Width = 153
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 34
    end
    object KEZDIJPANEL: TPanel
      Left = 456
      Top = 144
      Width = 120
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 35
    end
    object FIZETENDOPANEL: TPanel
      Left = 456
      Top = 174
      Width = 120
      Height = 25
      BevelOuter = bvNone
      Caption = ' '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 36
    end
  end
  object NQUERY: TIBQuery
    Database = NDBASE
    Transaction = NTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 328
  end
  object NDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 328
  end
  object NTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 328
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 832
    Top = 392
  end
  object JQUERY: TIBQuery
    Database = JDBASE
    Transaction = JTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 424
  end
  object BIZDBASE: TIBDatabase
    DatabaseName = ':'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 864
    Top = 392
  end
  object JDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 424
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 896
    Top = 392
  end
  object JTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 424
  end
  object NATURSOURCE: TDataSource
    DataSet = NQUERY
    Left = 16
    Top = 192
  end
  object JOGISOURCE: TDataSource
    DataSet = JQUERY
    Left = 16
    Top = 160
  end
  object BIZSOURCE: TDataSource
    DataSet = BIZQUERY
    Left = 800
    Top = 392
  end
  object BIZLATOKQUERY: TIBQuery
    Database = BIZLATOKDBASE
    Transaction = BIZLATOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 384
  end
  object BIZLATOKDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZLATOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 384
  end
  object BIZLATOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZLATOKDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 384
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 40
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 40
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 40
  end
end
