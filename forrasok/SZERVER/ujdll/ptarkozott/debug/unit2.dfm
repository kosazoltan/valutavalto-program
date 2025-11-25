object PENZTARKOZOTTIDISPLAY: TPENZTARKOZOTTIDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'PENZTARKOZOTTIDISPLAY'
  ClientHeight = 613
  ClientWidth = 870
  Color = 8421631
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
    Width = 870
    Height = 613
    Align = alClient
    Brush.Color = 8421631
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 766
    Height = 42
    Caption = 'P'#201'NZT'#193'RAK K'#214'Z'#214'TTI P'#201'NZMOZG'#193'SOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -35
    Font.Name = 'Verdana'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object QUITGOMB: TBitBtn
    Left = 648
    Top = 568
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'SZERVER MEN'#220'RE'
    TabOrder = 0
    OnClick = QUITGOMBClick
  end
  object IDOSZAKPANEL: TPanel
    Left = 24
    Top = 64
    Width = 825
    Height = 33
    Caption = '2008 SZEPTEMBER 23 - 28'
    Color = 10551295
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object PTKOZTRACS: TDBGrid
    Left = 24
    Top = 104
    Width = 825
    Height = 457
    Color = 12648447
    DataSource = PTKOZTSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
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
        FieldName = 'KULDO'
        Title.Alignment = taCenter
        Title.Caption = 'K'#220'LD'#214
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 132
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'FOGADO'
        Title.Alignment = taCenter
        Title.Caption = 'FOGAD'#211
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 123
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Title.Alignment = taCenter
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 117
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FOGADOTT'
        Title.Alignment = taCenter
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 144
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KULDOTT'
        Title.Alignment = taCenter
        Title.Caption = 'K'#220'LD'#214'TT'
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 143
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'STATUS'
        Title.Alignment = taCenter
        Title.Caption = 'ST'#193'TUSZ'
        Title.Color = 8454143
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsItalic]
        Width = 112
        Visible = True
      end>
  end
  object masadatokgomb: TBitBtn
    Left = 24
    Top = 568
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    TabOrder = 3
    OnClick = masadatokgombClick
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 232
    Top = 568
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'SIK EGYS'#201'G'
    TabOrder = 4
    OnClick = MASEGYSEGGOMBClick
  end
  object MASIDOSZAKGOMB: TBitBtn
    Left = 440
    Top = 568
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'SIK ID'#336'SZAK'
    TabOrder = 5
    OnClick = MASIDOSZAKGOMBClick
  end
  object PARADBASE: TIBDatabase
    Connected = True
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PARATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 304
  end
  object PARATRANZ: TIBTransaction
    Active = True
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 96
    Top = 304
  end
  object PTKOZTSOURCE: TDataSource
    DataSet = PARAQUERY
    Enabled = False
    Left = 32
    Top = 352
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 32
    Top = 304
    object PARAQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'PENZTARKOZOTT.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object PARAQUERYKULDO: TIntegerField
      FieldName = 'KULDO'
      Origin = 'PENZTARKOZOTT.KULDO'
    end
    object PARAQUERYFOGADO: TIntegerField
      FieldName = 'FOGADO'
      Origin = 'PENZTARKOZOTT.FOGADO'
    end
    object PARAQUERYKULDOTT: TFloatField
      FieldName = 'KULDOTT'
      Origin = 'PENZTARKOZOTT.KULDOTT'
      DisplayFormat = '### ### ###'
    end
    object PARAQUERYFOGADOTT: TFloatField
      FieldName = 'FOGADOTT'
      Origin = 'PENZTARKOZOTT.FOGADOTT'
      DisplayFormat = '### ### ###'
    end
    object PARAQUERYSTATUS: TIBStringField
      FieldName = 'STATUS'
      Origin = 'PENZTARKOZOTT.STATUS'
      FixedChar = True
      Size = 2
    end
    object PARAQUERYKULDODNEMFOGADO: TIBStringField
      FieldName = 'KULDODNEMFOGADO'
      Origin = 'PENZTARKOZOTT.KULDODNEMFOGADO'
      FixedChar = True
      Size = 9
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 72
    Top = 352
  end
  object PARATABLA: TIBTable
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 272
  end
end
