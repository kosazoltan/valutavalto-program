object STORNODISP: TSTORNODISP
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'STORNODISP'
  ClientHeight = 480
  ClientWidth = 726
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
    Width = 729
    Height = 481
    Brush.Color = 8421631
    Pen.Color = clGradientActiveCaption
    Pen.Width = 8
  end
  object Shape1: TShape
    Left = 32
    Top = 72
    Width = 673
    Height = 353
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 56
    Top = 24
    Width = 615
    Height = 41
    Caption = 'A STORN'#211' BIZONYLATOK KIJELZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 584
    Top = 432
    Width = 123
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object FEJRACS: TDBGrid
    Left = 48
    Top = 88
    Width = 641
    Height = 313
    BorderStyle = bsNone
    Color = 11599871
    DataSource = FEJSOURCE
    FixedColor = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
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
        Width = 49
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#225'tum'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Caption = 'Id'#246
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'Bizonylat'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 86
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
        Width = 115
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'STORNOBIZONYLAT'
        Title.Alignment = taCenter
        Title.Caption = 'St.biz.'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'STORNOTIPUS'
        Title.Alignment = taCenter
        Title.Caption = 'Tipus'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 67
        Visible = True
      end
      item
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
    Left = 40
    Top = 456
    Width = 585
    Height = 313
    BevelInner = bvRaised
    BevelWidth = 2
    Color = clMoneyGreen
    TabOrder = 2
    object Label2: TLabel
      Left = 128
      Top = 16
      Width = 346
      Height = 36
      Caption = 'A BIZONYLAT T'#201'TELEI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGreen
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = []
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
    object BitBtn2: TBitBtn
      Left = 224
      Top = 280
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGreen
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn2Click
    end
  end
  object STORNOTETELTABLA: TIBTable
    Database = STORNOTETELDBASE
    Transaction = STORNOTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftInteger
      end
      item
        Name = 'BIZONYLATSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 7
      end
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'BANKJEGY'
        DataType = ftFloat
      end
      item
        Name = 'FORINTERTEK'
        DataType = ftFloat
      end>
    IndexDefs = <
      item
        Name = 'IDX_STORNOTETEL'
        Fields = 'IRODASZAM;BIZONYLATSZAM'
      end>
    StoreDefs = True
    TableName = 'STORNOTETEL'
    Left = 496
    Top = 336
    object STORNOTETELTABLAIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
    end
    object STORNOTETELTABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      FixedChar = True
      Size = 7
    end
    object STORNOTETELTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object STORNOTETELTABLABANKJEGY: TFloatField
      FieldName = 'BANKJEGY'
      DisplayFormat = '###,###,###'
    end
    object STORNOTETELTABLAFORINTERTEK: TFloatField
      FieldName = 'FORINTERTEK'
      DisplayFormat = '###,###,###'
    end
  end
  object STORNOTETELDBASE: TIBDatabase
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
    Active = False
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
    DataSet = STORNOFEJTABLA
    Left = 48
    Top = 264
  end
  object TETELSOURCE: TDataSource
    DataSet = STORNOTETELTABLA
    Left = 592
    Top = 336
  end
end
