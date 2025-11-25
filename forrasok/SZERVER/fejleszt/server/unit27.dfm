object PENZTARKOZOTTIDISPLAY: TPENZTARKOZOTTIDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'PENZTARKOZOTTIDISPLAY'
  ClientHeight = 496
  ClientWidth = 742
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
  object Label1: TLabel
    Left = 48
    Top = 16
    Width = 655
    Height = 40
    Caption = 'P'#201'NZT'#193'RAK K'#214'Z'#214'TTI P'#201'NZMOZG'#193'SOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 576
    Top = 456
    Width = 139
    Height = 25
    Cancel = True
    Caption = 'VISSZA'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object IDOSZAKPANEL: TPanel
    Left = 24
    Top = 64
    Width = 689
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
    Width = 689
    Height = 345
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
        Width = 100
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
        Width = 100
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
        Width = 120
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
        Width = 120
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
        Width = 94
        Visible = True
      end>
  end
  object PTKOZTTABLA: TIBTable
    Database = PTKOZTDBASE
    Transaction = PTKOZTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'KULDO'
        DataType = ftInteger
      end
      item
        Name = 'FOGADO'
        DataType = ftInteger
      end
      item
        Name = 'KULDOTT'
        DataType = ftFloat
      end
      item
        Name = 'FOGADOTT'
        DataType = ftFloat
      end
      item
        Name = 'STATUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 2
      end>
    IndexDefs = <
      item
        Name = 'IDX_PENZTARKOZOTT'
        Fields = 'VALUTANEM;KULDO;FOGADO'
      end>
    StoreDefs = True
    TableName = 'PENZTARKOZOTT'
    Left = 24
    Top = 328
    object PTKOZTTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object PTKOZTTABLAKULDO: TIntegerField
      FieldName = 'KULDO'
    end
    object PTKOZTTABLAFOGADO: TIntegerField
      FieldName = 'FOGADO'
    end
    object PTKOZTTABLAKULDOTT: TFloatField
      FieldName = 'KULDOTT'
      DisplayFormat = '###,###,###'
    end
    object PTKOZTTABLAFOGADOTT: TFloatField
      FieldName = 'FOGADOTT'
      DisplayFormat = '###,###,###'
    end
    object PTKOZTTABLASTATUS: TIBStringField
      FieldName = 'STATUS'
      FixedChar = True
      Size = 2
    end
  end
  object PTKOZTDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PTKOZTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 328
  end
  object PTKOZTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PTKOZTDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 328
  end
  object PTKOZTSOURCE: TDataSource
    DataSet = PTKOZTTABLA
    Left = 24
    Top = 368
  end
end
