object KESZLETDISPLAY: TKESZLETDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KESZLETDISPLAY'
  ClientHeight = 446
  ClientWidth = 719
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
    Left = 144
    Top = 8
    Width = 414
    Height = 28
    Caption = 'ID'#214'SZAKI K'#201'SZLETEK KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 40
    Top = 40
    Width = 649
    Height = 73
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 8
    Top = 128
    Width = 697
    Height = 233
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 32
    Top = 376
    Width = 657
    Height = 57
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Panel1: TPanel
    Left = 48
    Top = 48
    Width = 633
    Height = 25
    BevelOuter = bvNone
    Caption = 'VIZSG'#193'LT IRODA: IROD'#193'K '#214'SSZESITETT ADATAI'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object IDOSZAKPANEL: TPanel
    Left = 48
    Top = 80
    Width = 633
    Height = 25
    BevelOuter = bvNone
    Caption = 'VIZSG'#193'LT ID'#214'SZAK: 2008 SZEPTEMBER 22 - 28'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object KESZLETRACS: TDBGrid
    Left = 24
    Top = 136
    Width = 665
    Height = 217
    DataSource = KESZLETSOURCE
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
        Color = clAqua
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'VAL'
        Width = 33
        Visible = True
      end
      item
        Color = clYellow
        Expanded = False
        FieldName = 'KESZLET'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'K'#201'SZLET'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET1'
        Title.Caption = '20.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET2'
        Title.Alignment = taCenter
        Title.Caption = '10.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET3'
        Title.Alignment = taCenter
        Title.Caption = '5.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET4'
        Title.Alignment = taCenter
        Title.Caption = '2.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET5'
        Title.Alignment = taCenter
        Title.Caption = '1.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET6'
        Title.Alignment = taCenter
        Title.Caption = '500'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET7'
        Title.Alignment = taCenter
        Title.Caption = '200'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET8'
        Title.Alignment = taCenter
        Title.Caption = '100'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET9'
        Title.Alignment = taCenter
        Title.Caption = '50'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET10'
        Title.Alignment = taCenter
        Title.Caption = '20'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET11'
        Title.Alignment = taCenter
        Title.Caption = '10'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET12'
        Title.Alignment = taCenter
        Title.Caption = '5'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET13'
        Title.Alignment = taCenter
        Title.Caption = '2'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET14'
        Title.Alignment = taCenter
        Title.Caption = '1'
        Width = 40
        Visible = True
      end>
  end
  object Panel3: TPanel
    Left = 262
    Top = 384
    Width = 100
    Height = 17
    Caption = 'FORINT '#201'RT'#201'K'
    Color = 9474303
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object TPanel
    Left = 44
    Top = 384
    Width = 100
    Height = 17
    Caption = 'VALUTA '#201'RT'#201'K'
    Color = 9474303
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object BitBtn2: TBitBtn
    Left = 360
    Top = 408
    Width = 177
    Height = 17
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A MEN'#220'RE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = BitBtn2Click
    OnEnter = POSTAGOMBEnter
    OnExit = POSTAGOMBExit
    OnMouseMove = POSTAGOMBMouseMove
  end
  object VALUTAPANEL: TPanel
    Left = 147
    Top = 384
    Width = 102
    Height = 17
    BevelOuter = bvNone
    Caption = '123 245 000'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
  end
  object FORINTPANEL: TPanel
    Left = 364
    Top = 384
    Width = 101
    Height = 17
    BevelOuter = bvNone
    Caption = '250 000 000'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 7
  end
  object Panel5: TPanel
    Left = 474
    Top = 384
    Width = 100
    Height = 17
    Caption = #214'SSZES '#201'RT'#201'K'
    Color = 9474303
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object OSSZESPANEL: TPanel
    Left = 576
    Top = 384
    Width = 105
    Height = 17
    BevelOuter = bvNone
    Caption = '180 000 000'
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
  end
  object POSTAGOMB: TBitBtn
    Left = 176
    Top = 408
    Width = 177
    Height = 17
    Cursor = crHandPoint
    Caption = 'LISTA KIIR'#193'SA A POST'#193'BA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
    OnClick = PostabaTesz
    OnEnter = POSTAGOMBEnter
    OnExit = POSTAGOMBExit
    OnMouseMove = POSTAGOMBMouseMove
  end
  object KESZLETTABLA: TIBTable
    Database = KESZLETDBASE
    Transaction = keszlettranz
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftInteger
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftInteger
      end
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ELSZAMOLASIARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'KESZLET'
        DataType = ftFloat
      end
      item
        Name = 'FORINTERTEK'
        DataType = ftFloat
      end
      item
        Name = 'CIMLET1'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET2'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET3'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET4'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET5'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET6'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET7'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET8'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET9'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET10'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET11'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET12'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET13'
        DataType = ftInteger
      end
      item
        Name = 'CIMLET14'
        DataType = ftInteger
      end>
    StoreDefs = True
    TableName = 'CIMLETGYUJTO'
    Left = 32
    Top = 320
    object KESZLETTABLAIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
    end
    object KESZLETTABLAERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
    end
    object KESZLETTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object KESZLETTABLAELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
    end
    object KESZLETTABLAFORINTERTEK: TFloatField
      FieldName = 'FORINTERTEK'
    end
    object KESZLETTABLAKESZLET: TFloatField
      FieldName = 'KESZLET'
      DisplayFormat = '###,###,###'
    end
    object KESZLETTABLACIMLET1: TIntegerField
      FieldName = 'CIMLET1'
    end
    object KESZLETTABLACIMLET2: TIntegerField
      FieldName = 'CIMLET2'
    end
    object KESZLETTABLACIMLET3: TIntegerField
      FieldName = 'CIMLET3'
    end
    object KESZLETTABLACIMLET5: TIntegerField
      FieldName = 'CIMLET5'
    end
    object KESZLETTABLACIMLET6: TIntegerField
      FieldName = 'CIMLET6'
    end
    object KESZLETTABLACIMLET7: TIntegerField
      FieldName = 'CIMLET7'
    end
    object KESZLETTABLACIMLET8: TIntegerField
      FieldName = 'CIMLET8'
    end
    object KESZLETTABLACIMLET9: TIntegerField
      FieldName = 'CIMLET9'
    end
    object KESZLETTABLACIMLET10: TIntegerField
      FieldName = 'CIMLET10'
    end
    object KESZLETTABLACIMLET11: TIntegerField
      FieldName = 'CIMLET11'
    end
    object KESZLETTABLACIMLET12: TIntegerField
      FieldName = 'CIMLET12'
    end
    object KESZLETTABLACIMLET13: TIntegerField
      FieldName = 'CIMLET13'
    end
    object KESZLETTABLACIMLET14: TIntegerField
      FieldName = 'CIMLET14'
    end
    object KESZLETTABLACIMLET4: TIntegerField
      FieldName = 'CIMLET4'
    end
  end
  object KESZLETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = keszlettranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 320
  end
  object keszlettranz: TIBTransaction
    Active = False
    DefaultDatabase = KESZLETDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 320
  end
  object KESZLETSOURCE: TDataSource
    DataSet = KESZLETTABLA
    Left = 640
    Top = 328
  end
end
