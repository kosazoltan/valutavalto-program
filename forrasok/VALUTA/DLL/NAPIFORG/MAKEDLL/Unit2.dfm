object NAPIFORGALOMFORM: TNAPIFORGALOMFORM
  Left = 192
  Top = 112
  AlphaBlendValue = 200
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'NAPIFORGALOMFORM'
  ClientHeight = 715
  ClientWidth = 1004
  Color = 6513507
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 176
    Top = 24
    Width = 755
    Height = 55
    Caption = 'A NAPI FORGALOM KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -48
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object ESCAPEGOMB: TBitBtn
    Left = 816
    Top = 672
    Width = 163
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    TabOrder = 0
    OnClick = ESCAPEGOMBClick
  end
  object ADATRACS: TDBGrid
    Left = 40
    Top = 136
    Width = 953
    Height = 513
    Color = clSilver
    DataSource = HZARSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Color = clGray
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clYellow
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'VALUTA'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 104
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'NYITO'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'NYIT'#211
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 136
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETEL'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'V'#193'S'#193'RL'#193'S'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 153
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADAS'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'ELAD'#193'S'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 141
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ATADAS'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = #193'TAD'#193'S'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 131
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ATVETEL'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = #193'TV'#201'TEL'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 133
        Visible = True
      end
      item
        Alignment = taCenter
        Color = clYellow
        Expanded = False
        FieldName = 'ZARO'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'Z'#193'R'#211
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Width = 133
        Visible = True
      end>
  end
  object NYOMTATOGOMB: TBitBtn
    Left = 56
    Top = 672
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'NYOMTAT'#193'S'
    TabOrder = 2
    OnClick = NYOMTATOGOMBClick
  end
  object HZARSOURCE: TDataSource
    DataSet = HAVIZARTABLA
    Left = 80
    Top = 232
  end
  object HAVIZARTABLA: TIBTable
    Database = HAVIZARDBASE
    Transaction = HAVIZARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'VALUTANEM'
    TableName = 'HAVIZAR'
    Left = 16
    Top = 16
    object HAVIZARTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object HAVIZARTABLANYITO: TIntegerField
      FieldName = 'NYITO'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAELADAS: TIntegerField
      FieldName = 'ELADAS'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAZARO: TIntegerField
      FieldName = 'ZARO'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAZAROFORINTERTEK: TIntegerField
      FieldName = 'ZAROFORINTERTEK'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
    end
    object HAVIZARTABLAVETELIARFOLYAM: TFloatField
      FieldName = 'VETELIARFOLYAM'
    end
    object HAVIZARTABLAELADASIARFOLYAM: TFloatField
      FieldName = 'ELADASIARFOLYAM'
    end
    object HAVIZARTABLAELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
    end
    object HAVIZARTABLAVETEL: TIntegerField
      FieldName = 'VETEL'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAATVETEL: TIntegerField
      FieldName = 'ATVETEL'
      DisplayFormat = '###,###,###'
    end
    object HAVIZARTABLAATADAS: TIntegerField
      FieldName = 'ATADAS'
      DisplayFormat = '###,###,###'
    end
  end
  object HAVIZARDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVIZARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object HAVIZARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIZARDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 48
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 48
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 112
    Top = 48
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 88
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 88
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 88
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 112
    Top = 88
  end
end
