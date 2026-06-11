object Form1: TForm1
  Left = 192
  Top = 114
  BorderIcons = [biMinimize]
  BorderStyle = bsNone
  Caption = 'AZ E-KERESKEDELEM ELSZ'#193'MOLTAT'#193'SI T'#193'BL'#193'ZATA'
  ClientHeight = 530
  ClientWidth = 759
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
  object Label1: TLabel
    Left = 72
    Top = 12
    Width = 641
    Height = 41
    Caption = 'A BEK'#220'LD'#214'TT  MATRICA FORGALMAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 416
    Top = 440
    Width = 147
    Height = 31
    Caption = #214'SSZESEN:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object TEMPRACS: TDBGrid
    Left = 16
    Top = 152
    Width = 730
    Height = 281
    Color = 11599871
    DataSource = TEMPSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Times New Roman'
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
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Width = 72
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IRODASZAM'
        Title.Alignment = taCenter
        Title.Caption = 'IRODA'
        Width = 60
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IRODANEV'
        Title.Alignment = taCenter
        Title.Caption = 'IRODA NEVE'
        Width = 152
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'CIKKSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'CIKKSZ'
        Width = 49
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIKKNEV'
        Title.Alignment = taCenter
        Title.Caption = 'CIKK MEGNEVEZ'#201'SE'
        Width = 204
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EGYSEGAR'
        Title.Alignment = taCenter
        Title.Caption = 'EGYS'#201'G'#193'R'
        Width = 78
        Visible = True
      end
      item
        Color = clYellow
        Expanded = False
        FieldName = 'BEFIZETVE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -13
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        Title.Alignment = taCenter
        Visible = True
      end>
  end
  object KILEPOGOMB: TBitBtn
    Left = 272
    Top = 440
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object KIJELZESGOMB: TBitBtn
    Left = 16
    Top = 440
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIJELZ'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 20
    OnClick = KIJELZESGOMBClick
  end
  object GroupBox1: TGroupBox
    Left = 8
    Top = 46
    Width = 271
    Height = 33
    TabOrder = 2
    object RONEMONTH: TRadioButton
      Left = 6
      Top = 11
      Width = 91
      Height = 17
      Caption = 'EGY H'#211'NAP'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = True
      OnClick = RONEMONTHClick
    end
    object RTERM: TRadioButton
      Left = 112
      Top = 11
      Width = 121
      Height = 17
      Caption = 'EGY IDOSZAK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = RTERMClick
    end
  end
  object NAPNEVPANEL: TPanel
    Left = 520
    Top = 54
    Width = 89
    Height = 20
    Caption = 'CS'#220'T'#214'RT'#214'K'
    TabOrder = 3
  end
  object VALTOCOMBO: TComboBox
    Left = 212
    Top = 88
    Width = 201
    Height = 21
    DropDownCount = 30
    ItemHeight = 13
    TabOrder = 4
    Text = 'H'#211'DMEZ'#214'V'#193'S'#193'RHELYI TESCO'
    OnChange = VALTOCOMBOChange
    OnClick = VALTOCOMBOChange
    OnCloseUp = VALTOCOMBOChange
  end
  object GroupBox2: TGroupBox
    Left = 8
    Top = 79
    Width = 200
    Height = 33
    TabOrder = 5
    object RALLOFFICES: TRadioButton
      Left = 8
      Top = 12
      Width = 100
      Height = 17
      Caption = #214'SSZES V'#193'LT'#211
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = True
      OnClick = RALLOFFICESClick
    end
    object RONEOFFICE: TRadioButton
      Left = 112
      Top = 12
      Width = 80
      Height = 17
      Caption = 'EGY V'#193'LT'#211
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = RONEOFFICEClick
    end
  end
  object etarbox: TGroupBox
    Left = 416
    Top = 79
    Width = 209
    Height = 33
    TabOrder = 6
    object RONEVALUESTOCK: TRadioButton
      Left = 120
      Top = 12
      Width = 80
      Height = 17
      Caption = 'EGY '#201'-T'#193'R'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = RONEVALUESTOCKClick
    end
    object RALLVALUESTOCK: TRadioButton
      Left = 8
      Top = 12
      Width = 100
      Height = 17
      Caption = #214'SSZES '#201'-T'#193'R'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      TabStop = True
      OnClick = RALLVALUESTOCKClick
    end
  end
  object GroupBox4: TGroupBox
    Left = 104
    Top = 112
    Width = 550
    Height = 33
    TabOrder = 7
    object RALLITEMS: TRadioButton
      Left = 8
      Top = 12
      Width = 97
      Height = 17
      Caption = #214'SSZES CIKK'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TabStop = True
      OnClick = RPHONEFILLClick
    end
    object RPHONEFILL: TRadioButton
      Left = 104
      Top = 12
      Width = 169
      Height = 17
      Caption = 'CSAK TELEFON FELT'#214'LT'#201'S'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = RPHONEFILLClick
    end
    object RCARLICENSE: TRadioButton
      Left = 272
      Top = 12
      Width = 137
      Height = 17
      Caption = 'CSAK AUT'#211'MATRICA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = RPHONEFILLClick
    end
    object RPAYING: TRadioButton
      Left = 416
      Top = 12
      Width = 129
      Height = 17
      Caption = 'CSAK BEFIZET'#201'SEK'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = RPHONEFILLClick
    end
  end
  object ETARCOMBO: TComboBox
    Left = 628
    Top = 88
    Width = 121
    Height = 21
    ItemHeight = 13
    TabOrder = 8
    Text = 'ETARCOMBO'
    OnChange = ETARCOMBOChange
    OnClick = ETARCOMBOChange
    OnCloseUp = ETARCOMBOChange
  end
  object OSSZESPANEL: TPanel
    Left = 576
    Top = 440
    Width = 169
    Height = 28
    Caption = '123,456,000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
  end
  object IDOSZAKPANEL: TPanel
    Left = 280
    Top = 46
    Width = 470
    Height = 33
    Color = clTeal
    TabOrder = 10
    object GroupBox5: TGroupBox
      Left = 0
      Top = 0
      Width = 468
      Height = 33
      TabOrder = 0
      object Label3: TLabel
        Left = 192
        Top = 9
        Width = 39
        Height = 20
        Caption = '-T'#211'L'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label4: TLabel
        Left = 432
        Top = 8
        Width = 27
        Height = 20
        Caption = '- IG'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object EVCOMBO: TComboBox
        Left = 2
        Top = 9
        Width = 50
        Height = 21
        ItemHeight = 13
        TabOrder = 0
        Text = '2010'
        OnChange = TOLEVCOMBOChange
        OnClick = TOLEVCOMBOChange
        OnCloseUp = TOLEVCOMBOChange
      end
      object HONAPCOMBO: TComboBox
        Left = 52
        Top = 8
        Width = 97
        Height = 21
        DropDownCount = 12
        ItemHeight = 13
        TabOrder = 1
        Text = 'SZEPTEMBER'
        OnChange = TOLEVCOMBOChange
      end
      object TOLNAPCOMBO: TComboBox
        Left = 148
        Top = 8
        Width = 41
        Height = 21
        DropDownCount = 31
        ItemHeight = 13
        TabOrder = 2
        Text = '31'
        OnChange = TOLNAPCOMBOChange
      end
      object IGNAPCOMBO: TComboBox
        Left = 386
        Top = 8
        Width = 41
        Height = 21
        DropDownCount = 31
        ItemHeight = 13
        TabOrder = 3
        Text = '31'
        OnChange = IGNAPCOMBOChange
      end
      object IGEVPANEL: TPanel
        Left = 240
        Top = 8
        Width = 45
        Height = 21
        BevelInner = bvLowered
        Caption = '2001'
        Color = clWhite
        TabOrder = 4
      end
      object IGHONAPPANEL: TPanel
        Left = 288
        Top = 8
        Width = 97
        Height = 21
        BevelInner = bvLowered
        Caption = 'SZEPTEMBER'
        Color = clWhite
        TabOrder = 5
      end
      object jobbfuggony: TPanel
        Left = 54
        Top = 8
        Width = 102
        Height = 23
        BevelOuter = bvNone
        Color = clTeal
        TabOrder = 6
        Visible = False
      end
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 767
    Height = 4
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 12
  end
  object Panel2: TPanel
    Left = 0
    Top = 2
    Width = 4
    Height = 524
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 13
  end
  object Panel3: TPanel
    Left = 0
    Top = 524
    Width = 767
    Height = 4
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 14
  end
  object Panel4: TPanel
    Left = 755
    Top = 2
    Width = 4
    Height = 522
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 15
  end
  object EGYENLEGGOMB: TBitBtn
    Left = 136
    Top = 440
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = #201'VI EGYENLEG'
    Enabled = False
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 17
    OnClick = EGYENLEGGOMBClick
  end
  object MULTEVIGOMB: TBitBtn
    Left = 16
    Top = 472
    Width = 361
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#218'LT '#201'VI ADATOK REGENER'#193'L'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 18
    OnClick = MULTEVIGOMBClick
  end
  object EZEVIGOMB: TBitBtn
    Left = 384
    Top = 472
    Width = 361
    Height = 25
    Cursor = crHandPoint
    Caption = 'IDEI '#201'V REGENER'#193'L'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 19
    OnClick = EZEVIGOMBClick
  end
  object SUMMAPANEL: TPanel
    Left = 688
    Top = 294
    Width = 740
    Height = 401
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 16
    Visible = False
    object summaracs: TDBGrid
      Left = 24
      Top = 16
      Width = 689
      Height = 345
      Color = 13697023
      DataSource = HAVISOURCE
      FixedColor = 10551295
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
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
          Expanded = False
          FieldName = 'HONAP'
          Title.Alignment = taCenter
          Title.Caption = 'H'#211'NAP'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 82
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'NYITO'
          Title.Alignment = taCenter
          Title.Caption = 'NYIT'#211
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 114
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MATRICA'
          Title.Alignment = taCenter
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 114
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TELEFON'
          Title.Alignment = taCenter
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 114
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ATADAS'
          Title.Alignment = taCenter
          Title.Caption = #193'TAD'#193'S'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 114
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ZARO'
          Title.Alignment = taCenter
          Title.Caption = 'Z'#193'R'#211
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 114
          Visible = True
        end>
    end
    object visszagomb: TBitBtn
      Left = 312
      Top = 368
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 1
      OnClick = visszagombClick
    end
  end
  object FUGGONY: TPanel
    Left = 585
    Top = 362
    Width = 744
    Height = 280
    Color = 13697023
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 11
  end
  object termtakaro: TPanel
    Left = 432
    Top = 48
    Width = 321
    Height = 33
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 21
  end
  object BALFUGGONY: TPanel
    Left = 8
    Top = 48
    Width = 201
    Height = 65
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 22
    Visible = False
  end
  object ETARTAKARO: TPanel
    Left = 416
    Top = 80
    Width = 337
    Height = 33
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 23
    Visible = False
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 328
    object TRADEQUERYIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
      Origin = 'TRADE1010.IRODASZAM'
    end
    object TRADEQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'TRADE1010.TIPUS'
      FixedChar = True
      Size = 1
    end
    object TRADEQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'TRADE1010.DATUM'
      FixedChar = True
      Size = 10
    end
    object TRADEQUERYCIKKSZAM: TSmallintField
      FieldName = 'CIKKSZAM'
      Origin = 'TRADE1010.CIKKSZAM'
    end
    object TRADEQUERYCIKKNEV: TIBStringField
      FieldName = 'CIKKNEV'
      Origin = 'TRADE1010.CIKKNEV'
      FixedChar = True
      Size = 33
    end
    object TRADEQUERYEGYSEGAR: TIntegerField
      FieldName = 'EGYSEGAR'
      Origin = 'TRADE1010.EGYSEGAR'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYBEFIZETVE: TIntegerField
      FieldName = 'BEFIZETVE'
      Origin = 'TRADE1010.BEFIZETVE'
      DisplayFormat = '### ### ###'
    end
    object TRADEQUERYIRODANEV: TIBStringField
      FieldName = 'IRODANEV'
      Origin = 'TRADE1010.IRODANEV'
      FixedChar = True
      Size = 24
    end
    object TRADEQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'TRADE1010.ERTEKTAR'
    end
  end
  object TRADEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
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
    Top = 328
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 328
  end
  object TEMPSOURCE: TDataSource
    DataSet = TEMPQUERY
    Left = 32
    Top = 176
  end
  object CIKKTORZSQUERY: TIBQuery
    Database = CIKKTORZSDBASE
    Transaction = CIKKTORZSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 296
  end
  object IRODAQUERY: TIBQuery
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 264
  end
  object CIKKTORZSDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\MATCIKKEK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = CIKKTORZSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 296
  end
  object IRODADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IRODATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 264
  end
  object CIKKTORZSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CIKKTORZSDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 296
  end
  object IRODATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IRODADBASE
    AutoStopAction = saNone
    Left = 120
    Top = 264
  end
  object HTRADETABLA: TIBTable
    Database = HTRADEDBASE
    Transaction = HTRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 232
  end
  object HTRADEQUERY: TIBQuery
    Database = HTRADEDBASE
    Transaction = HTRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 232
  end
  object HTRADEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HTRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 232
  end
  object HTRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HTRADEDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 232
  end
  object TRADETABLA: TIBTable
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftSmallint
      end
      item
        Name = 'TIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'CIKKSZAM'
        DataType = ftSmallint
      end
      item
        Name = 'CIKKNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 33
      end
      item
        Name = 'EGYSEGAR'
        DataType = ftInteger
      end
      item
        Name = 'BEFIZETVE'
        DataType = ftInteger
      end
      item
        Name = 'IRODANEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 24
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'IDX_1010'
        Fields = 'DATUM;IRODASZAM'
      end
      item
        Name = 'IDX_10101'
        Fields = 'IRODASZAM'
      end
      item
        Name = 'IDX_10102'
        Fields = 'DATUM'
      end>
    StoreDefs = True
    TableName = 'TRADE1010'
    Left = 24
    Top = 328
    object TRADETABLAIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
    end
    object TRADETABLATIPUS: TIBStringField
      FieldName = 'TIPUS'
      FixedChar = True
      Size = 1
    end
    object TRADETABLADATUM: TIBStringField
      FieldName = 'DATUM'
      FixedChar = True
      Size = 10
    end
    object TRADETABLACIKKSZAM: TSmallintField
      FieldName = 'CIKKSZAM'
    end
    object TRADETABLACIKKNEV: TIBStringField
      FieldName = 'CIKKNEV'
      FixedChar = True
      Size = 33
    end
    object TRADETABLAEGYSEGAR: TIntegerField
      FieldName = 'EGYSEGAR'
      DisplayFormat = '### ### ###'
    end
    object TRADETABLABEFIZETVE: TIntegerField
      FieldName = 'BEFIZETVE'
      DisplayFormat = '### ### ###'
    end
    object TRADETABLAIRODANEV: TIBStringField
      FieldName = 'IRODANEV'
      FixedChar = True
      Size = 24
    end
    object TRADETABLAERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
    end
  end
  object SUMMAQUERY: TIBQuery
    Database = SUMMADBASE
    Transaction = SUMMATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM OSSZESITO'
      '')
    Left = 568
    Top = 160
  end
  object SUMMADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = SUMMATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 592
    Top = 160
  end
  object SUMMATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SUMMADBASE
    AutoStopAction = saNone
    Left = 624
    Top = 160
  end
  object IBTable1: TIBTable
    Database = SUMMADBASE
    Transaction = SUMMATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'IRODASZAM'
    StoreDefs = True
    TableName = 'OSSZESITO'
    Left = 464
    Top = 168
    object IBTable1IRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
    end
    object IBTable1BEVETEL: TIntegerField
      FieldName = 'BEVETEL'
    end
    object IBTable1KIADAS: TIntegerField
      FieldName = 'KIADAS'
    end
    object IBTable1NYITO: TIntegerField
      FieldName = 'NYITO'
    end
    object IBTable1ZARO: TIntegerField
      FieldName = 'ZARO'
    end
  end
  object HAVITABLA: TIBTable
    Database = HAVIDBASE
    Transaction = HAVITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftSmallint
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftSmallint
      end
      item
        Name = 'HONAP'
        DataType = ftSmallint
      end
      item
        Name = 'NYITO'
        DataType = ftInteger
      end
      item
        Name = 'MATRICA'
        DataType = ftInteger
      end
      item
        Name = 'TELEFON'
        DataType = ftInteger
      end
      item
        Name = 'ATADAS'
        DataType = ftInteger
      end
      item
        Name = 'ZARO'
        DataType = ftInteger
      end>
    IndexDefs = <
      item
        Name = 'X20111'
        Fields = 'IRODASZAM'
      end
      item
        Name = 'X20112'
        Fields = 'IRODASZAM;HONAP'
        Options = [ixUnique]
      end>
    IndexName = 'X20112'
    StoreDefs = True
    TableName = 'HAVI2011'
    Left = 504
    Top = 384
    object HAVITABLAIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
    end
    object HAVITABLAERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
    end
    object HAVITABLAHONAP: TSmallintField
      FieldName = 'HONAP'
    end
    object HAVITABLANYITO: TIntegerField
      FieldName = 'NYITO'
      DisplayFormat = '### ### ###'
    end
    object HAVITABLAMATRICA: TIntegerField
      FieldName = 'MATRICA'
      DisplayFormat = '### ### ###'
    end
    object HAVITABLATELEFON: TIntegerField
      FieldName = 'TELEFON'
      DisplayFormat = '### ### ###'
    end
    object HAVITABLAATADAS: TIntegerField
      FieldName = 'ATADAS'
      DisplayFormat = '### ### ###'
    end
    object HAVITABLAZARO: TIntegerField
      FieldName = 'ZARO'
      DisplayFormat = '### ### ###'
    end
  end
  object HAVIDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 536
    Top = 384
  end
  object HAVITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIDBASE
    AutoStopAction = saNone
    Left = 568
    Top = 384
  end
  object HAVISOURCE: TDataSource
    DataSet = HAVITABLA
    Left = 600
    Top = 384
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM STRADE')
    Left = 72
    Top = 176
    object TEMPQUERYIRODASZAM: TSmallintField
      FieldName = 'IRODASZAM'
      Origin = 'STRADE.IRODASZAM'
    end
    object TEMPQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'STRADE.DATUM'
      FixedChar = True
      Size = 10
    end
    object TEMPQUERYCIKKSZAM: TSmallintField
      FieldName = 'CIKKSZAM'
      Origin = 'STRADE.CIKKSZAM'
    end
    object TEMPQUERYCIKKNEV: TIBStringField
      FieldName = 'CIKKNEV'
      Origin = 'STRADE.CIKKNEV'
      FixedChar = True
      Size = 33
    end
    object TEMPQUERYEGYSEGAR: TIntegerField
      FieldName = 'EGYSEGAR'
      Origin = 'STRADE.EGYSEGAR'
      DisplayFormat = '### ### ###'
    end
    object TEMPQUERYBEFIZETVE: TIntegerField
      FieldName = 'BEFIZETVE'
      Origin = 'STRADE.BEFIZETVE'
      DisplayFormat = '### ### ###'
    end
    object TEMPQUERYIRODANEV: TIBStringField
      FieldName = 'IRODANEV'
      Origin = 'STRADE.IRODANEV'
      FixedChar = True
      Size = 24
    end
    object TEMPQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'STRADE.ERTEKTAR'
    end
    object TEMPQUERYTIPUS: TIBStringField
      FieldName = 'TIPUS'
      Origin = 'STRADE.TIPUS'
      FixedChar = True
      Size = 1
    end
  end
  object TEMPDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 176
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 176
  end
end
