object FORM2: TFORM2
  Left = 435
  Top = 214
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'FORM2'
  ClientHeight = 403
  ClientWidth = 629
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
  object HRKMENUPANEL: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 400
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 640
      Height = 400
      Align = alClient
      Brush.Color = clMoneyGreen
      Pen.Color = clTeal
      Pen.Width = 4
    end
    object Panel2: TPanel
      Left = 48
      Top = 56
      Width = 561
      Height = 41
      BevelOuter = bvNone
      Caption = 'HORV'#193'T KUNA H'#193'ZIP'#201'NZT'#193'R'
      Color = clMoneyGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clTeal
      Font.Height = -32
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object HRKATVEVOGOMB: TBitBtn
      Left = 96
      Top = 152
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'HORV'#193'T KUNA '#193'TV'#201'TELE EGY P'#201'NZT'#193'RB'#211'L'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = HRKATVEVOGOMBClick
    end
    object HRKPILLGOMB: TBitBtn
      Left = 96
      Top = 216
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'HORV'#193'T KUNA JELENLEGI K'#201'SZLETE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = HRKPILLGOMBClick
    end
    object HRKBIZONYLATGOMB: TBitBtn
      Left = 96
      Top = 248
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
      TabOrder = 3
      OnClick = HRKBIZONYLATGOMBClick
    end
    object VISSZAGOMB: TBitBtn
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
      TabOrder = 4
      OnClick = VISSZAGOMBClick
    end
    object HRKATADOGOMB: TBitBtn
      Left = 96
      Top = 184
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'HORV'#193'T KUNA '#193'TAD'#193'SA EGY P'#201'NZT'#193'RNAK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = HRKATADOGOMBClick
    end
    object ATADASPANEL: TPanel
      Left = -1789
      Top = 24
      Width = 589
      Height = 273
      BevelOuter = bvNone
      Color = clMoneyGreen
      TabOrder = 6
      Visible = False
      object Label5: TLabel
        Left = 120
        Top = 24
        Width = 374
        Height = 36
        Caption = 'HORV'#193'T KUNA '#193'TAD'#193'SA'
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -32
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 176
        Top = 88
        Width = 156
        Height = 28
        Caption = 'Bizonylat sz'#225'm:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label7: TLabel
        Left = 88
        Top = 132
        Width = 242
        Height = 28
        Caption = 'A fogad'#243' p'#233'nzt'#225'r sz'#225'ma:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label8: TLabel
        Left = 160
        Top = 176
        Width = 169
        Height = 28
        Caption = #193'tk'#252'ld'#246'tt '#246'sszeg:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object KIPENZTAREDIT: TEdit
        Left = 336
        Top = 128
        Width = 49
        Height = 34
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnEnter = BEKUNAEDITEnter
        OnExit = BEKUNAEDITExit
        OnKeyDown = KIPENZTAREDITKeyDown
      end
      object KIKUNAEDIT: TEdit
        Left = 336
        Top = 168
        Width = 121
        Height = 34
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnEnter = BEKUNAEDITEnter
        OnExit = BEKUNAEDITExit
        OnKeyDown = KIKUNAEDITKeyDown
      end
      object kikonyveloGomb: TBitBtn
        Left = 136
        Top = 232
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'K'#214'NYVEL'#201'S'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = kikonyveloGombClick
      end
      object KIMEGSEMGOMB: TBitBtn
        Left = 304
        Top = 232
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object KIBIZPANEL: TPanel
        Left = 336
        Top = 88
        Width = 121
        Height = 33
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clNavy
        Font.Height = -21
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
    end
  end
  object PILLKEZDIJPANEL: TPanel
    Left = -1500
    Top = 136
    Width = 529
    Height = 209
    BevelOuter = bvNone
    TabOrder = 3
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
  object ATVETELPANEL: TPanel
    Left = -1987
    Top = -50
    Width = 589
    Height = 273
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 1
    Visible = False
    object Label11: TLabel
      Left = 152
      Top = 88
      Width = 168
      Height = 28
      Caption = 'Bizonylat sz'#225'ma:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 120
      Top = 32
      Width = 395
      Height = 36
      Caption = 'HORV'#193'T KUNA '#193'TV'#201'TELE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 184
      Top = 156
      Width = 135
      Height = 28
      Caption = #193'tvett '#246'sszeg:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 448
      Top = 155
      Width = 57
      Height = 31
      Caption = 'HRK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 88
      Top = 120
      Width = 236
      Height = 28
      Caption = 'Bek'#252'ld'#337' p'#233'nzt'#225'r sz'#225'ma:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object BEBIZPANEL: TPanel
      Left = 328
      Top = 92
      Width = 89
      Height = 25
      Caption = ' '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object BEKUNAEDIT: TEdit
      Left = 328
      Top = 158
      Width = 113
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      Text = ' '
      OnEnter = BEKUNAEDITEnter
      OnExit = BEKUNAEDITExit
      OnKeyDown = BEKUNAEDITKeyDown
    end
    object BEKONYVELOGOMB: TBitBtn
      Left = 160
      Top = 224
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'NYVEL'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = BEKONYVELOGOMBClick
    end
    object BEMEGSEMGOMB: TBitBtn
      Left = 328
      Top = 224
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = BEMEGSEMGOMBClick
    end
    object BEPENZTAREDIT: TEdit
      Left = 328
      Top = 124
      Width = 49
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 3
      ParentFont = False
      TabOrder = 4
      Text = ' '
      OnEnter = BEKUNAEDITEnter
      OnExit = BEKUNAEDITExit
      OnKeyDown = BEPENZTAREDITKeyDown
    end
  end
  object BIZONYLATPANEL: TPanel
    Left = 0
    Top = 0
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
    object HRKRACS: TDBGrid
      Left = 32
      Top = 64
      Width = 569
      Height = 265
      DataSource = HRKSOURCE
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
      OnCellClick = HrkRacsCellClick
      OnDblClick = HrkRacsDblClick
      OnKeyUp = HrkRacsKeyUp
      OnMouseUp = HrkRacsMouseUp
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 87
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IDO'
          Title.Alignment = taCenter
          Title.Caption = 'ID'#336
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BEVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'BEV'#201'TEL'
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 102
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'KIADAS'
          Title.Alignment = taCenter
          Title.Caption = 'KIAD'#193'S'
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 98
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'BIZONYLAT'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 125
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAR'
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'R'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 71
          Visible = True
        end>
    end
    object STORNOGOMB: TBitBtn
      Left = 32
      Top = 344
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
      TabOrder = 1
      OnClick = STORNOGOMBClick
    end
    object LISTAVISSZAGOMB: TBitBtn
      Left = 472
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Vissza a men'#369're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = LISTAVISSZAGOMBClick
    end
    object KEZBIZONYFOCIMPANEL: TPanel
      Left = 40
      Top = 16
      Width = 481
      Height = 41
      BevelOuter = bvNone
      Caption = 'A horv'#225't kuna forgalmi bizonylatai'
      Color = 13684944
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object STORNOPANEL: TPanel
      Left = 224
      Top = 280
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
      TabOrder = 4
    end
    object REPRINTGOMB: TBitBtn
      Left = 248
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Nyomtat'#225's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = REPRINTGOMBClick
    end
    object SUREPANEL: TPanel
      Left = -1987
      Top = 160
      Width = 289
      Height = 145
      Color = clSilver
      TabOrder = 6
      Visible = False
      object Shape3: TShape
        Left = 1
        Top = 1
        Width = 287
        Height = 143
        Align = alClient
        Brush.Color = clRed
        Pen.Color = clYellow
        Pen.Width = 3
      end
      object Label9: TLabel
        Left = 16
        Top = 16
        Width = 263
        Height = 18
        Caption = 'BIZTOSAN STORN'#211'ZZAM A BIZONYLATOT ?'
        Color = clRed
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clYellow
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentColor = False
        ParentFont = False
      end
      object SUREGOMB: TBitBtn
        Left = 64
        Top = 40
        Width = 75
        Height = 17
        Cursor = crHandPoint
        Caption = 'IGEN'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnClick = SUREGOMBClick
      end
      object NOSUREGOMB: TBitBtn
        Left = 152
        Top = 40
        Width = 75
        Height = 17
        Cursor = crHandPoint
        Caption = 'NEM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = NOSUREGOMBClick
      end
      object STORNOFEDEL: TPanel
        Left = 16
        Top = 64
        Width = 257
        Height = 73
        BevelOuter = bvNone
        Color = clRed
        TabOrder = 2
        Visible = False
        object Label10: TLabel
          Left = 8
          Top = 8
          Width = 59
          Height = 19
          Caption = 'INDOKA:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clYellow
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object INDOKPANEL: TEdit
          Left = 72
          Top = 5
          Width = 169
          Height = 27
          BorderStyle = bsNone
          CharCase = ecUpperCase
          Color = clWhite
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Calibri'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnEnter = BEKUNAEDITEnter
          OnExit = BEKUNAEDITExit
          OnKeyDown = INDOKPANELKeyDown
        end
        object STORNOGOGOMB: TBitBtn
          Left = 16
          Top = 40
          Width = 107
          Height = 21
          Caption = 'STORNO MEHET'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Calibri'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 1
          OnClick = STORNOGOGOMBClick
        end
        object STORNONOGOMB: TBitBtn
          Left = 136
          Top = 40
          Width = 105
          Height = 21
          Caption = 'NEM STORN'#211'Z'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Calibri'
          Font.Style = [fsBold, fsItalic]
          ParentFont = False
          TabOrder = 2
          OnClick = NOSUREGOMBClick
        end
      end
    end
  end
  object HRKSOURCE: TDataSource
    DataSet = HRKQUERY
    Left = 152
    Top = 144
  end
  object HRKDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\HAZIHRK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 144
  end
  object HRKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HRKDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 120
    Top = 144
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 56
    Top = 144
  end
  object ERTEKTARQUERY: TIBQuery
    Database = ERTEKTARDBASE
    Transaction = ertektarTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
    Top = 136
  end
  object ERTEKTARDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 392
    Top = 136
  end
  object ertektarTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ERTEKTARDBASE
    AutoStopAction = saNone
    Left = 424
    Top = 136
  end
end
