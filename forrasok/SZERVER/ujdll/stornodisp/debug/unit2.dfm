object STORNODISPLAY: TSTORNODISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'STORNODISPLAY'
  ClientHeight = 613
  ClientWidth = 870
  Color = 16311512
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 870
    Height = 613
    Align = alClient
    Brush.Color = 8421631
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Shape1: TShape
    Left = 32
    Top = 72
    Width = 809
    Height = 489
    Brush.Color = 11599871
    Pen.Width = 2
  end
  object Label1: TLabel
    Left = 128
    Top = 16
    Width = 637
    Height = 36
    Caption = 'A STORN'#211' BIZONYLATOK KIJELZ'#201'SE'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'Cooper Black'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 272
    Top = 52
    Width = 352
    Height = 17
    Caption = '(SZ'#193'MLA T'#201'TELEI -> ENTER vagy DUPLA-KLIKK)'
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object QUITGOMB: TBitBtn
    Left = 640
    Top = 568
    Width = 195
    Height = 25
    Cursor = crHandPoint
    Caption = 'SZERVER MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = QUITGOMBClick
  end
  object FEJRACS: TDBGrid
    Left = 48
    Top = 88
    Width = 777
    Height = 465
    Cursor = crHandPoint
    BorderStyle = bsNone
    Color = 11599871
    DataSource = FEJSOURCE
    FixedColor = clWhite
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = FEJRACSDblClick
    OnKeyDown = FEJRACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IRODASZAM'
        Title.Alignment = taCenter
        Title.Caption = 'Iroda'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 67
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#225'tum'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 129
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Caption = 'Id'#246
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 81
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'Bizonylat'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 136
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTAROSNEV'
        Title.Alignment = taCenter
        Title.Caption = 'P'#233'nzt'#225'ros'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 228
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'STORNOINDOK'
        Title.Alignment = taCenter
        Title.Caption = 'Indokl'#225's'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 120
        Visible = True
      end>
  end
  object TETELPANEL: TPanel
    Left = 140
    Top = 180
    Width = 585
    Height = 313
    BevelInner = bvRaised
    BevelWidth = 2
    Color = clMoneyGreen
    TabOrder = 2
    object Label2: TLabel
      Left = 96
      Top = 16
      Width = 388
      Height = 36
      Caption = 'A BIZONYLAT T'#201'TELEI'
      Font.Charset = ANSI_CHARSET
      Font.Color = clGreen
      Font.Height = -32
      Font.Name = 'Cooper Black'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object TETELRACS: TDBGrid
      Left = 24
      Top = 56
      Width = 521
      Height = 209
      DataSource = TETELSOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -16
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IRODASZAM'
          Title.Alignment = taCenter
          Title.Caption = 'Iroda'
          Title.Color = clGreen
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -16
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'Bizonylatsz'#225'm'
          Title.Color = clGreen
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -16
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 124
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'VALUTANEM'
          Title.Alignment = taCenter
          Title.Caption = 'Valuta'
          Title.Color = clGreen
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -16
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKJEGY'
          Title.Alignment = taCenter
          Title.Caption = 'Bankjegy'
          Title.Color = clGreen
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -16
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 110
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'FORINTERTEK'
          Title.Alignment = taCenter
          Title.Caption = #201'rt'#233'k'
          Title.Color = clGreen
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -16
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 110
          Visible = True
        end>
    end
    object visszagomb: TBitBtn
      Left = 224
      Top = 280
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Default = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = visszagombClick
    end
  end
  object masadatokgomb: TBitBtn
    Left = 40
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    TabOrder = 3
    OnClick = masadatokgombClick
  end
  object masegyseggomb: TBitBtn
    Left = 240
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'MAS EGYS'#201'G'
    TabOrder = 4
    OnClick = masegyseggombClick
  end
  object masidoszakgomb: TBitBtn
    Left = 440
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ID'#336'SZAK'
    TabOrder = 5
    OnClick = masidoszakgombClick
  end
  object STORNOTETELDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = STORNOTETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 336
  end
  object STORNOTETELTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = STORNOTETELDBASE
    AutoStopAction = saNone
    Left = 560
    Top = 336
  end
  object STORNOFEJTABLA: TIBTable
    Database = STORNOFEJDBASE
    Transaction = STORNOFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftInteger
      end
      item
        Name = 'BIZONYLATSZAM'
        DataType = ftString
        Size = 7
      end
      item
        Name = 'DATUM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'IDO'
        DataType = ftString
        Size = 8
      end
      item
        Name = 'PENZTAROSNEV'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'STORNOTIPUS'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'STORNOBIZONYLAT'
        DataType = ftString
        Size = 7
      end
      item
        Name = 'STORNOINDOK'
        DataType = ftString
        Size = 20
      end>
    StoreDefs = True
    TableName = 'STORNOFEJ'
    Left = 48
    Top = 136
  end
  object STORNOFEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = STORNOFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 176
  end
  object STORNOFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = STORNOFEJDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 216
  end
  object FEJSOURCE: TDataSource
    DataSet = STORNOFEJQUERY
    Left = 48
    Top = 264
  end
  object TETELSOURCE: TDataSource
    DataSet = STORNOTETELQUERY
    Left = 592
    Top = 336
  end
  object STORNOTETELQUERY: TIBQuery
    Database = STORNOTETELDBASE
    Transaction = STORNOTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 528
    Top = 368
    object STORNOTETELQUERYIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
      Origin = 'STORNOTETEL.IRODASZAM'
    end
    object STORNOTETELQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'STORNOTETEL.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object STORNOTETELQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'STORNOTETEL.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object STORNOTETELQUERYBANKJEGY: TFloatField
      FieldName = 'BANKJEGY'
      Origin = 'STORNOTETEL.BANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object STORNOTETELQUERYFORINTERTEK: TFloatField
      FieldName = 'FORINTERTEK'
      Origin = 'STORNOTETEL.FORINTERTEK'
      DisplayFormat = '### ### ###'
    end
    object STORNOTETELQUERYARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      Origin = 'STORNOTETEL.ARFOLYAM'
    end
    object STORNOTETELQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'STORNOTETEL.ELSZAMOLASIARFOLYAM'
    end
    object STORNOTETELQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'STORNOTETEL.CEGBETU'
      FixedChar = True
      Size = 1
    end
  end
  object STORNOFEJQUERY: TIBQuery
    Database = STORNOFEJDBASE
    Transaction = STORNOFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 304
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 752
    Top = 152
  end
end
