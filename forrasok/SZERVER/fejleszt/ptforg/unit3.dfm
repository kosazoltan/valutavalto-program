object BEMUTATO: TBEMUTATO
  Left = 196
  Top = 134
  BorderStyle = bsNone
  Caption = 'BEMUTATO'
  ClientHeight = 606
  ClientWidth = 1016
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 1016
    Height = 606
    Align = alClient
    Brush.Color = 13697023
    Pen.Color = clRed
    Pen.Width = 5
  end
  object visszagomb: TButton
    Left = 432
    Top = 560
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = visszagombClick
  end
  object KULDORACS: TDBGrid
    Left = 32
    Top = 64
    Width = 465
    Height = 441
    BorderStyle = bsNone
    DataSource = KULDOSOURCE
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
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
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Times New Roman'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Color = clYellow
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Caption = 'ID'#214
        Title.Color = clYellow
        Width = 45
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'BIZONYLAT'
        Title.Color = clYellow
        Width = 78
        Visible = True
      end
      item
        Color = 11599871
        Expanded = False
        FieldName = 'BANKJEGY'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Color = clYellow
        Width = 80
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTAROSNEV'
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'ROS'
        Title.Color = clYellow
        Width = 176
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PLOMBASZAM'
        Title.Alignment = taCenter
        Title.Caption = 'PLOMBA'
        Title.Color = clYellow
        Width = 100
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SZALLITONEV'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'LLIT'#211
        Title.Color = clYellow
        Width = 160
        Visible = True
      end>
  end
  object FOGADORACS: TDBGrid
    Left = 520
    Top = 64
    Width = 465
    Height = 441
    BorderStyle = bsNone
    DataSource = FOGADOSOURCE
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 2
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
        Width = 69
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Caption = 'ID'#214
        Title.Color = clYellow
        Width = 54
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'BIZONYLAT'
        Title.Color = clYellow
        Width = 84
        Visible = True
      end
      item
        Color = 11599871
        Expanded = False
        FieldName = 'BANKJEGY'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Color = clYellow
        Width = 72
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTAROSNEV'
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'ROS'
        Title.Color = clYellow
        Width = 171
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PLOMBASZAM'
        Title.Alignment = taCenter
        Title.Caption = 'PLOMBA'
        Title.Color = clYellow
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'SZALLITONEV'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'LLIT'#211
        Title.Color = clYellow
        Visible = True
      end>
  end
  object KULDOPANEL: TPanel
    Left = 32
    Top = 8
    Width = 465
    Height = 33
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object FOGADOPANEL: TPanel
    Left = 520
    Top = 8
    Width = 465
    Height = 33
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object KSUMPANEL: TPanel
    Left = 32
    Top = 512
    Width = 465
    Height = 41
    BevelOuter = bvNone
    Color = clGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object FSUMPANEL: TPanel
    Left = 520
    Top = 512
    Width = 465
    Height = 41
    BevelOuter = bvNone
    Color = clMaroon
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object Panel1: TPanel
    Left = 32
    Top = 48
    Width = 953
    Height = 15
    Color = clFuchsia
    TabOrder = 7
  end
  object KULDODBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\V143.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KULDOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 488
  end
  object KULDOTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = KULDODBASE
    AutoStopAction = saNone
    Left = 120
    Top = 488
  end
  object FOGADODBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\V143.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FOGADOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 480
    Top = 488
  end
  object FOGADOTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = FOGADODBASE
    AutoStopAction = saNone
    Left = 512
    Top = 488
  end
  object KULDOQUERY: TIBQuery
    Database = KULDODBASE
    Transaction = KULDOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 488
    object KULDOQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BF1408.DATUM'
      FixedChar = True
      Size = 10
    end
    object KULDOQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BF1408.IDO'
      FixedChar = True
      Size = 8
    end
    object KULDOQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BF1408.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object KULDOQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BF1408.TIPUS'
      FixedChar = True
      Size = 1
    end
    object KULDOQUERYOSSZESEN: TIntegerField
      FieldName = 'OSSZESEN'
      Origin = 'BF1408.OSSZESEN'
    end
    object KULDOQUERYNETTO: TIntegerField
      FieldName = 'NETTO'
      Origin = 'BF1408.NETTO'
    end
    object KULDOQUERYTRANZDIJ: TIntegerField
      FieldName = 'TRANZDIJ'
      Origin = 'BF1408.TRANZDIJ'
    end
    object KULDOQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'BF1408.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object KULDOQUERYUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
      Origin = 'BF1408.UGYFELSZAM'
    end
    object KULDOQUERYUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      Origin = 'BF1408.UGYFELNEV'
      FixedChar = True
      Size = 25
    end
    object KULDOQUERYTETEL: TIntegerField
      FieldName = 'TETEL'
      Origin = 'BF1408.TETEL'
    end
    object KULDOQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'BF1408.PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object KULDOQUERYIDKOD: TIBStringField
      FieldName = 'IDKOD'
      Origin = 'BF1408.IDKOD'
      FixedChar = True
      Size = 5
    end
    object KULDOQUERYPENZTAR: TIBStringField
      FieldName = 'PENZTAR'
      Origin = 'BF1408.PENZTAR'
      FixedChar = True
      Size = 4
    end
    object KULDOQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BF1408.TRBPENZTAR'
      FixedChar = True
      Size = 4
    end
    object KULDOQUERYPLOMBASZAM: TIBStringField
      FieldName = 'PLOMBASZAM'
      Origin = 'BF1408.PLOMBASZAM'
      FixedChar = True
      Size = 10
    end
    object KULDOQUERYSZALLITONEV: TIBStringField
      FieldName = 'SZALLITONEV'
      Origin = 'BF1408.SZALLITONEV'
      FixedChar = True
    end
    object KULDOQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'BF1408.KEZELESIDIJ'
    end
    object KULDOQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BF1408.STORNO'
    end
    object KULDOQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BF1408.STORNOBIZONYLAT'
      FixedChar = True
      Size = 7
    end
    object KULDOQUERYBIZONYLATSZAM1: TIBStringField
      FieldName = 'BIZONYLATSZAM1'
      Origin = 'BT1408.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object KULDOQUERYDATUM1: TIBStringField
      FieldName = 'DATUM1'
      Origin = 'BT1408.DATUM'
      FixedChar = True
      Size = 10
    end
    object KULDOQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'BT1408.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object KULDOQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'BT1408.BANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object KULDOQUERYARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      Origin = 'BT1408.ARFOLYAM'
    end
    object KULDOQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'BT1408.ELSZAMOLASIARFOLYAM'
    end
    object KULDOQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BT1408.FORINTERTEK'
    end
    object KULDOQUERYELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Origin = 'BT1408.ELOJEL'
      FixedChar = True
      Size = 1
    end
    object KULDOQUERYCOIN: TSmallintField
      FieldName = 'COIN'
      Origin = 'BT1408.COIN'
    end
    object KULDOQUERYSTORNO1: TSmallintField
      FieldName = 'STORNO1'
      Origin = 'BT1408.STORNO'
    end
  end
  object FOGADOQUERY: TIBQuery
    Database = FOGADODBASE
    Transaction = FOGADOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 448
    Top = 488
    object FOGADOQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'BF1408.DATUM'
      FixedChar = True
      Size = 10
    end
    object FOGADOQUERYIDO: TIBStringField
      FieldName = 'IDO'
      Origin = 'BF1408.IDO'
      FixedChar = True
      Size = 8
    end
    object FOGADOQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BF1408.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object FOGADOQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'BF1408.TIPUS'
      FixedChar = True
      Size = 1
    end
    object FOGADOQUERYOSSZESEN: TIntegerField
      FieldName = 'OSSZESEN'
      Origin = 'BF1408.OSSZESEN'
    end
    object FOGADOQUERYNETTO: TIntegerField
      FieldName = 'NETTO'
      Origin = 'BF1408.NETTO'
    end
    object FOGADOQUERYTRANZDIJ: TIntegerField
      FieldName = 'TRANZDIJ'
      Origin = 'BF1408.TRANZDIJ'
    end
    object FOGADOQUERYUGYFELTIPUS: TIBStringField
      FieldName = 'UGYFELTIPUS'
      Origin = 'BF1408.UGYFELTIPUS'
      FixedChar = True
      Size = 1
    end
    object FOGADOQUERYUGYFELSZAM: TIntegerField
      FieldName = 'UGYFELSZAM'
      Origin = 'BF1408.UGYFELSZAM'
    end
    object FOGADOQUERYUGYFELNEV: TIBStringField
      FieldName = 'UGYFELNEV'
      Origin = 'BF1408.UGYFELNEV'
      FixedChar = True
      Size = 25
    end
    object FOGADOQUERYTETEL: TIntegerField
      FieldName = 'TETEL'
      Origin = 'BF1408.TETEL'
    end
    object FOGADOQUERYPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Origin = 'BF1408.PENZTAROSNEV'
      FixedChar = True
      Size = 25
    end
    object FOGADOQUERYIDKOD: TIBStringField
      FieldName = 'IDKOD'
      Origin = 'BF1408.IDKOD'
      FixedChar = True
      Size = 5
    end
    object FOGADOQUERYPENZTAR: TIBStringField
      FieldName = 'PENZTAR'
      Origin = 'BF1408.PENZTAR'
      FixedChar = True
      Size = 4
    end
    object FOGADOQUERYTRBPENZTAR: TIBStringField
      FieldName = 'TRBPENZTAR'
      Origin = 'BF1408.TRBPENZTAR'
      FixedChar = True
      Size = 4
    end
    object FOGADOQUERYPLOMBASZAM: TIBStringField
      FieldName = 'PLOMBASZAM'
      Origin = 'BF1408.PLOMBASZAM'
      FixedChar = True
      Size = 10
    end
    object FOGADOQUERYSZALLITONEV: TIBStringField
      FieldName = 'SZALLITONEV'
      Origin = 'BF1408.SZALLITONEV'
      FixedChar = True
    end
    object FOGADOQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'BF1408.KEZELESIDIJ'
    end
    object FOGADOQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'BF1408.STORNO'
    end
    object FOGADOQUERYSTORNOBIZONYLAT: TIBStringField
      FieldName = 'STORNOBIZONYLAT'
      Origin = 'BF1408.STORNOBIZONYLAT'
      FixedChar = True
      Size = 7
    end
    object FOGADOQUERYBIZONYLATSZAM1: TIBStringField
      FieldName = 'BIZONYLATSZAM1'
      Origin = 'BT1408.BIZONYLATSZAM'
      FixedChar = True
      Size = 7
    end
    object FOGADOQUERYDATUM1: TIBStringField
      FieldName = 'DATUM1'
      Origin = 'BT1408.DATUM'
      FixedChar = True
      Size = 10
    end
    object FOGADOQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'BT1408.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object FOGADOQUERYBANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
      Origin = 'BT1408.BANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object FOGADOQUERYARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
      Origin = 'BT1408.ARFOLYAM'
    end
    object FOGADOQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'BT1408.ELSZAMOLASIARFOLYAM'
    end
    object FOGADOQUERYFORINTERTEK: TIntegerField
      FieldName = 'FORINTERTEK'
      Origin = 'BT1408.FORINTERTEK'
    end
    object FOGADOQUERYELOJEL: TIBStringField
      FieldName = 'ELOJEL'
      Origin = 'BT1408.ELOJEL'
      FixedChar = True
      Size = 1
    end
    object FOGADOQUERYCOIN: TSmallintField
      FieldName = 'COIN'
      Origin = 'BT1408.COIN'
    end
    object FOGADOQUERYSTORNO1: TSmallintField
      FieldName = 'STORNO1'
      Origin = 'BT1408.STORNO'
    end
  end
  object KULDOSOURCE: TDataSource
    DataSet = KULDOQUERY
    Left = 160
    Top = 488
  end
  object FOGADOSOURCE: TDataSource
    DataSet = FOGADOQUERY
    Left = 544
    Top = 488
  end
end
