object BIZONYLATDISP: TBIZONYLATDISP
  Left = 198
  Top = 174
  BorderStyle = bsNone
  Caption = 'BIZONYLATDISP'
  ClientHeight = 767
  ClientWidth = 1067
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 888
    Top = 504
    Width = 32
    Height = 13
    Caption = 'Label2'
  end
  object Panel1: TPanel
    Left = 344
    Top = 440
    Width = 129
    Height = 33
    Caption = 'NAV NYUGTA'
    Color = 7829367
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Britannic Bold'
    Font.Style = []
    ParentFont = False
    TabOrder = 20
  end
  object blokkfejpanel: TPanel
    Left = 4
    Top = 4
    Width = 333
    Height = 33
    Caption = 'Blokk fejek'
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object BLOKKFEJRACS: TDBGrid
    Left = 4
    Top = 40
    Width = 325
    Height = 641
    Cursor = crHandPoint
    Color = 4210752
    DataSource = FEJSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnCellClick = BLOKKFEJRACSCellClick
    OnDblClick = BLOKKFEJRACSDblClick
    OnKeyUp = BLOKKFEJRACSKeyUp
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'BIZONYLAT'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'OSSZESFORINTERTEK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'BLOKK (FT)'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KEZELESIDIJ'
        Title.Alignment = taCenter
        Title.Caption = 'KEZ-DIJ'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 58
        Visible = True
      end>
  end
  object BLOKKTETELRACS: TDBGrid
    Left = 340
    Top = 40
    Width = 289
    Height = 153
    Color = 4210752
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'BANKJEGY'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'VALUTA'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = #193'RFOLYAM'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FORINTERTEK'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'FORINT'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end>
  end
  object NAPTAR: TCalendar
    Left = 340
    Top = 264
    Width = 270
    Height = 137
    Cursor = crHandPoint
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    StartOfWeek = 0
    TabOrder = 2
    OnChange = NAPTARChange
  end
  object Panel10: TPanel
    Left = 613
    Top = 4
    Width = 400
    Height = 380
    Color = 4210752
    TabOrder = 3
    object Label1: TLabel
      Left = 72
      Top = 8
      Width = 248
      Height = 36
      Caption = #220'GYF'#201'L ADATAI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 96
      Top = 304
      Width = 249
      Height = 16
      Caption = 'TIZ-MILLI'#211' FELETTI TRANZAKCI'#211'K'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Panel20: TPanel
      Left = 176
      Top = 324
      Width = 220
      Height = 23
      TabOrder = 0
      object FORRASEDIT: TEdit
        Left = 0
        Top = 0
        Width = 217
        Height = 23
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel23: TPanel
      Left = 176
      Top = 349
      Width = 220
      Height = 23
      TabOrder = 1
      object ENGEDEDIT: TEdit
        Left = 0
        Top = 0
        Width = 217
        Height = 23
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel5: TPanel
      Left = 8
      Top = 325
      Width = 166
      Height = 21
      HelpContext = 21
      Caption = 'P'#201'NZ FORR'#193'SA'
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel11: TPanel
      Left = 8
      Top = 350
      Width = 166
      Height = 21
      Caption = 'ENGED'#201'LYEZ'#336
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
  end
  object Panel4: TPanel
    Left = 344
    Top = 4
    Width = 265
    Height = 33
    Caption = 'Blokkt'#233'telek'
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object DATUMPANEL: TPanel
    Left = 340
    Top = 194
    Width = 270
    Height = 36
    Caption = '2013 szeptember 23'
    Color = 5263440
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object Panel6: TPanel
    Left = 340
    Top = 232
    Width = 130
    Height = 25
    Cursor = crHandPoint
    Caption = 'El'#246'z'#337' h'#243'nap'
    Color = 7368816
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
    OnClick = Panel6Click
  end
  object Panel7: TPanel
    Left = 472
    Top = 232
    Width = 137
    Height = 25
    Cursor = crHandPoint
    Caption = 'K'#246'vetkez'#337' h'#243
    Color = 7368816
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
    OnClick = Panel7Click
  end
  object Panel2: TPanel
    Left = 4
    Top = 724
    Width = 1005
    Height = 38
    Caption = 'Panel2'
    Color = clBlack
    TabOrder = 9
    object VISSZAGOMB: TBitBtn
      Left = 872
      Top = 8
      Width = 129
      Height = 22
      Cursor = crHandPoint
      Cancel = True
      Caption = 'Vissza a men'#252're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = VISSZAGOMBClick
    end
    object Button1: TButton
      Left = 8
      Top = 8
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'Bizonylatok sz'#369'r'#233'se'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = Button1Click
    end
    object EGESZHONAP: TRadioButton
      Left = 168
      Top = 12
      Width = 225
      Height = 17
      Caption = 'A H'#211'NAP '#214'SSZES BIZONYLATA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = EGESZHONAPClick
    end
    object CSAKNAP: TRadioButton
      Tag = 12
      Left = 392
      Top = 12
      Width = 281
      Height = 17
      Caption = 'CSAK A V'#193'LASZTOTT NAP '
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      TabStop = True
    end
    object REPRINTGOMB: TBitBtn
      Left = 740
      Top = 8
      Width = 129
      Height = 22
      Cursor = crHandPoint
      Caption = #218'jranyomtat'#225's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = Ujranyomtatas
    end
    object OKMANYGOMB: TBitBtn
      Left = 592
      Top = 8
      Width = 145
      Height = 22
      Cursor = crHandPoint
      Caption = 'OKM'#193'NYKIJELZ'#201'S'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = OKMANYGOMBClick
    end
  end
  object Panel8: TPanel
    Left = 616
    Top = 390
    Width = 395
    Height = 187
    Color = 5592405
    TabOrder = 10
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 162
      Height = 23
    end
    object Shape2: TShape
      Left = 8
      Top = 33
      Width = 162
      Height = 23
    end
    object Shape3: TShape
      Left = 8
      Top = 83
      Width = 162
      Height = 23
    end
    object Shape21: TShape
      Left = 8
      Top = 58
      Width = 162
      Height = 23
    end
    object Shape17: TShape
      Left = 8
      Top = 158
      Width = 162
      Height = 23
    end
    object Shape18: TShape
      Left = 8
      Top = 133
      Width = 162
      Height = 23
    end
    object M: TShape
      Left = 8
      Top = 108
      Width = 162
      Height = 23
    end
    object Panel9: TPanel
      Left = 176
      Top = 8
      Width = 214
      Height = 23
      TabOrder = 0
      object DBEdit3: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'JOGISZEMELYNEV'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel37: TPanel
      Left = 176
      Top = 33
      Width = 214
      Height = 23
      TabOrder = 1
      object DBEdit17: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'TELEPHELYCIM'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel38: TPanel
      Left = 176
      Top = 58
      Width = 214
      Height = 23
      TabOrder = 2
      object DBEdit18: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'OKIRATSZAM'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel39: TPanel
      Left = 176
      Top = 83
      Width = 214
      Height = 23
      TabOrder = 3
      object DBEdit19: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'FOTEVEKENYSEG'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel40: TPanel
      Left = 176
      Top = 108
      Width = 214
      Height = 23
      TabOrder = 4
      object DBEdit20: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'MEGBIZOTTBEOSZTASA'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel41: TPanel
      Left = 176
      Top = 133
      Width = 214
      Height = 23
      TabOrder = 5
      object DBEdit21: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'KEPVISELONEV'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel42: TPanel
      Left = 176
      Top = 158
      Width = 214
      Height = 23
      TabOrder = 6
      object DBEdit22: TDBEdit
        Left = 1
        Top = 1
        Width = 212
        Height = 21
        Color = 16756991
        DataField = 'KEPVISBEO'
        DataSource = JOGISOURCE
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object Panel44: TPanel
      Left = 9
      Top = 9
      Width = 160
      Height = 21
      Caption = 'Jogi szem'#233'ly neve'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object Panel45: TPanel
      Left = 9
      Top = 34
      Width = 160
      Height = 21
      Caption = 'Telephely c'#237'me'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 8
    end
    object Panel46: TPanel
      Left = 9
      Top = 59
      Width = 160
      Height = 21
      Caption = 'Okiratsz'#225'm'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 9
    end
    object Panel47: TPanel
      Left = 9
      Top = 84
      Width = 160
      Height = 21
      Caption = 'F'#337'tev'#233'kyns'#233'g'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 10
    end
    object Panel48: TPanel
      Left = 9
      Top = 109
      Width = 160
      Height = 21
      Caption = 'Megbizott beosz'#225'sa'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 11
    end
    object Panel49: TPanel
      Left = 9
      Top = 134
      Width = 160
      Height = 21
      Caption = 'K'#233'pvisel'#337' neve'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 12
    end
    object Panel50: TPanel
      Left = 9
      Top = 159
      Width = 160
      Height = 21
      Caption = 'K'#233'pvisel'#337' beoszt'#225'sa'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 13
    end
  end
  object Panel43: TPanel
    Left = 340
    Top = 584
    Width = 671
    Height = 135
    Color = 5263440
    TabOrder = 11
    object TNEV2PANEL: TPanel
      Tag = 2
      Left = 8
      Top = 40
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = TNEV1PANELClick
    end
    object TNEV1PANEL: TPanel
      Tag = 1
      Left = 8
      Top = 8
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = TNEV1PANELClick
    end
    object TNEV3PANEL: TPanel
      Tag = 3
      Left = 8
      Top = 72
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      OnClick = TNEV1PANELClick
    end
    object TCIM1PANEL: TPanel
      Left = 232
      Top = 8
      Width = 233
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object TCIM3PANEL: TPanel
      Left = 232
      Top = 72
      Width = 233
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object TCIM2PANEL: TPanel
      Left = 232
      Top = 40
      Width = 233
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object TAP1PANEL: TPanel
      Left = 472
      Top = 8
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object TAP2PANEL: TPanel
      Left = 472
      Top = 40
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object TAP3PANEL: TPanel
      Left = 472
      Top = 72
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object TNEV4PANEL: TPanel
      Tag = 4
      Left = 8
      Top = 104
      Width = 217
      Height = 23
      Cursor = crHandPoint
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
      OnClick = TNEV1PANELClick
    end
    object TCIM4PANEL: TPanel
      Left = 232
      Top = 104
      Width = 233
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
    end
    object TAP4PANEL: TPanel
      Left = 472
      Top = 104
      Width = 193
      Height = 23
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
  end
  object BIZONYLATTIPUSPANEL: TPanel
    Left = 344
    Top = 480
    Width = 265
    Height = 49
    Color = 4210752
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 12
  end
  object STORNOPANEL: TPanel
    Left = 344
    Top = 536
    Width = 265
    Height = 41
    Color = clBlack
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 13
  end
  object DATUMKEROGOMB: TPanel
    Left = 344
    Top = 403
    Width = 265
    Height = 33
    Cursor = crHandPoint
    Caption = 'Ezt a napot k'#233'rem !'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 14
    OnClick = DatumKiertekeles
  end
  object PENZTARPANEL: TPanel
    Left = -1950
    Top = 454
    Width = 393
    Height = 186
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 15
    object PENZTARNEVPANEL: TPanel
      Left = 0
      Top = 128
      Width = 385
      Height = 41
      BevelOuter = bvNone
      Caption = 'ADEFRGTHZ FRGTBHZJH FREDFGBVFX'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object PENZTARSZAMPANEL: TPanel
      Left = 144
      Top = 80
      Width = 97
      Height = 41
      BevelOuter = bvNone
      Caption = 'RTBD'
      Color = 4539717
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object IRANYNEVPANEL: TPanel
      Left = 24
      Top = 16
      Width = 345
      Height = 57
      BevelOuter = bvNone
      Caption = #193'tvev'#337' p'#233'nzt'#225'r'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -48
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object SZUROPANEL: TPanel
    Left = -1800
    Top = 128
    Width = 425
    Height = 537
    Color = 2105376
    TabOrder = 16
    object Shape19: TShape
      Left = 1
      Top = 1
      Width = 423
      Height = 535
      Align = alClient
      Brush.Color = 2105376
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label3: TLabel
      Left = 24
      Top = 24
      Width = 371
      Height = 36
      Caption = 'BIZONYLATOK SZ'#368'R'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object GroupBox1: TGroupBox
      Left = 32
      Top = 72
      Width = 353
      Height = 401
      TabOrder = 0
      object RR1: TRadioButton
        Tag = 1
        Left = 16
        Top = 32
        Width = 217
        Height = 25
        Caption = 'Sz'#369'r'#233's kikapcsolva'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object RR2: TRadioButton
        Tag = 2
        Left = 16
        Top = 72
        Width = 297
        Height = 25
        Caption = 'Csak '#252'gyfeles bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object RR3: TRadioButton
        Tag = 3
        Left = 16
        Top = 120
        Width = 281
        Height = 25
        Caption = 'Csak v'#233'teli bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
      end
      object RR4: TRadioButton
        Tag = 4
        Left = 16
        Top = 168
        Width = 257
        Height = 25
        Caption = 'Csak elad'#225'si bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object RR5: TRadioButton
        Tag = 5
        Left = 16
        Top = 216
        Width = 321
        Height = 25
        Caption = 'Csak konverzi'#243's bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
      end
      object RR6: TRadioButton
        Tag = 6
        Left = 16
        Top = 256
        Width = 321
        Height = 25
        Caption = 'Csak p'#233'nz-'#225'tad'#225'si bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 5
      end
      object RR7: TRadioButton
        Tag = 7
        Left = 16
        Top = 304
        Width = 313
        Height = 25
        Caption = 'Csak p'#233'nz '#225'tv'#233'teli bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 6
      end
      object RR8: TRadioButton
        Tag = 8
        Left = 16
        Top = 352
        Width = 297
        Height = 25
        Caption = 'Csak storn'#243'zott bizonylatok'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 7
      end
    end
    object BitBtn1: TBitBtn
      Left = 128
      Top = 496
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'Vissza'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn1Click
    end
  end
  object COPYPANEL: TPanel
    Left = -1658
    Top = 304
    Width = 425
    Height = 113
    BevelOuter = bvNone
    TabOrder = 17
    object Shape20: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 113
      Align = alClient
      Brush.Color = 4539717
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label4: TLabel
      Left = 24
      Top = 24
      Width = 387
      Height = 29
      Caption = 'K'#201'REM AZ '#218'JRANYOMTAT'#193'S INDOK'#193'T !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 112
      Top = 64
      Width = 84
      Height = 24
      Caption = 'INDOK ='
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object INDOKEDIT: TEdit
      Left = 203
      Top = 64
      Width = 153
      Height = 32
      BorderStyle = bsNone
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 10
      ParentFont = False
      TabOrder = 0
      Text = 'ASDFRTGHZX'
      OnExit = INDOKEDITExit
      OnKeyDown = INDOKEDITKeyDown
    end
  end
  object PROSNEVPANEL: TPanel
    Left = 4
    Top = 680
    Width = 331
    Height = 41
    BevelOuter = bvNone
    Color = 4210752
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 18
  end
  object LAKCIMCSIK: TBitBtn
    Left = -1900
    Top = 184
    Width = 497
    Height = 33
    Cursor = crHandPoint
    TabOrder = 19
    OnClick = LAKCIMCSIKClick
  end
  object NAVPANEL: TPanel
    Left = 472
    Top = 440
    Width = 137
    Height = 33
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 21
  end
  object UGYADATPANEL: TPanel
    Left = 616
    Top = 50
    Width = 393
    Height = 255
    BevelOuter = bvNone
    Color = 4210752
    TabOrder = 22
    object ScrollBox1: TScrollBox
      Left = 1
      Top = 1
      Width = 392
      Height = 248
      VertScrollBar.Position = 177
      TabOrder = 0
      object Shape7: TShape
        Left = 0
        Top = 23
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape10: TShape
        Left = 0
        Top = 197
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape11: TShape
        Left = 0
        Top = 172
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape22: TShape
        Left = 0
        Top = 147
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape23: TShape
        Left = 0
        Top = -177
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape27: TShape
        Left = 0
        Top = -2
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape29: TShape
        Left = 0
        Top = 97
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape30: TShape
        Left = 0
        Top = -152
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape31: TShape
        Left = 0
        Top = -102
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape32: TShape
        Left = 0
        Top = -77
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape33: TShape
        Left = 0
        Top = 221
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape35: TShape
        Left = 0
        Top = 47
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape36: TShape
        Left = 0
        Top = -127
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape37: TShape
        Left = 0
        Top = 122
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape38: TShape
        Left = 0
        Top = -52
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape40: TShape
        Left = 0
        Top = 72
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Shape41: TShape
        Left = 0
        Top = -27
        Width = 168
        Height = 23
        Pen.Color = clYellow
      end
      object Panel34: TPanel
        Left = 1
        Top = -176
        Width = 166
        Height = 21
        Caption = #220'GYF'#201'L NEVE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object Panel35: TPanel
        Left = 1
        Top = 48
        Width = 166
        Height = 21
        Caption = 'AZONOS'#205'T'#211
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object Panel36: TPanel
        Left = 1
        Top = 222
        Width = 166
        Height = 21
        Caption = 'UTCA - H'#193'ZSZ'#193'M'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object Panel25: TPanel
        Left = 1
        Top = -151
        Width = 166
        Height = 21
        Caption = 'EL'#214'Z'#336' NEVE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
      end
      object Panel51: TPanel
        Left = 1
        Top = -101
        Width = 166
        Height = 21
        Caption = 'LE'#193'NYKORI NEVE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object Panel52: TPanel
        Left = 1
        Top = -51
        Width = 166
        Height = 21
        Caption = 'SZ'#220'LET'#201'SI IDEJE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
      end
      object Panel53: TPanel
        Left = 1
        Top = -1
        Width = 166
        Height = 21
        Caption = 'LAKC'#205'M'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 6
      end
      object Panel54: TPanel
        Left = 1
        Top = 24
        Width = 166
        Height = 21
        Caption = 'OKM'#193'NYT'#205'PUS'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 7
      end
      object Panel55: TPanel
        Left = 1
        Top = 73
        Width = 166
        Height = 21
        Caption = 'TARTOZKOD'#193'SI HELY'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
      end
      object Panel56: TPanel
        Left = 1
        Top = 148
        Width = 166
        Height = 21
        Caption = 'K'#214'ZSZERPL'#336' ST'#193'TUSZ'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 9
      end
      object Panel57: TPanel
        Left = 1
        Top = -126
        Width = 166
        Height = 21
        Caption = 'ANYJA NEVE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 10
      end
      object Panel58: TPanel
        Left = 1
        Top = -76
        Width = 166
        Height = 21
        Caption = 'SZ'#220'LET'#201'SI HELYE'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 11
      end
      object Panel59: TPanel
        Left = 1
        Top = -25
        Width = 166
        Height = 21
        Caption = #193'LLAMPOLG'#193'R'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 12
      end
      object Panel60: TPanel
        Left = 1
        Top = 98
        Width = 166
        Height = 21
        Caption = 'LAKC'#205'MK'#193'RTYA'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 13
      end
      object Panel61: TPanel
        Left = 1
        Top = 173
        Width = 166
        Height = 21
        Caption = 'IR'#193'NY'#205'T'#211' SZ'#193'M'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 14
      end
      object Panel62: TPanel
        Left = 1
        Top = 123
        Width = 166
        Height = 21
        Caption = 'DEVIZA ST'#193'TUSZ'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 15
      end
      object Panel63: TPanel
        Left = 1
        Top = 198
        Width = 166
        Height = 21
        Caption = 'V'#193'ROSA'
        Color = 4539717
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 16
      end
      object Panel64: TPanel
        Left = 171
        Top = -177
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 17
        object DBEdit2: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'NEV'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel65: TPanel
        Left = 171
        Top = -127
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 18
        object DBEdit16: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'ANYJANEVE'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel66: TPanel
        Left = 171
        Top = -77
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 19
        object DBEdit23: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'SZULETESIHELY'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel67: TPanel
        Left = 171
        Top = -27
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 20
        object DBEdit24: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'ALLAMPOLGAR'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel68: TPanel
        Left = 171
        Top = 23
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 21
        object DBEdit14: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'OKMANYTIPUS'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel69: TPanel
        Left = 171
        Top = -2
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 22
        object DBEdit25: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'LAKCIM'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel70: TPanel
        Left = 171
        Top = 73
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 23
        object DBEdit28: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'TARTOZKODASIHELY'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel71: TPanel
        Left = 171
        Top = 148
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 24
        object KOZSZEREPLOEDIT: TEdit
          Left = 0
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          Text = ' '
        end
      end
      object Panel72: TPanel
        Left = 171
        Top = 197
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 25
        object DBEdit33: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'VAROS'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel73: TPanel
        Left = 171
        Top = 48
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 26
        object DBEdit26: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'AZONOSITO'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel74: TPanel
        Left = 171
        Top = 98
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 27
        object DBEdit29: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'LAKCIMKARTYA'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel75: TPanel
        Left = 171
        Top = 172
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 28
        object DBEdit32: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'IRSZAM'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel76: TPanel
        Left = 171
        Top = 221
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 29
        object DBEdit27: TDBEdit
          Left = 1
          Top = 1
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'UTCA'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel77: TPanel
        Left = 171
        Top = 123
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 30
        object BELKULEDIT: TEdit
          Left = 0
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          Text = ' '
        end
      end
      object Panel78: TPanel
        Left = 171
        Top = -152
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 31
        object DBEdit5: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'ELOZONEV'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel79: TPanel
        Left = 171
        Top = -102
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 32
        object DBEdit11: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'LEANYKORI'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel80: TPanel
        Left = 171
        Top = -52
        Width = 198
        Height = 23
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 33
        object DBEdit15: TDBEdit
          Left = 1
          Top = 0
          Width = 198
          Height = 21
          Color = clYellow
          DataField = 'SZULETESIIDO'
          DataSource = UGYFELSOURCE
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
        end
      end
    end
  end
  object TULAJPANEL: TPanel
    Left = 8
    Top = 288
    Width = 315
    Height = 369
    BevelOuter = bvNone
    Color = 4210752
    TabOrder = 23
    object tulfopanel: TPanel
      Left = 8
      Top = 16
      Width = 297
      Height = 41
      BevelOuter = bvNone
      Caption = '1. TULAJDONOS'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel12: TPanel
      Left = 8
      Top = 184
      Width = 97
      Height = 21
      Caption = #193'LLAMPOLG:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object TKOZSZERPANEL: TPanel
      Left = 8
      Top = 288
      Width = 297
      Height = 21
      Caption = 'NEM KIEMELT K'#214'ZSZEREPL'#336
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object Panel14: TPanel
      Left = 8
      Top = 88
      Width = 97
      Height = 21
      Caption = 'EL'#214'Z'#336' NEVE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object Panel15: TPanel
      Left = 8
      Top = 136
      Width = 97
      Height = 21
      Caption = 'SZ'#220'L-I HELYE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object Panel16: TPanel
      Left = 8
      Top = 160
      Width = 97
      Height = 21
      Caption = 'SZ'#220'L-I IDEJE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object Panel17: TPanel
      Left = 8
      Top = 112
      Width = 97
      Height = 21
      Caption = 'LAKC'#205'ME:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object Panel18: TPanel
      Left = 8
      Top = 64
      Width = 97
      Height = 21
      Caption = 'NEVE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object Panel19: TPanel
      Left = 8
      Top = 256
      Width = 97
      Height = 21
      Caption = #201'RD M'#201'RT'#201'KE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object Panel21: TPanel
      Left = 8
      Top = 208
      Width = 97
      Height = 21
      Caption = 'TART-I HELYE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object Panel22: TPanel
      Left = 8
      Top = 232
      Width = 97
      Height = 21
      Caption = #201'RD JELLEGE:'
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 10
    end
    object BACKGOMB: TBitBtn
      Left = 96
      Top = 328
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Default = True
      TabOrder = 11
      OnClick = BACKGOMBClick
    end
    object NEVEDIT: TEdit
      Left = 104
      Top = 64
      Width = 201
      Height = 21
      Color = 13697023
      TabOrder = 12
      Text = 'NEVEDIT'
    end
    object ELOZOEDIT: TEdit
      Left = 104
      Top = 88
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 13
      Text = 'ELOZOEDIT'
    end
    object LAKCIMEDIT: TEdit
      Left = 104
      Top = 112
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 14
      Text = 'LAKCIMEDIT'
    end
    object SZULHELYEDIT: TEdit
      Left = 104
      Top = 136
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 15
      Text = 'SZULHELYEDIT'
    end
    object SZULIDOEDIT: TEdit
      Left = 104
      Top = 160
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 16
      Text = 'SZULIDOEDIT'
    end
    object ALLAMPOLGEDIT: TEdit
      Left = 104
      Top = 184
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 17
      Text = 'ALLAMPOLGEDIT'
    end
    object TARTHELYEDIT: TEdit
      Left = 104
      Top = 208
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 18
      Text = 'TARTHELYEDIT'
    end
    object ERDJELLEGEDIT: TEdit
      Left = 104
      Top = 232
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 19
      Text = 'ERDJELLEGEDIT'
    end
    object ERDMERTEKEDIT: TEdit
      Left = 104
      Top = 256
      Width = 201
      Height = 21
      Color = 11599871
      TabOrder = 20
      Text = 'ERDMERTEKEDIT'
    end
  end
  object MEGBIZOPANEL: TPanel
    Left = -1879
    Top = 392
    Width = 393
    Height = 185
    Color = 4539717
    TabOrder = 24
    Visible = False
    object Label7: TLabel
      Left = 16
      Top = 16
      Width = 354
      Height = 18
      Caption = 'A TRANZAKCI'#211'T MEGBIZ'#193'SB'#211'L BONYOLITOTTA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 152
      Top = 48
      Width = 80
      Height = 18
      Caption = 'MEGBIZ'#211':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object MZNEVPANEL: TPanel
      Left = 16
      Top = 80
      Width = 361
      Height = 17
      BevelOuter = bvNone
      Caption = 'ASDFGHZTR ASDEFRGTZNHZJUZTRE VFGZASDXVX'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object MZANYJAPANEL: TPanel
      Left = 16
      Top = 104
      Width = 361
      Height = 17
      BevelOuter = bvNone
      Caption = 'MZANYJAPANEL'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object MZSZULETESPANEL: TPanel
      Left = 16
      Top = 128
      Width = 361
      Height = 17
      BevelOuter = bvNone
      Caption = 'MZSZULETESPANEL'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object MZLAKCIMPANEL: TPanel
      Left = 16
      Top = 152
      Width = 361
      Height = 17
      BevelOuter = bvNone
      Caption = 'MZLAKCIMPANEL'
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
  end
  object HAVIFEJTABLA: TIBTable
    Database = HAVIFEJDBASE
    Transaction = HAVIFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexDefs = <
      item
        Name = 'XBF1303'
        Fields = 'DATUM'
      end>
    StoreDefs = True
    Left = 24
    Top = 200
    object HAVIFEJTABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      FixedChar = True
      Size = 7
    end
    object HAVIFEJTABLATIPUS: TIBStringField
      FieldName = 'TIPUS'
      FixedChar = True
      Size = 1
    end
    object HAVIFEJTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJTABLAIDO: TIBStringField
      FieldName = 'IDO'
      FixedChar = True
      Size = 8
    end
    object HAVIFEJTABLANETTO: TIntegerField
      FieldName = 'NETTO'
    end
    object HAVIFEJTABLATRANZDIJ: TIntegerField
      FieldName = 'TRANZDIJ'
    end
    object HAVIFEJTABLAKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      DisplayFormat = '### ###'
    end
    object HAVIFEJTABLAFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
    end
    object HAVIFEJTABLAOSSZESFORINTERTEK: TIntegerField
      FieldName = 'OSSZESFORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object HAVIFEJTABLAUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object HAVIFEJTABLAUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
    end
    object HAVIFEJTABLAUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      FixedChar = True
      Size = 25
    end
    object HAVIFEJTABLATETEL: TSmallintField
      FieldName = 'TETEL'
    end
    object HAVIFEJTABLAPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object HAVIFEJTABLATARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object HAVIFEJTABLATRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      FixedChar = True
      Size = 3
    end
    object HAVIFEJTABLAMEGBIZOSZAM: TIntegerField
      FieldName = 'MEGBIZOSZAM'
    end
    object HAVIFEJTABLAMEGBIZOTT: TIntegerField
      FieldName = 'MEGBIZOTT'
    end
    object HAVIFEJTABLAPLOMBASZAM: TIBStringField
      FieldName = 'PLOMBASZAM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJTABLASTORNO: TSmallintField
      FieldName = 'STORNO'
    end
    object HAVIFEJTABLASTORNOZOTTBIZONYLAT: TIBStringField
      FieldName = 'STORNOZOTTBIZONYLAT'
      FixedChar = True
      Size = 7
    end
    object HAVIFEJTABLASTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      FixedChar = True
      Size = 7
    end
    object HAVIFEJTABLAIDKOD: TIBStringField
      FieldName = 'IDKOD'
      FixedChar = True
      Size = 5
    end
  end
  object HAVIFEJQUERY: TIBQuery
    Database = HAVIFEJDBASE
    Transaction = HAVIFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 64
    Top = 200
    object HAVIFEJQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BF1709.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BF1709.TIPUS'
      FixedChar = True
      Size = 1
    end
    object HAVIFEJQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BF1709.DATUM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BF1709.IDO'
      FixedChar = True
      Size = 8
    end
    object HAVIFEJQUERYNETTO: TIntegerField
      FieldName = 'NETTO'
      Origin = 'BF1709.NETTO'
    end
    object HAVIFEJQUERYTRANZDIJ: TIntegerField
      FieldName = 'TRANZDIJ'
      Origin = 'BF1709.TRANZDIJ'
    end
    object HAVIFEJQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'BF1709.KEZELESIDIJ'
    end
    object HAVIFEJQUERYFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
      Origin = 'BF1709.FIZETENDO'
    end
    object HAVIFEJQUERYFIZETOESZKOZ: TSmallintField
      FieldName = 'FIZETOESZKOZ'
      Origin = 'BF1709.FIZETOESZKOZ'
    end
    object HAVIFEJQUERYOSSZESFORINTERTEK: TIntegerField
      FieldName = 'OSSZESFORINTERTEK'
      Origin = 'BF1709.OSSZESFORINTERTEK'
    end
    object HAVIFEJQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'BF1709.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object HAVIFEJQUERYUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
      Origin = 'BF1709.UGYFELSZAM'
    end
    object HAVIFEJQUERYUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      Origin = 'BF1709.UGYFELNEV'
      FixedChar = True
      Size = 41
    end
    object HAVIFEJQUERYTETEL: TSmallintField
      FieldName = 'TETEL'
      Origin = 'BF1709.TETEL'
    end
    object HAVIFEJQUERYIDKOD: TIBStringField
      FieldName = 'IDKOD'
      Origin = 'BF1709.IDKOD'
      FixedChar = True
      Size = 5
    end
    object HAVIFEJQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'BF1709.PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object HAVIFEJQUERYTARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      Origin = 'BF1709.TARSPENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object HAVIFEJQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BF1709.TRBPENZTAR'
      FixedChar = True
      Size = 3
    end
    object HAVIFEJQUERYMEGBIZOSZAM: TIntegerField
      FieldName = 'MEGBIZOSZAM'
      Origin = 'BF1709.MEGBIZOSZAM'
    end
    object HAVIFEJQUERYMEGBIZOTT: TIntegerField
      FieldName = 'MEGBIZOTT'
      Origin = 'BF1709.MEGBIZOTT'
    end
    object HAVIFEJQUERYPLOMBASZAM: TIBStringField
      FieldName = 'PLOMBASZAM'
      Origin = 'BF1709.PLOMBASZAM'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYKONVERZIO: TSmallintField
      FieldName = 'KONVERZIO'
      Origin = 'BF1709.KONVERZIO'
    end
    object HAVIFEJQUERYUGYFELCIM: TIBStringField
      FieldName = 'UGYFELCIM'
      Origin = 'BF1709.UGYFELCIM'
      FixedChar = True
      Size = 56
    end
    object HAVIFEJQUERYADOSZAM: TIBStringField
      FieldName = 'ADOSZAM'
      Origin = 'BF1709.ADOSZAM'
      FixedChar = True
      Size = 15
    end
    object HAVIFEJQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BF1709.STORNO'
    end
    object HAVIFEJQUERYSTORNOZOTTBIZONYLAT: TIBStringField
      FieldName = 'STORNOZOTTBIZONYLAT'
      Origin = 'BF1709.STORNOZOTTBIZONYLAT'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BF1709.STORNOBIZONYLAT'
      FixedChar = True
      Size = 10
    end
    object HAVIFEJQUERYZCOUNTS: TIBStringField
      FieldName = 'ZCOUNTS'
      Origin = 'BF1709.ZCOUNTS'
      FixedChar = True
      Size = 4
    end
    object HAVIFEJQUERYRECNUMS: TIBStringField
      FieldName = 'RECNUMS'
      Origin = 'BF1709.RECNUMS'
      FixedChar = True
      Size = 5
    end
    object HAVIFEJQUERYKEREKITES: TSmallintField
      FieldName = 'KEREKITES'
      Origin = 'BF1709.KEREKITES'
    end
    object HAVIFEJQUERYFORRAS: TIBStringField
      FieldName = 'FORRAS'
      Origin = 'BF1709.FORRAS'
      FixedChar = True
    end
    object HAVIFEJQUERYENGEDELYEZO: TIBStringField
      FieldName = 'ENGEDELYEZO'
      Origin = 'BF1709.ENGEDELYEZO'
      FixedChar = True
    end
  end
  object HAVIFEJDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVIFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 200
  end
  object HAVIFEJTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = HAVIFEJDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 200
  end
  object UGYFELQUERY: TIBQuery
    Database = UGYFELDBASE
    Transaction = UGYFELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT *FROM UGYFEL')
    Left = 160
    Top = 240
  end
  object UGYFELDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = UGYFELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 192
    Top = 240
  end
  object UGYFELTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = UGYFELDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 240
  end
  object JOGIQUERY: TIBQuery
    Database = JOGIDBASE
    Transaction = jogitranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 240
    Top = 688
  end
  object JOGIDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = jogitranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 272
    Top = 688
  end
  object jogitranz: TIBTransaction
    Active = False
    DefaultDatabase = JOGIDBASE
    AutoStopAction = saNone
    Left = 304
    Top = 688
  end
  object TULAJQUERY: TIBQuery
    Database = TULAJDBASE
    Transaction = TULAJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 688
  end
  object TULAJDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TULAJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 160
    Top = 688
  end
  object TULAJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TULAJDBASE
    AutoStopAction = saNone
    Left = 192
    Top = 688
  end
  object BLOKKFEJSOURCE: TDataSource
    DataSet = HAVIFEJQUERY
    Left = 224
    Top = 152
  end
  object TETELQUERY: TIBQuery
    Database = TETELDBASE
    Transaction = TETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM BLOKKTETEL')
    Left = 48
    Top = 152
    object TETELQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BLOKKTETEL.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object TETELQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'BLOKKTETEL.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object TETELQUERYARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      Origin = 'BLOKKTETEL.ARFOLYAM'
    end
    object TETELQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'BLOKKTETEL.ELSZAMOLASIARFOLYAM'
    end
    object TETELQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'BLOKKTETEL.BANKJEGY'
    end
    object TETELQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BLOKKTETEL.FORINTERTEK'
    end
    object TETELQUERYELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Origin = 'BLOKKTETEL.ELOJEL'
      FixedChar = True
      Size = 1
    end
    object TETELQUERYCOIN: TSmallintField
      FieldName = 'COIN'
      Origin = 'BLOKKTETEL.COIN'
    end
    object TETELQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BLOKKTETEL.STORNO'
    end
    object TETELQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BLOKKTETEL.DATUM'
      FixedChar = True
      Size = 10
    end
  end
  object TETELDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 152
  end
  object TETELTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = TETELDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 152
  end
  object HAVITETELQUERY: TIBQuery
    Database = HAVITETELDBASE
    Transaction = HAVITETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 24
    Top = 240
    object HAVITETELQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BT1701.DATUM'
      FixedChar = True
      Size = 10
    end
    object HAVITETELQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BT1701.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object HAVITETELQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'BT1701.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object HAVITETELQUERYARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      Origin = 'BT1701.ARFOLYAM'
    end
    object HAVITETELQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'BT1701.ELSZAMOLASIARFOLYAM'
    end
    object HAVITETELQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'BT1701.BANKJEGY'
    end
    object HAVITETELQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BT1701.FORINTERTEK'
    end
    object HAVITETELQUERYELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Origin = 'BT1701.ELOJEL'
      FixedChar = True
      Size = 1
    end
    object HAVITETELQUERYCOIN: TSmallintField
      FieldName = 'COIN'
      Origin = 'BT1701.COIN'
    end
    object HAVITETELQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BT1701.STORNO'
    end
  end
  object HAVITETELDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 240
  end
  object HAVITETELTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = HAVITETELDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 240
  end
  object BLOKKTETELSOURCE: TDataSource
    DataSet = HAVITETELQUERY
    Left = 264
    Top = 152
  end
  object UGYFELSOURCE: TDataSource
    DataSet = UGYFELQUERY
    Left = 496
    Top = 128
  end
  object JOGISOURCE: TDataSource
    DataSet = JOGIQUERY
    Left = 224
    Top = 192
  end
  object FEJSOURCE: TDataSource
    DataSet = FEJQUERY
    Left = 224
    Top = 112
  end
  object TETELSOURCE: TDataSource
    DataSet = TETELQUERY
    Left = 264
    Top = 112
  end
  object FEJTABLA: TIBTable
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'BLOKKFEJ'
    Left = 176
    Top = 112
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM BLOKKFEJ')
    Left = 48
    Top = 112
    object FEJQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BLOKKFEJ.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BLOKKFEJ.TIPUS'
      FixedChar = True
      Size = 1
    end
    object FEJQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BLOKKFEJ.DATUM'
      FixedChar = True
      Size = 11
    end
    object FEJQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BLOKKFEJ.IDO'
      FixedChar = True
      Size = 8
    end
    object FEJQUERYOSSZESFORINTERTEK: TIntegerField
      FieldName = 'OSSZESFORINTERTEK'
      Origin = 'BLOKKFEJ.OSSZESFORINTERTEK'
    end
    object FEJQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'BLOKKFEJ.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object FEJQUERYUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
      Origin = 'BLOKKFEJ.UGYFELSZAM'
    end
    object FEJQUERYUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      Origin = 'BLOKKFEJ.UGYFELNEV'
      FixedChar = True
      Size = 41
    end
    object FEJQUERYTETEL: TSmallintField
      FieldName = 'TETEL'
      Origin = 'BLOKKFEJ.TETEL'
    end
    object FEJQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'BLOKKFEJ.PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object FEJQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BLOKKFEJ.TRBPENZTAR'
      FixedChar = True
      Size = 3
    end
    object FEJQUERYTARSPENZTARKOD: TIBStringField
      FieldName = 'TARSPENZTARKOD'
      Origin = 'BLOKKFEJ.TARSPENZTARKOD'
      FixedChar = True
      Size = 4
    end
    object FEJQUERYMEGBIZOTT: TIntegerField
      FieldName = 'MEGBIZOTT'
      Origin = 'BLOKKFEJ.MEGBIZOTT'
    end
    object FEJQUERYMEGBIZOSZAM: TIntegerField
      FieldName = 'MEGBIZOSZAM'
      Origin = 'BLOKKFEJ.MEGBIZOSZAM'
    end
    object FEJQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BLOKKFEJ.STORNO'
    end
    object FEJQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BLOKKFEJ.STORNOBIZONYLAT'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYSTORNOZOTTBIZONYLAT: TIBStringField
      FieldName = 'STORNOZOTTBIZONYLAT'
      Origin = 'BLOKKFEJ.STORNOZOTTBIZONYLAT'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYPLOMBASZAM: TIBStringField
      FieldName = 'PLOMBASZAM'
      Origin = 'BLOKKFEJ.PLOMBASZAM'
      FixedChar = True
      Size = 10
    end
    object FEJQUERYNETTO: TIntegerField
      FieldName = 'NETTO'
      Origin = 'BLOKKFEJ.NETTO'
    end
    object FEJQUERYTRANZDIJ: TIntegerField
      FieldName = 'TRANZDIJ'
      Origin = 'BLOKKFEJ.TRANZDIJ'
    end
    object FEJQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'BLOKKFEJ.KEZELESIDIJ'
    end
    object FEJQUERYFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
      Origin = 'BLOKKFEJ.FIZETENDO'
    end
    object FEJQUERYIDKOD: TIBStringField
      FieldName = 'IDKOD'
      Origin = 'BLOKKFEJ.IDKOD'
      FixedChar = True
      Size = 5
    end
    object FEJQUERYFIZETOESZKOZ: TSmallintField
      FieldName = 'FIZETOESZKOZ'
      Origin = 'BLOKKFEJ.FIZETOESZKOZ'
    end
    object FEJQUERYKONVERZIO: TSmallintField
      FieldName = 'KONVERZIO'
      Origin = 'BLOKKFEJ.KONVERZIO'
    end
    object FEJQUERYUGYFELCIM: TIBStringField
      FieldName = 'UGYFELCIM'
      Origin = 'BLOKKFEJ.UGYFELCIM'
      FixedChar = True
      Size = 56
    end
    object FEJQUERYADOSZAM: TIBStringField
      FieldName = 'ADOSZAM'
      Origin = 'BLOKKFEJ.ADOSZAM'
      FixedChar = True
      Size = 13
    end
    object FEJQUERYZCOUNTS: TIBStringField
      FieldName = 'ZCOUNTS'
      Origin = 'BLOKKFEJ.ZCOUNTS'
      FixedChar = True
      Size = 4
    end
    object FEJQUERYRECNUMS: TIBStringField
      FieldName = 'RECNUMS'
      Origin = 'BLOKKFEJ.RECNUMS'
      FixedChar = True
      Size = 5
    end
    object FEJQUERYKEREKITES: TSmallintField
      FieldName = 'KEREKITES'
      Origin = 'BLOKKFEJ.KEREKITES'
    end
    object FEJQUERYFORRAS: TIBStringField
      FieldName = 'FORRAS'
      Origin = 'BLOKKFEJ.FORRAS'
      FixedChar = True
    end
    object FEJQUERYENGEDELYEZO: TIBStringField
      FieldName = 'ENGEDELYEZO'
      Origin = 'BLOKKFEJ.ENGEDELYEZO'
      FixedChar = True
    end
  end
  object FEJDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 112
  end
  object FEJTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 112
  end
  object PENZTARQUERY: TIBQuery
    Database = PENZTARDBASE
    Transaction = PENZTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 688
  end
  object PENZTARDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PENZTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 688
  end
  object PENZTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTARDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 688
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 96
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
    Left = 504
    Top = 136
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 536
    Top = 96
  end
end
