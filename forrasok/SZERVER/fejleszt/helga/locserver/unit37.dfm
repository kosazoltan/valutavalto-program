object WuniWafaControl: TWuniWafaControl
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 529
  ClientWidth = 750
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
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Brush.Color = 8421631
    Pen.Color = clWhite
    Pen.Width = 8
  end
  object Shape1: TShape
    Left = 40
    Top = 104
    Width = 673
    Height = 233
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 96
    Top = 16
    Width = 519
    Height = 36
    Caption = 'WESTERN UNION '#201'S '#193'F'#193' ADATOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clPurple
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 256
    Top = 56
    Width = 196
    Height = 36
    Caption = 'VIZSG'#193'LATA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object CSIK: TProgressBar
    Left = 48
    Top = 352
    Width = 657
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object RACS: TDBGrid
    Left = 56
    Top = 112
    Width = 641
    Height = 217
    BorderStyle = bsNone
    Color = 11599871
    DataSource = DataSource1
    FixedColor = 16311512
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnKeyUp = RACSKeyUp
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IRODASZAM'
        Title.Alignment = taCenter
        Title.Caption = 'IRODA SZ'#193'M'
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 89
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'STATUS'
        Title.Alignment = taCenter
        Title.Caption = 'ST'#193'TUSZ'
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELOHAVIUSDZARO'
        Title.Alignment = taCenter
        Title.Caption = 'MULTHAVI USD Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 143
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'USDNYITO'
        Title.Alignment = taCenter
        Title.Caption = 'USD NYIT'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 76
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'USDBE'
        Title.Alignment = taCenter
        Title.Caption = 'USD BEV'#201'TEL'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 99
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'USDKI'
        Title.Alignment = taCenter
        Title.Caption = 'USD KIAD'#193'S'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 83
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'USDZARO'
        Title.Alignment = taCenter
        Title.Caption = 'USD Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 78
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'SZAMUSDZARO'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'MITOTT'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 71
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELOHAVIHUFZARO'
        Title.Alignment = taCenter
        Title.Caption = 'MULTHAVI HUF Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 142
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'HUFNYITO'
        Title.Alignment = taCenter
        Title.Caption = 'HUF NYIT'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 89
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'HUFBE'
        Title.Alignment = taCenter
        Title.Caption = 'HUF BEV'#201'TEL'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 101
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'HUFKI'
        Title.Alignment = taCenter
        Title.Caption = 'HUF KIAD'#193'S'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 81
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'HUFZARO'
        Title.Alignment = taCenter
        Title.Caption = 'HUF Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 72
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'SZAMHUFZARO'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'MITOTT'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 93
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELOHAVIAFAZARO'
        Title.Alignment = taCenter
        Title.Caption = 'MULTHAVI AFA Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 144
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'AFANYITO'
        Title.Alignment = taCenter
        Title.Caption = 'AFA NYIT'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 84
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'AFABE'
        Title.Alignment = taCenter
        Title.Caption = 'AFA BEV'#201'TEL'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 90
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'AFAKI'
        Title.Alignment = taCenter
        Title.Caption = 'AFA KIAD'#193'S'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 90
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'AFAZARO'
        Title.Alignment = taCenter
        Title.Caption = 'AFA Z'#193'R'#211
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'SZAMAFAZARO'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'MITOTT'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 87
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'HIBAKOD'
        Title.Alignment = taCenter
        Title.Caption = 'HIBAK'#211'D'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -13
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end>
  end
  object KILEPOGOMB: TBitBtn
    Left = 616
    Top = 432
    Width = 97
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    OnClick = KILEPOGOMBClick
  end
  object HIBAJEGYZEK: TMemo
    Left = 48
    Top = 376
    Width = 329
    Height = 97
    Color = 6316287
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Lines.Strings = (
      'HIBAJEGYZEK')
    ParentFont = False
    TabOrder = 3
  end
  object BOLTPANEL: TPanel
    Left = 136
    Top = 144
    Width = 449
    Height = 41
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object VALTOPANEL: TPanel
    Left = 384
    Top = 376
    Width = 321
    Height = 25
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object WZARDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = WZARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 576
    Top = 232
  end
  object WZARTABLA: TIBTable
    Database = WZARDBASE
    Transaction = WZARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 544
    Top = 232
  end
  object WZARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WZARDBASE
    AutoStopAction = saNone
    Left = 608
    Top = 232
  end
  object WUNITABLA: TIBTable
    Database = WUNIDBASE
    Transaction = WUNITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 544
    Top = 200
  end
  object WUNIDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = WUNITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 576
    Top = 200
  end
  object WUNITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUNIDBASE
    AutoStopAction = saNone
    Left = 608
    Top = 200
  end
  object WZARQUERY: TIBQuery
    Database = WZARDBASE
    Transaction = WZARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 232
  end
  object WUCTRLQUERY: TIBQuery
    Database = WUCTRLDBASE
    Transaction = WUCTRLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 192
  end
  object WUCTRLTABLA: TIBTable
    Database = WUCTRLDBASE
    Transaction = WUCTRLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftSmallint
      end
      item
        Name = 'ELOHAVIUSDZARO'
        DataType = ftInteger
      end
      item
        Name = 'ELOHAVIHUFZARO'
        DataType = ftInteger
      end
      item
        Name = 'ELOHAVIAFAZARO'
        DataType = ftInteger
      end
      item
        Name = 'USDNYITO'
        DataType = ftInteger
      end
      item
        Name = 'HUFNYITO'
        DataType = ftInteger
      end
      item
        Name = 'AFANYITO'
        DataType = ftInteger
      end
      item
        Name = 'USDBE'
        DataType = ftInteger
      end
      item
        Name = 'HUFBE'
        DataType = ftInteger
      end
      item
        Name = 'AFABE'
        DataType = ftInteger
      end
      item
        Name = 'USDKI'
        DataType = ftInteger
      end
      item
        Name = 'HUFKI'
        DataType = ftInteger
      end
      item
        Name = 'AFAKI'
        DataType = ftInteger
      end
      item
        Name = 'USDZARO'
        DataType = ftInteger
      end
      item
        Name = 'HUFZARO'
        DataType = ftInteger
      end
      item
        Name = 'AFAZARO'
        DataType = ftInteger
      end
      item
        Name = 'HIBAKOD'
        DataType = ftSmallint
      end
      item
        Name = 'STATUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'SZAMUSDZARO'
        DataType = ftInteger
      end
      item
        Name = 'SZAMHUFZARO'
        DataType = ftInteger
      end
      item
        Name = 'SZAMAFAZARO'
        DataType = ftInteger
      end>
    IndexDefs = <
      item
        Name = 'IDX_WUNICONTROL'
        Fields = 'IRODASZAM'
      end>
    IndexFieldNames = 'IRODASZAM'
    StoreDefs = True
    TableName = 'WUNICONTROL'
    Left = 304
    Top = 192
    object WUCTRLTABLAIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
    end
    object WUCTRLTABLAELOHAVIUSDZARO: TIntegerField
      FieldName = 'ELOHAVIUSDZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAELOHAVIHUFZARO: TIntegerField
      FieldName = 'ELOHAVIHUFZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAELOHAVIAFAZARO: TIntegerField
      FieldName = 'ELOHAVIAFAZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAUSDNYITO: TIntegerField
      FieldName = 'USDNYITO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAHUFNYITO: TIntegerField
      FieldName = 'HUFNYITO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAAFANYITO: TIntegerField
      FieldName = 'AFANYITO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAUSDBE: TIntegerField
      FieldName = 'USDBE'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAHUFBE: TIntegerField
      FieldName = 'HUFBE'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAAFABE: TIntegerField
      FieldName = 'AFABE'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAUSDKI: TIntegerField
      FieldName = 'USDKI'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAHUFKI: TIntegerField
      FieldName = 'HUFKI'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAAFAKI: TIntegerField
      FieldName = 'AFAKI'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAUSDZARO: TIntegerField
      FieldName = 'USDZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAHUFZARO: TIntegerField
      FieldName = 'HUFZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAAFAZARO: TIntegerField
      FieldName = 'AFAZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLAHIBAKOD: TSmallintField
      FieldName = 'HIBAKOD'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLASTATUS: TIBStringField
      FieldName = 'STATUS'
      FixedChar = True
      Size = 3
    end
    object WUCTRLTABLASZAMUSDZARO: TIntegerField
      FieldName = 'SZAMUSDZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLASZAMHUFZARO: TIntegerField
      FieldName = 'SZAMHUFZARO'
      DisplayFormat = '###,###,###'
    end
    object WUCTRLTABLASZAMAFAZARO: TIntegerField
      FieldName = 'SZAMAFAZARO'
      DisplayFormat = '###,###,###'
    end
  end
  object WUCTRLDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = WUCTRLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 336
    Top = 192
  end
  object WUCTRLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUCTRLDBASE
    AutoStopAction = saNone
    Left = 368
    Top = 192
  end
  object WUNIQUERY: TIBQuery
    Database = WUNIDBASE
    Transaction = WUNITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 200
  end
  object WAFATABLA: TIBTable
    Database = WAFADBASE
    Transaction = wafatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 304
    Top = 224
  end
  object WAFAQUERY: TIBQuery
    Database = WAFADBASE
    Transaction = wafatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 224
  end
  object WAFADBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = wafatranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 336
    Top = 224
  end
  object wafatranz: TIBTransaction
    Active = False
    DefaultDatabase = WAFADBASE
    AutoStopAction = saNone
    Left = 368
    Top = 224
  end
  object DataSource1: TDataSource
    DataSet = WUCTRLTABLA
    Left = 24
    Top = 264
  end
end
