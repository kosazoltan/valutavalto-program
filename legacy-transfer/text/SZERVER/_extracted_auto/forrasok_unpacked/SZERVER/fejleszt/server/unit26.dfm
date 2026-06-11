object BANKFORGALOMDISPLAY: TBANKFORGALOMDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'BANKFORGALOMDISPLAY'
  ClientHeight = 446
  ClientWidth = 704
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
    Left = 112
    Top = 8
    Width = 517
    Height = 40
    Caption = 'ID'#214'SZAKI BANKI FORGALOM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 352
    Top = 384
    Width = 81
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object idoszakpanel: TPanel
    Left = 136
    Top = 48
    Width = 465
    Height = 33
    Caption = '2009 SZEPTEMBER 25 - 30'
    Color = clInactiveCaptionText
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object DBGrid1: TDBGrid
    Left = 136
    Top = 96
    Width = 465
    Height = 273
    Color = clSilver
    DataSource = bankforgsource
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -19
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Color = clMoneyGreen
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 135
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FELVETTKP'
        Title.Alignment = taCenter
        Title.Color = clMoneyGreen
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 150
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BEFIZETETTKP'
        Title.Alignment = taCenter
        Title.Color = clMoneyGreen
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 150
        Visible = True
      end>
  end
  object BANKFORGTABLA: TIBTable
    Database = BANKFORGDBASE
    Transaction = BANKFORGTRANZ
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
        Name = 'FELVETTKP'
        DataType = ftFloat
      end
      item
        Name = 'BEFIZETETTKP'
        DataType = ftFloat
      end
      item
        Name = 'CEGBETU'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end>
    IndexDefs = <
      item
        Name = 'IDX_SUMBANKFORGALOM'
        Fields = 'VALUTANEM'
      end>
    StoreDefs = True
    TableName = 'SUMBANKFORGALOM'
    Left = 272
    Top = 192
    object BANKFORGTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object BANKFORGTABLAFELVETTKP: TFloatField
      FieldName = 'FELVETTKP'
      DisplayFormat = '###,###,###'
    end
    object BANKFORGTABLABEFIZETETTKP: TFloatField
      FieldName = 'BEFIZETETTKP'
      DisplayFormat = '###,###,###'
    end
  end
  object BANKFORGDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BANKFORGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 304
    Top = 192
  end
  object BANKFORGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BANKFORGDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 192
  end
  object bankforgsource: TDataSource
    DataSet = BANKFORGTABLA
    Left = 304
    Top = 224
  end
end
