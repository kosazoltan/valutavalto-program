object KEDVEZMENYLISTA: TKEDVEZMENYLISTA
  Left = 212
  Top = 146
  BorderStyle = bsNone
  Caption = 'KEDVEZMENYLISTA'
  ClientHeight = 530
  ClientWidth = 749
  Color = 15846054
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Brush.Color = 16311512
    Pen.Color = clGradientActiveCaption
    Pen.Width = 8
  end
  object Label3: TLabel
    Left = 32
    Top = 480
    Width = 175
    Height = 19
    Caption = 'KEDVEZM'#201'NY AD'#193'SA:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Panel1: TPanel
    Left = 32
    Top = 16
    Width = 673
    Height = 41
    Caption = 'KIJEL'#214'LT ID'#214'SZAKBAN T'#214'RT'#201'NT '#193'RFOLYAM KEDVEZM'#201'NYEK'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 40
    Top = 72
    Width = 65
    Height = 33
    Caption = 'EGYS'#201'G'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object KORZETPANEL: TPanel
    Left = 104
    Top = 72
    Width = 265
    Height = 33
    Caption = 'P'#201'NZT'#193'RAK '#214'SSZESITETT ADATAI'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object Panel4: TPanel
    Left = 376
    Top = 72
    Width = 81
    Height = 33
    Caption = 'ID'#214'SZAK'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -12
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object IDOSZAKPANEL: TPanel
    Left = 456
    Top = 72
    Width = 249
    Height = 33
    Caption = '2009.02.01 - 2009.02.28'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel6: TPanel
    Left = 40
    Top = 120
    Width = 329
    Height = 169
    Color = clSkyBlue
    TabOrder = 5
    object Label1: TLabel
      Left = 48
      Top = 8
      Width = 206
      Height = 20
      Caption = 'TRANZAKCI'#211' SZERINT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Bevel1: TBevel
      Left = 8
      Top = 27
      Width = 313
      Height = 5
    end
    object Panel8: TPanel
      Left = 8
      Top = 128
      Width = 145
      Height = 33
      Caption = #214'SSZESEN'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel9: TPanel
      Left = 8
      Top = 88
      Width = 145
      Height = 33
      Caption = 'ELAD'#193'SN'#193'L'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel10: TPanel
      Left = 8
      Top = 48
      Width = 145
      Height = 33
      Caption = 'V'#201'TELN'#201'L'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object VETELPANEL: TPanel
      Left = 160
      Top = 48
      Width = 161
      Height = 33
      Caption = '123 456 789 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object ELADPANEL: TPanel
      Left = 160
      Top = 88
      Width = 161
      Height = 33
      Caption = '12 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object SKEDVPANEL: TPanel
      Left = 160
      Top = 128
      Width = 161
      Height = 33
      Caption = '55 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
  end
  object Panel7: TPanel
    Left = 376
    Top = 120
    Width = 329
    Height = 169
    Color = clSkyBlue
    TabOrder = 6
    object Label2: TLabel
      Left = 104
      Top = 8
      Width = 144
      Height = 20
      Caption = 'TIPUS SZERINT'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Bevel2: TBevel
      Left = 8
      Top = 27
      Width = 313
      Height = 5
    end
    object Panel14: TPanel
      Left = 8
      Top = 124
      Width = 185
      Height = 17
      Caption = 'F'#336#201'RT'#201'KT'#193'ROSI'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Panel15: TPanel
      Left = 8
      Top = 104
      Width = 185
      Height = 17
      Caption = #220'GYVEZET'#214'I'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object Panel16: TPanel
      Left = 8
      Top = 62
      Width = 185
      Height = 17
      Caption = #220'GYF'#201'LK'#193'RTYA'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object Panel17: TPanel
      Left = 8
      Top = 84
      Width = 185
      Height = 17
      Caption = 'S'#193'VOS KEDVEZM'#201'NY'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object Panel18: TPanel
      Left = 8
      Top = 144
      Width = 185
      Height = 17
      Caption = #201'RT'#201'KT'#193'ROSI'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object ETARPANEL: TPanel
      Left = 200
      Top = 144
      Width = 121
      Height = 17
      Caption = '1 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
    end
    object FOERTPANEL: TPanel
      Left = 200
      Top = 124
      Width = 121
      Height = 17
      Caption = '5 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 6
    end
    object UGYVEZPANEL: TPanel
      Left = 200
      Top = 104
      Width = 121
      Height = 17
      Caption = '23 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 7
    end
    object SAVOSPANEL: TPanel
      Left = 200
      Top = 84
      Width = 121
      Height = 17
      Caption = '200 000 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object UGYFCARDPANEL: TPanel
      Left = 200
      Top = 62
      Width = 121
      Height = 17
      Caption = '123 456 789 Ft'
      Color = clCream
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
    object Panel3: TPanel
      Left = 8
      Top = 40
      Width = 185
      Height = 17
      Caption = 'P'#201'NZ'#193'ROSI S'#193'V'
      Color = 11599871
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 10
    end
    object PENZTAROSPANEL: TPanel
      Left = 200
      Top = 40
      Width = 121
      Height = 17
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
  end
  object KEDVEZRACS: TDBGrid
    Left = 40
    Top = 304
    Width = 665
    Height = 153
    Color = 13697023
    DataSource = kedvezsource
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 7
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
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = #193'RFOLYAM'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'UJARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = #218'J '#193'RFOLYAM'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ENGEDMENY'
        Title.Alignment = taCenter
        Title.Caption = 'ENGEDM'#201'NY'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BANKJEGY'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'BIZONYLAT'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTAROSNEV'
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'ROS'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Visible = True
      end>
  end
  object BitBtn1: TBitBtn
    Left = 608
    Top = 480
    Width = 97
    Height = 17
    Cursor = crHandPoint
    Caption = 'VISSZA'
    TabOrder = 8
    OnClick = BitBtn1Click
  end
  object engokpanel: TPanel
    Left = 216
    Top = 480
    Width = 281
    Height = 17
    TabOrder = 9
    object DBText1: TDBText
      Left = 0
      Top = 0
      Width = 361
      Height = 17
      DataField = 'ENGEDMENYOK'
      DataSource = kedvezsource
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object KEDVEZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = KEDVEZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 560
    Top = 360
  end
  object KEDVEZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KEDVEZDBASE
    AutoStopAction = saNone
    Left = 600
    Top = 360
  end
  object kedvezsource: TDataSource
    DataSet = KEDVEZTABLA
    Left = 24
    Top = 360
  end
  object KEDVEZTABLA: TIBTable
    Database = KEDVEZDBASE
    Transaction = KEDVEZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODA'
        DataType = ftSmallint
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftSmallint
      end
      item
        Name = 'DATUM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'VALUTANEM'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'UJARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'PENZTAROSNEV'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'BIZONYLATSZAM'
        DataType = ftString
        Size = 7
      end
      item
        Name = 'BANKJEGY'
        DataType = ftFloat
      end
      item
        Name = 'RATETYPE'
        DataType = ftSmallint
      end
      item
        Name = 'ENGEDMENY'
        DataType = ftFloat
      end
      item
        Name = 'ENGEDMENYOK'
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <
      item
        Name = 'IDX_ARFOLYAMELTERITES'
        Fields = 'IRODA;VALUTANEM'
      end
      item
        Name = 'IDX_ARFOLYAMELTERITES1'
        Fields = 'ERTEKTAR;IRODA'
      end>
    IndexFieldNames = 'ERTEKTAR;IRODA'
    StoreDefs = True
    TableName = 'ARFOLYAMELTERITES'
    Left = 496
    Top = 360
    object KEDVEZTABLAIRODA: TSmallintField
      FieldName = 'IRODA'
    end
    object KEDVEZTABLAERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
    end
    object KEDVEZTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
    object KEDVEZTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object KEDVEZTABLAARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      DisplayFormat = '###,###'
    end
    object KEDVEZTABLAUJARFOLYAM: TFloatField
      FieldName = 'UJARFOLYAM'
      DisplayFormat = '###,###'
    end
    object KEDVEZTABLAPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Size = 25
    end
    object KEDVEZTABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Size = 7
    end
    object KEDVEZTABLABANKJEGY: TFloatField
      FieldName = 'BANKJEGY'
      DisplayFormat = '###,###,###'
    end
    object KEDVEZTABLARATETYPE: TSmallintField
      FieldName = 'RATETYPE'
    end
    object KEDVEZTABLAENGEDMENY: TFloatField
      FieldName = 'ENGEDMENY'
      DisplayFormat = '###,###,###'
    end
    object KEDVEZTABLAENGEDMENYOK: TIBStringField
      FieldName = 'ENGEDMENYOK'
    end
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTIMERTimer
    Left = 24
    Top = 8
  end
end
