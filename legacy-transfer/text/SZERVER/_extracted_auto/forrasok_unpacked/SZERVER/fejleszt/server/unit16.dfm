object IRODATMK: TIRODATMK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'IRODATMK'
  ClientHeight = 532
  ClientWidth = 752
  Color = 15780519
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape5: TShape
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Brush.Color = 8421631
    Pen.Color = clAqua
    Pen.Width = 8
  end
  object Label1: TLabel
    Left = 96
    Top = 16
    Width = 583
    Height = 43
    Caption = 'A V'#193'LT'#211'IROD'#193'K KARBANTART'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 48
    Top = 136
    Width = 657
    Height = 313
    Brush.Color = 11599871
    Pen.Width = 3
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 96
    Top = 428
    Width = 577
    Height = 34
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object CEGVALTOGOMB: TBitBtn
    Left = 136
    Top = 88
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'C'#201'G V'#193'LT'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGray
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
    OnClick = CEGVALTOGOMBClick
    OnEnter = UJIRODAGOMBEnter
    OnExit = UJIRODAGOMBExt
    OnMouseMove = UJIRODAGOMBMouseMove
  end
  object CEGPANEL: TPanel
    Left = 320
    Top = 88
    Width = 313
    Height = 25
    BevelOuter = bvNone
    Caption = 'EXLUSIVE PANNON CHANGE'
    Color = 16311509
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object MODOSITOGOMB: TBitBtn
    Left = 384
    Top = 432
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'ADAT M'#211'DOSIT'#193'SA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = MODOSITOGOMBClick
  end
  object TORLOGOMB: TBitBtn
    Left = 248
    Top = 432
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'IRODA T'#214'RL'#201'SE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = TORLOGOMBClick
  end
  object UJIRODAGOMB: TBitBtn
    Left = 112
    Top = 432
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = #218'J IRODA FELV'#201'TELE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = UJIRODAGOMBClick
  end
  object VISSZAGOMB: TBitBtn
    Left = 520
    Top = 432
    Width = 131
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A MEN'#220'RE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = VISSZAGOMBClick
  end
  object IRODARACS: TDBGrid
    Left = 58
    Top = 168
    Width = 633
    Height = 257
    BorderStyle = bsNone
    Color = 11599871
    DataSource = IRODASOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = IRODARACSDblClick
    OnKeyDown = IRODARACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'UZLET'
        Title.Alignment = taCenter
        Title.Caption = 'SZ'#193'M'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 56
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VAROS'
        Title.Alignment = taCenter
        Title.Caption = 'V'#193'ROS'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 103
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BOLTNEV'
        Title.Alignment = taCenter
        Title.Caption = 'BOLT NEVE'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'STATUS'
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 66
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BANKKOD'
        Title.Alignment = taCenter
        Title.Caption = 'BANK K'#211'D'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ERTEKTAR'
        Title.Alignment = taCenter
        Title.Caption = #201'T'#193'R'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 53
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'SUNDAYCLOSE'
        Title.Alignment = taCenter
        Title.Caption = 'VAS.'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 47
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'CLOSED'
        Title.Alignment = taCenter
        Title.Caption = 'Z'#193'RVA'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clBlue
        Title.Font.Height = -13
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end>
  end
  object IRODAKARTON: TPanel
    Left = 208
    Top = 344
    Width = 729
    Height = 481
    BevelOuter = bvNone
    BevelWidth = 2
    Color = 16311512
    TabOrder = 2
    object Shape4: TShape
      Left = 224
      Top = 448
      Width = 649
      Height = 321
      Brush.Color = 15780517
      Pen.Width = 2
    end
    object Label2: TLabel
      Left = 48
      Top = 112
      Width = 201
      Height = 29
      Caption = 'AZ IRODA SZ'#193'MA:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 66
      Top = 184
      Width = 155
      Height = 20
      Caption = 'AZ IRODA V'#193'ROSA:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 38
      Top = 216
      Width = 187
      Height = 20
      Caption = 'IRODA MEGNEVEZ'#201'SE:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 384
      Top = 112
      Width = 123
      Height = 29
      Caption = 'BANKK'#211'D:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 48
      Top = 328
      Width = 105
      Height = 21
      Caption = #201'RT'#201'KT'#193'R: '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Bevel1: TBevel
      Left = 48
      Top = 160
      Width = 625
      Height = 9
    end
    object Bevel2: TBevel
      Left = 40
      Top = 304
      Width = 625
      Height = 8
    end
    object Label5: TLabel
      Left = 496
      Top = 184
      Width = 133
      Height = 21
      Caption = 'TELEFONSZ'#193'M'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object IRODASZAMEDIT: TEdit
      Left = 264
      Top = 104
      Width = 73
      Height = 45
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = '134'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = IRODASZAMEDITKeyDown
    end
    object VAROSEDIT: TEdit
      Left = 232
      Top = 179
      Width = 217
      Height = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 16
      ParentFont = False
      TabOrder = 1
      Text = 'ABCDFGRTHZGTRFRG'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = VAROSEDITKeyDown
    end
    object BOLTNEVEDIT: TEdit
      Left = 232
      Top = 216
      Width = 217
      Height = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 16
      ParentFont = False
      TabOrder = 2
      Text = 'BOLTNEVEDIT'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = BOLTNEVEDITKeyDown
    end
    object GroupBox1: TGroupBox
      Left = 48
      Top = 256
      Width = 241
      Height = 41
      Color = 16311513
      ParentColor = False
      TabOrder = 3
      object RADIOPTAR: TRadioButton
        Left = 8
        Top = 12
        Width = 113
        Height = 23
        Caption = 'P'#201'NZT'#193'R'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        OnClick = RADIOPTARClick
      end
      object RADIETAR: TRadioButton
        Left = 120
        Top = 12
        Width = 121
        Height = 22
        Caption = #201'RT'#201'KT'#193'R'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = RADIOPTARClick
      end
    end
    object BANKKODEDIT: TEdit
      Left = 520
      Top = 104
      Width = 89
      Height = 45
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      Text = '3456'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = BANKKODEDITKeyDown
    end
    object ERTEKTAREDIT: TEdit
      Left = 152
      Top = 320
      Width = 49
      Height = 37
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 5
      Text = '2564'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = ERTEKTAREDITKeyDown
    end
    object SUNDAYBOX: TCheckBox
      Left = 432
      Top = 336
      Width = 177
      Height = 22
      Alignment = taLeftJustify
      Caption = 'VAS'#193'RNAP Z'#193'RVA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = RADIOPTARClick
    end
    object MENTESGOMB: TBitBtn
      Left = 200
      Top = 368
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK MENT'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = MENTESGOMBClick
      OnEnter = UJIRODAGOMBEnter
      OnExit = UJIRODAGOMBExt
      OnMouseMove = UJIRODAGOMBMouseMove
    end
    object MEGSEMGOMB: TBitBtn
      Left = 368
      Top = 368
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clGray
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
      OnClick = MEGSEMGOMBClick
      OnEnter = UJIRODAGOMBEnter
      OnExit = UJIRODAGOMBExt
      OnMouseMove = UJIRODAGOMBMouseMove
    end
    object GroupBox2: TGroupBox
      Left = 296
      Top = 256
      Width = 369
      Height = 41
      Color = 16311513
      ParentColor = False
      TabOrder = 9
      object RBEST: TRadioButton
        Left = 16
        Top = 16
        Width = 73
        Height = 17
        Caption = 'BEST'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        OnClick = RADIOPTARClick
      end
      object RPANNON: TRadioButton
        Left = 88
        Top = 16
        Width = 105
        Height = 17
        Caption = 'PANNON'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = RADIOPTARClick
      end
      object REAST: TRadioButton
        Left = 192
        Top = 16
        Width = 80
        Height = 17
        Caption = 'EAST'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = RADIOPTARClick
      end
      object RZALOG: TRadioButton
        Left = 272
        Top = 16
        Width = 113
        Height = 17
        Caption = 'Z'#193'LOG'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
    end
    object TELEFONEDIT: TEdit
      Left = 456
      Top = 216
      Width = 209
      Height = 29
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 15
      ParentFont = False
      TabOrder = 10
      Text = 'EDIT1'
      OnChange = IRODASZAMEDITChange
      OnEnter = IRODASZAMEDITEnter
      OnExit = IRODASZAMEDITExit
      OnKeyDown = TELEFONEDITKeyDown
    end
    object CLOSEDBOX: TCheckBox
      Left = 216
      Top = 336
      Width = 185
      Height = 17
      Alignment = taLeftJustify
      BiDiMode = bdLeftToRight
      Caption = 'TART'#211'SAN Z'#193'RVA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentBiDiMode = False
      ParentFont = False
      TabOrder = 11
      OnClick = RADIOPTARClick
    end
  end
  object TOROLPANEL: TPanel
    Left = 506
    Top = 10
    Width = 473
    Height = 137
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 6
    object Shape3: TShape
      Left = 8
      Top = 8
      Width = 457
      Height = 105
      Brush.Color = clRed
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label8: TLabel
      Left = 32
      Top = 24
      Width = 396
      Height = 19
      Caption = 'BIZTOS, HOGY T'#214'R'#214'LJEM A K'#214'VETKEZ'#214' IROD'#193'T ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object IRNEVPANEL: TPanel
      Left = 16
      Top = 56
      Width = 433
      Height = 25
      BevelOuter = bvNone
      Caption = 'ASDCFVGTRZGTFRTZUZTGHJNHGTZUIOPRT'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object IGENGOMB: TBitBtn
      Left = 104
      Top = 96
      Width = 137
      Height = 25
      Caption = 'T'#214'R'#214'LD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = IGENGOMBClick
      OnEnter = UJIRODAGOMBEnter
      OnExit = UJIRODAGOMBExt
      OnMouseMove = UJIRODAGOMBMouseMove
    end
    object NEMGOMB: TBitBtn
      Left = 256
      Top = 96
      Width = 137
      Height = 25
      Caption = 'NE T'#214'R'#214'LD'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = NEMGOMBClick
      OnEnter = UJIRODAGOMBEnter
      OnExit = UJIRODAGOMBExt
      OnMouseMove = UJIRODAGOMBMouseMove
    end
  end
  object IRODATABLA: TIBTable
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'UZLET'
        DataType = ftInteger
      end
      item
        Name = 'VAROS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 16
      end
      item
        Name = 'BOLTNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 16
      end
      item
        Name = 'STATUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftInteger
      end
      item
        Name = 'BANKKOD'
        Attributes = [faFixed]
        DataType = ftString
        Size = 4
      end
      item
        Name = 'SUNDAYCLOSE'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end>
    IndexDefs = <
      item
        Name = 'IDX_IRODAK'
        Fields = 'UZLET'
      end
      item
        Name = 'IDX_IRODAK1'
        Fields = 'ERTEKTAR'
      end>
    IndexFieldNames = 'UZLET'
    StoreDefs = True
    TableName = 'IRODAK'
    Left = 416
    Top = 272
  end
  object IRODADBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IRODATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 448
    Top = 272
  end
  object IRODATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IRODADBASE
    AutoStopAction = saNone
    Left = 480
    Top = 272
  end
  object IRODASOURCE: TDataSource
    DataSet = IRODAQUERY
    Left = 512
    Top = 272
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 560
    Top = 344
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 592
    Top = 344
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 624
    Top = 344
  end
  object IRODAQUERY: TIBQuery
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM IRODAK')
    Left = 384
    Top = 272
  end
  object DAYBOOKTABLA: TIBTable
    Database = DAYBOOKDBASE
    Transaction = DAYBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 272
  end
  object DAYBOOKDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = DAYBOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 272
  end
  object DAYBOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBOOKDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 272
  end
end
