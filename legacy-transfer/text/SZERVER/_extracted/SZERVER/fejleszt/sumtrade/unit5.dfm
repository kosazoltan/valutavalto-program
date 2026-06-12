object EREDMENYKIJELZES: TEREDMENYKIJELZES
  Left = 193
  Top = 108
  BorderStyle = bsSingle
  Caption = 'EREDMENYKIJELZES'
  ClientHeight = 652
  ClientWidth = 1226
  Color = 4539717
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
    Left = 8
    Top = 48
    Width = 1209
    Height = 577
    Brush.Color = 11184810
  end
  object Label1: TLabel
    Left = 576
    Top = 11
    Width = 39
    Height = 31
    Caption = '-t'#243'l'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 744
    Top = 12
    Width = 31
    Height = 31
    Caption = '-ig'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object DBGrid1: TDBGrid
    Left = 16
    Top = 64
    Width = 1185
    Height = 545
    BorderStyle = bsNone
    Color = 11599871
    DataSource = TRADESOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Color = clYellow
        Expanded = False
        FieldName = 'IRODASZAM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'IRODA'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Color = clYellow
        Expanded = False
        FieldName = 'ERTEKTAR'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'K'#214'RZET'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NYITO'
        Title.Alignment = taCenter
        Title.Caption = 'NYIT'#211
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'MATRICA'
        Title.Alignment = taCenter
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TELEFON'
        Title.Alignment = taCenter
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VODAFON'
        Title.Alignment = taCenter
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TELENOR'
        Title.Alignment = taCenter
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PAYSAFECARD'
        Title.Alignment = taCenter
        Title.Caption = 'PAYSAFE'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ATVETEL'
        Title.Alignment = taCenter
        Title.Caption = #193'TV'#201'TEL'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ATADAS'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = #193'TAD'#193'S'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Color = clYellow
        Expanded = False
        FieldName = 'ZARO'
        Title.Alignment = taCenter
        Title.Caption = 'Z'#193'R'#211
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'SZAMZARO'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'MITOTT'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Width = 88
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'STATUS'
        Title.Alignment = taCenter
        Title.Caption = 'ST'#193'TUSZ'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Visible = True
      end>
  end
  object TOLPANEL: TPanel
    Left = 440
    Top = 12
    Width = 129
    Height = 37
    Caption = '2011.02.01'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object IGPANEL: TPanel
    Left = 624
    Top = 12
    Width = 113
    Height = 37
    Caption = '2011.02.16'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object BitBtn1: TBitBtn
    Left = 512
    Top = 616
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 8
    Top = 8
    Width = 241
    Height = 33
    Cursor = crHandPoint
    Caption = 'EXCELT'#193'BLA K'#201'SZ'#205'T'#336
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = BitBtn2Click
  end
  object TRADESOURCE: TDataSource
    DataSet = TRADEQUERY
    Left = 152
    Top = 368
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'select * from sumtrade')
    Left = 56
    Top = 368
    object TRADEQUERYPENZTAR: TIntegerField
      FieldName = 'PENZTAR'
      Origin = 'SUMTRADE.PENZTAR'
    end
    object TRADEQUERYSTATUS: TIBStringField
      FieldName = 'STATUS'
      Origin = 'SUMTRADE.STATUS'
      FixedChar = True
      Size = 2
    end
    object TRADEQUERYSZAMZARO: TIntegerField
      FieldName = 'SZAMZARO'
      Origin = 'SUMTRADE.SZAMZARO'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYZARO: TIntegerField
      FieldName = 'ZARO'
      Origin = 'SUMTRADE.ZARO'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYATVETEL: TIntegerField
      FieldName = 'ATVETEL'
      Origin = 'SUMTRADE.ATVETEL'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYATADAS: TIntegerField
      FieldName = 'ATADAS'
      Origin = 'SUMTRADE.ATADAS'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYTELEFON: TIntegerField
      FieldName = 'TELEFON'
      Origin = 'SUMTRADE.TELEFON'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYMATRICA: TIntegerField
      FieldName = 'MATRICA'
      Origin = 'SUMTRADE.MATRICA'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYNYITO: TIntegerField
      FieldName = 'NYITO'
      Origin = 'SUMTRADE.NYITO'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
      Origin = 'SUMTRADE.IRODASZAM'
    end
    object TRADEQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'SUMTRADE.ERTEKTAR'
    end
    object TRADEQUERYVODAFON: TIntegerField
      FieldName = 'VODAFON'
      Origin = 'SUMTRADE.VODAFON'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYPAYSAFECARD: TIntegerField
      FieldName = 'PAYSAFECARD'
      Origin = 'SUMTRADE.PAYSAFECARD'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYTELENOR: TIntegerField
      FieldName = 'TELENOR'
      Origin = 'SUMTRADE.TELENOR'
      DisplayFormat = '### ### ###'
    end
  end
  object TRADEDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 368
  end
  object TRADETRANZ: TIBTransaction
    Active = True
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 368
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 32
    Top = 8
  end
end
