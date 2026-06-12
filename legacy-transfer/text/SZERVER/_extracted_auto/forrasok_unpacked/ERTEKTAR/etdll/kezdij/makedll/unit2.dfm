object KDADVET: TKDADVET
  Left = 188
  Top = 150
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'KDADVET'
  ClientHeight = 403
  ClientWidth = 641
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object KEZDIJPANEL: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 400
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 0
    object Shape6: TShape
      Left = 0
      Top = 0
      Width = 640
      Height = 400
      Align = alClient
      Brush.Color = 45056
      Pen.Color = clMaroon
      Pen.Width = 5
    end
    object Panel2: TPanel
      Left = 144
      Top = 56
      Width = 393
      Height = 41
      BevelOuter = bvNone
      Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK '
      Color = 45056
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object KEZDATVETGOMB: TBitBtn
      Left = 96
      Top = 144
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK '#193'TV'#201'TELE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = KEZDATVETGOMBClick
    end
    object KEZDPILLGOMB: TBitBtn
      Left = 96
      Top = 216
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'A KEZEL'#201'SI K'#214'LTS'#201'GEK JELENLEGI K'#201'SZLETE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = KEZDPILLGOMBClick
    end
    object KEZDBIZONYLATGOMB: TBitBtn
      Left = 96
      Top = 256
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'BIZONYLATOK MEGTEKINT'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = KEZDBIZONYLATGOMBClick
    end
    object KEZDVISSZAGOMB: TBitBtn
      Left = 240
      Top = 312
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = KEZDVISSZAGOMBClick
    end
    object KEZDKIADGOMB: TBitBtn
      Left = 96
      Top = 180
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK '#193'TUTAL'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KEZDKIADGOMBClick
    end
  end
  object PILLKEZDIJPANEL: TPanel
    Left = -1500
    Top = 136
    Width = 529
    Height = 209
    BevelOuter = bvNone
    TabOrder = 4
    Visible = False
    object Shape9: TShape
      Left = 0
      Top = 0
      Width = 529
      Height = 209
      Align = alClient
      Brush.Color = 11599871
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label21: TLabel
      Left = 24
      Top = 32
      Width = 476
      Height = 24
      Caption = 'A KEZEL'#201'SI K'#214'LTS'#201'G PILLANATNYI K'#201'SZLETE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PILLOSSZEGPANEL: TPanel
      Left = 136
      Top = 88
      Width = 289
      Height = 41
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object PillKeszBackGomb: TBitBtn
      Left = 224
      Top = 152
      Width = 115
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = PillKeszBackGombClick
    end
  end
  object KEZDIJATVETPANEL: TPanel
    Left = -2100
    Top = 110
    Width = 589
    Height = 273
    BevelOuter = bvNone
    Color = clGreen
    TabOrder = 1
    Visible = False
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 589
      Height = 273
      Align = alClient
      Brush.Color = clGreen
      Pen.Color = clYellow
      Pen.Width = 5
    end
    object Label9: TLabel
      Left = 120
      Top = 88
      Width = 198
      Height = 28
      Caption = 'T'#225'rsp'#233'nzt'#225'r sz'#225'ma :'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label11: TLabel
      Left = 144
      Top = 130
      Width = 174
      Height = 28
      Caption = 'Bizonylat sz'#225'ma :'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object KEZFOCIMPANEL: TPanel
      Left = 8
      Top = 32
      Width = 561
      Height = 41
      BevelOuter = bvNone
      Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK '#193'TV'#201'TELE'
      Color = clGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object ATVETTKEZBIZPANEL: TPanel
      Left = 328
      Top = 128
      Width = 153
      Height = 33
      Caption = 'B-000666'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object KULDOPENZTARPANEL: TPanel
      Left = 328
      Top = 88
      Width = 153
      Height = 33
      Caption = 'A123'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object ADOTTVETTPANEL: TPanel
      Left = 152
      Top = 168
      Width = 177
      Height = 41
      BevelOuter = bvNone
      Caption = #193'tvett '#246'sszeg:'
      Color = clGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object ATVETTKEZDIJEDIT: TEdit
      Left = 328
      Top = 168
      Width = 153
      Height = 40
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      Text = '125351000'
      OnEnter = ATVETTKEZDIJEDITEnter
      OnExit = ATVETTKEZDIJEDITExit
      OnKeyDown = ATVETTKEZDIJEDITKeyDown
    end
    object ATVETTKDKONYVELOGOMB: TBitBtn
      Left = 144
      Top = 224
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'Konyvel'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = ATVETTKDKONYVELOGOMBClick
    end
    object ATVETTKDKONYVMEGSEMGOMB: TBitBtn
      Left = 304
      Top = 224
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = ATVETTKDKONYVMEGSEMGOMBClick
    end
  end
  object KEZBIZONYLATPANEL: TPanel
    Left = -2200
    Top = 16
    Width = 640
    Height = 400
    BevelOuter = bvNone
    BevelWidth = 3
    Color = 6776679
    TabOrder = 2
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 640
      Height = 400
      Align = alClient
      Brush.Color = 16311512
      Pen.Width = 5
    end
    object KEZBIZRACS: TDBGrid
      Left = 32
      Top = 64
      Width = 569
      Height = 265
      DataSource = kezdijsource
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnCellClick = KEZBIZRACSCellClick
      OnDblClick = KEZBIZRACSDblClick
      OnKeyUp = KEZBIZRACSKeyUp
      OnMouseUp = KEZBIZRACSMouseUp
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#225'tum'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 103
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLAT'
          Title.Alignment = taCenter
          Title.Caption = 'Bizonylat'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 113
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'ELOJEL'
          Title.Alignment = taCenter
          Title.Caption = 'El'#337'jel'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 61
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKJEGY'
          Title.Alignment = taCenter
          Title.Caption = 'Kezel'#233'si d'#237'j'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 138
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAR'
          Title.Alignment = taCenter
          Title.Caption = 'T'#225'rsp'#233'nzt'#225'r'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 133
          Visible = True
        end>
    end
    object MAIKEZDIJGOMB: TBitBtn
      Left = 16
      Top = 336
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'Mai napi bizonylatok'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NapiKezdijDisplay
    end
    object OLDKEZDIJGOMB: TBitBtn
      Left = 176
      Top = 336
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'R'#233'gebbi bizonylatok'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = OLDKEZDIJGOMBClick
    end
    object KEZBIZSTORNOGOMB: TBitBtn
      Left = 336
      Top = 336
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Bizonylat storn'#243
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = KEZBIZSTORNOGOMBClick
    end
    object Kezbizvegegomb: TBitBtn
      Left = 480
      Top = 336
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'Vissza a men'#369're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = KezbizvegegombClick
    end
    object KEZBIZONYFOCIMPANEL: TPanel
      Left = 40
      Top = 16
      Width = 481
      Height = 41
      BevelOuter = bvNone
      Caption = 'Mai napi kezel'#233'si d'#237'j bizonylatai'
      Color = 13684944
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
    end
    object STORNOPANEL: TPanel
      Left = 200
      Top = 16
      Width = 185
      Height = 41
      Caption = 'STORNO'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -37
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object REPRINTGOMB: TBitBtn
      Left = 528
      Top = 24
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'Nyomtat'#225's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = REPRINTGOMBClick
    end
  end
  object hovalasztopanel: TPanel
    Left = -1600
    Top = 152
    Width = 313
    Height = 137
    TabOrder = 3
    Visible = False
    object Shape8: TShape
      Left = 1
      Top = 1
      Width = 311
      Height = 135
      Align = alClient
      Brush.Color = clSilver
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label13: TLabel
      Left = 32
      Top = 16
      Width = 252
      Height = 24
      Caption = 'V'#225'lassza ki a k'#237'v'#225'nt h'#243'napot'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object evcombo: TComboBox
      Left = 32
      Top = 48
      Width = 81
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 0
      Text = '2012'
      OnChange = evcomboChange
    end
    object hocombo: TComboBox
      Left = 120
      Top = 48
      Width = 169
      Height = 32
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 24
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = evcomboChange
    end
    object hookegomb: TButton
      Left = 32
      Top = 96
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'H'#243'nap rendben'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = hookegombClick
    end
    object homegsemgomb: TButton
      Left = 168
      Top = 96
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = homegsemgombClick
    end
  end
  object KEZDIJATADPANEL: TPanel
    Left = -1878
    Top = 56
    Width = 589
    Height = 273
    BevelOuter = bvNone
    Color = clMaroon
    TabOrder = 5
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 589
      Height = 273
      Align = alClient
      Brush.Color = clMaroon
      Pen.Color = clYellow
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 56
      Top = 32
      Width = 500
      Height = 36
      Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK '#193'TAD'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 128
      Top = 88
      Width = 192
      Height = 28
      Caption = 'T'#225'rsp'#233'nzt'#225'r sz'#225'ma:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 152
      Top = 128
      Width = 168
      Height = 28
      Caption = 'Bizonylat sz'#225'ma:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 168
      Top = 176
      Width = 155
      Height = 28
      Caption = #193'tadott '#246'sszeg :'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object atvevopenztarpanel: TPanel
      Left = 328
      Top = 88
      Width = 153
      Height = 33
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object ATADOTTKEZBIZPANEL: TPanel
      Left = 330
      Top = 128
      Width = 153
      Height = 33
      Caption = ' '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object kiadottkezdijedit: TEdit
      Left = 328
      Top = 168
      Width = 153
      Height = 40
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      Text = ' '
      OnEnter = ATVETTKEZDIJEDITEnter
      OnExit = ATVETTKEZDIJEDITExit
      OnKeyDown = kiadottkezdijeditKeyDown
    end
    object ATADOTTKDKONYVELOGOMB: TBitBtn
      Left = 152
      Top = 224
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#246'nyvel'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ATADOTTKDKONYVELOGOMBClick
    end
    object ATADOTTKDMEGSEMGOMB: TBitBtn
      Left = 296
      Top = 224
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = ATADOTTKDMEGSEMGOMBClick
    end
  end
  object valutaDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 376
    Top = 120
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = valutaDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 416
    Top = 120
  end
  object VALUTAQUERY: TIBQuery
    Database = valutaDBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 120
  end
  object kezdijsource: TDataSource
    DataSet = KEZDIJTABLA
    Left = 184
    Top = 128
  end
  object KEZDIJTABLA: TIBTable
    Database = KEZDIJDBASE
    Transaction = KEZDIJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'DATUM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'BIZONYLAT'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'ELOJEL'
        DataType = ftString
        Size = 1
      end
      item
        Name = 'BANKJEGY'
        DataType = ftInteger
      end
      item
        Name = 'PENZTAR'
        DataType = ftString
        Size = 4
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'IDX_KEZELESIDIJ'
        Fields = 'DATUM'
      end>
    StoreDefs = True
    TableName = 'KEZDIJ'
    Left = 56
    Top = 128
    object KEZDIJTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
    object KEZDIJTABLABIZONYLAT: TIBStringField
      FieldName = 'BIZONYLAT'
      Size = 8
    end
    object KEZDIJTABLAELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Size = 1
    end
    object KEZDIJTABLABANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
    end
    object KEZDIJTABLAPENZTAR: TIBStringField
      FieldName = 'PENZTAR'
      Size = 4
    end
    object KEZDIJTABLASTORNO: TSmallintField
      FieldName = 'STORNO'
    end
  end
  object KEZDIJDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = KEZDIJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 128
  end
  object KEZDIJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KEZDIJDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 152
    Top = 128
  end
  object kezdijquery: TIBQuery
    Database = KEZDIJDBASE
    Transaction = KEZDIJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 128
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 152
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 376
    Top = 152
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 416
    Top = 152
  end
end
