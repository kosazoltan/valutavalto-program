object SETSZORZO: TSETSZORZO
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'SETSZORZO'
  ClientHeight = 638
  ClientWidth = 549
  Color = clNavy
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 20
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 545
    Height = 633
    Brush.Color = 4473924
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 72
    Top = 16
    Width = 399
    Height = 33
    Caption = 'Jutal'#233'k sz'#225'zezrel'#233'k-szorz'#243'k be'#225'llit'#225'sa'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Arial Narrow'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Button1: TButton
    Left = 72
    Top = 584
    Width = 393
    Height = 25
    Cursor = crHandPoint
    Caption = 'Kil'#233'p'#233's a programb'#243'l'
    TabOrder = 0
    OnClick = Button1Click
  end
  object jutalekracs: TDBGrid
    Left = 16
    Top = 56
    Width = 513
    Height = 513
    Color = 6710886
    DataSource = JUTALEKSOURCE
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 1
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
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ReadOnly = True
        Title.Alignment = taCenter
        Title.Caption = 'IRODA'
        Title.Color = 3355443
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clYellow
        Title.Font.Height = -19
        Title.Font.Name = 'Calibri'
        Title.Font.Style = []
        Width = 76
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IRODANEV'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ReadOnly = True
        Title.Alignment = taCenter
        Title.Caption = 'IRODA MEGNEVEZ'#201'SE'
        Title.Color = 3355443
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clYellow
        Title.Font.Height = -19
        Title.Font.Name = 'Calibri'
        Title.Font.Style = [fsBold]
        Width = 283
        Visible = True
      end
      item
        Alignment = taCenter
        Color = 8947848
        Expanded = False
        FieldName = 'JUTALEKSZORZO'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'SZORZ'#211
        Title.Color = 3355443
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clYellow
        Title.Font.Height = -19
        Title.Font.Name = 'Calibri'
        Title.Font.Style = [fsBold]
        Width = 122
        Visible = True
      end>
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftSmallint
      end
      item
        Name = 'IRODANEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'JUTALEKSZORZO'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'IDX_JUTALEKSZORZO'
        Fields = 'IRODASZAM'
      end>
    IndexFieldNames = 'IRODASZAM'
    StoreDefs = True
    TableName = 'JUTALEKSZORZO'
    Left = 48
    Top = 160
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\JUTALEK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 160
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 160
  end
  object JUTALEKSOURCE: TDataSource
    DataSet = IBTABLA
    Left = 184
    Top = 160
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 200
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 200
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 200
  end
  object IBQuery: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 160
  end
end
