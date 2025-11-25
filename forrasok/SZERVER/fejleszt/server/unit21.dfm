object ARFOLYAMTMK: TARFOLYAMTMK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'ARFOLYAMTMK'
  ClientHeight = 529
  ClientWidth = 748
  Color = clTeal
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
    Brush.Color = 170
    Pen.Color = clWhite
    Pen.Width = 8
  end
  object Shape1: TShape
    Left = 88
    Top = 144
    Width = 569
    Height = 273
    Brush.Color = 16311512
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 152
    Top = 64
    Width = 425
    Height = 37
    Caption = #193'RFOLYAMOK BE'#193'LLIT'#193'SA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object CANCELGOMB: TBitBtn
    Left = 544
    Top = 376
    Width = 89
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = CANCELGOMBClick
    OnEnter = BitBtn2Enter
    OnExit = BitBtn2Exit
    OnMouseMove = BitBtn2MouseMove
  end
  object ARFOLYAMRACS: TDBGrid
    Left = 104
    Top = 168
    Width = 545
    Height = 200
    Cursor = crHandPoint
    BorderStyle = bsNone
    Color = 16311512
    DataSource = ARFOLYAMSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnKeyDown = ARFOLYAMRACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Title.Alignment = taCenter
        Title.Caption = 'VNEM'
        Title.Color = 8421631
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 81
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEV'
        Title.Alignment = taCenter
        Title.Caption = 'VALUTA NEVE'
        Title.Color = 8421631
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 270
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELSZAMOLASIARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = 'ELSZ-I '#193'RFOLYAM'
        Title.Color = 8421631
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 163
        Visible = True
      end>
  end
  object BitBtn2: TBitBtn
    Left = 368
    Top = 376
    Width = 73
    Height = 25
    Cursor = crHandPoint
    Caption = #218'J VALUTA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnEnter = BitBtn2Enter
    OnExit = BitBtn2Exit
    OnMouseMove = BitBtn2MouseMove
  end
  object BitBtn3: TBitBtn
    Left = 440
    Top = 376
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'VALUTA T'#214'RL'#201'SE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnEnter = BitBtn2Enter
    OnExit = BitBtn2Exit
    OnMouseMove = BitBtn2MouseMove
  end
  object BitBtn1: TBitBtn
    Left = 248
    Top = 376
    Width = 121
    Height = 25
    Cursor = crHandPoint
    Caption = #193'RFOLYAM K'#220'LD'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = BitBtn1Click
    OnEnter = BitBtn2Enter
    OnExit = BitBtn2Exit
    OnMouseMove = BitBtn2MouseMove
  end
  object BitBtn4: TBitBtn
    Left = 120
    Top = 376
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = #193'RFOLYAM BET'#214'LT'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = BitBtn4Click
    OnEnter = BitBtn2Enter
    OnExit = BitBtn2Exit
    OnMouseMove = BitBtn2MouseMove
  end
  object ARFOLYAMTABLA: TIBTable
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
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
        Name = 'VALUTANEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end
      item
        Name = 'VETELIARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'ELADASIARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'ELSZAMOLASIARFOLYAM'
        DataType = ftFloat
      end>
    IndexDefs = <
      item
        Name = 'IDX_ARFOLYAM'
        Fields = 'VALUTANEM'
      end>
    IndexFieldNames = 'VALUTANEM'
    StoreDefs = True
    TableName = 'ARFOLYAM'
    Left = 24
    Top = 216
    object ARFOLYAMTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object ARFOLYAMTABLAVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
      FixedChar = True
    end
    object ARFOLYAMTABLAELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      DisplayFormat = '###,###.00'
    end
  end
  object ARFOLYAMDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 24
    Top = 256
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFOLYAMDBASE
    AutoStopAction = saNone
    Left = 24
    Top = 296
  end
  object ARFOLYAMSOURCE: TDataSource
    DataSet = ARFOLYAMTABLA
    Left = 24
    Top = 328
  end
  object ArfolyamQuery: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 176
  end
end
