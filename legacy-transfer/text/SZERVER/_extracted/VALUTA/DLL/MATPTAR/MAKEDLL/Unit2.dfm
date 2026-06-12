object MATPENZTAR: TMATPENZTAR
  Left = 194
  Top = 107
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'MATPENZTAR'
  ClientHeight = 332
  ClientWidth = 597
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
  object matricaspanel: TPanel
    Left = 0
    Top = 0
    Width = 597
    Height = 329
    BevelOuter = bvNone
    Color = 5658198
    TabOrder = 0
    object Shape3: TShape
      Left = 40
      Top = 120
      Width = 513
      Height = 137
      Shape = stRoundRect
    end
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 597
      Height = 329
      Align = alClient
      Brush.Color = clOlive
      Pen.Width = 5
    end
    object Label8: TLabel
      Left = 40
      Top = 32
      Width = 510
      Height = 43
      Caption = 'ELEKTROMOS-KERESKED'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object BEVETGOMB: TBitBtn
      Left = 56
      Top = 96
      Width = 481
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-KERESKEDELMI P'#201'NZEK '#193'TV'#201'TELE '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = BEVETGOMBClick
    end
    object KIADGOMB: TBitBtn
      Left = 56
      Top = 128
      Width = 481
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-KERESKEDELMI P'#201'NZEK '#193'TAD'#193'SA '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = KIADGOMBClick
    end
    object KESZLETGOMB: TBitBtn
      Left = 56
      Top = 160
      Width = 481
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-KERESKEDELEM  PILLANATNYI K'#201'SZLETE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KESZLETGOMBClick
    end
    object BIZONYLATGOMB: TBitBtn
      Left = 56
      Top = 192
      Width = 481
      Height = 25
      Cursor = crHandPoint
      Caption = 'BIZONYLATOK MEGTEKINT'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = BIZONYLATGOMBClick
    end
    object returngomb: TBitBtn
      Left = 56
      Top = 224
      Width = 481
      Height = 25
      Caption = 'VISSZA A F'#336'MEN'#368'RE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = returngombClick
    end
  end
  object BEVETELPANEL: TPanel
    Left = -1500
    Top = 96
    Width = 537
    Height = 209
    Color = clYellow
    TabOrder = 1
    object Label2: TLabel
      Left = 40
      Top = 16
      Width = 451
      Height = 29
      Caption = 'E-KERESKEDELMI P'#201'NZ '#193'TV'#201'TELE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 104
      Top = 56
      Width = 273
      Height = 23
      Caption = 'T'#193'RSP'#201'NZT'#193'R/BANK SZ'#193'MA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 120
      Top = 88
      Width = 152
      Height = 21
      Caption = 'BIZONYLATSZ'#193'M:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 368
      Top = 122
      Width = 30
      Height = 24
      Caption = 'Ft'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label23: TLabel
      Left = 120
      Top = 120
      Width = 150
      Height = 21
      Caption = #193'TVETT '#214'SSZEG:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object BEBANKSZAMPANEL: TPanel
      Left = 384
      Top = 45
      Width = 57
      Height = 41
      BevelOuter = bvNone
      Caption = 'TRB'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object BEBIZPANEL: TPanel
      Left = 280
      Top = 85
      Width = 113
      Height = 25
      BevelOuter = bvNone
      Caption = 'B-123456'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object BEOSSZEGEDIT: TEdit
      Left = 280
      Top = 119
      Width = 89
      Height = 22
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '155000'
      OnEnter = BEOSSZEGEDITEnter
      OnExit = BEOSSZEGEDITExit
      OnKeyDown = BEOSSZEGEDITKeyDown
    end
    object BEOKEGOMB: TBitBtn
      Left = 32
      Top = 168
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'TRANZAKCI'#211' RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = BEOKEGOMBClick
    end
    object BEMEGSEMGOMB: TBitBtn
      Left = 272
      Top = 168
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = BEMEGSEMGOMBClick
    end
  end
  object KIADASPANEL: TPanel
    Left = -1500
    Top = 96
    Width = 537
    Height = 209
    Color = clYellow
    TabOrder = 2
    object Label7: TLabel
      Left = 56
      Top = 16
      Width = 436
      Height = 29
      Caption = 'E-KERESKEDELMI P'#201'NZ '#193'TAD'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label13: TLabel
      Left = 96
      Top = 56
      Width = 273
      Height = 23
      Caption = 'T'#193'RSP'#201'NZT'#193'R/BANK SZ'#193'MA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label21: TLabel
      Left = 112
      Top = 88
      Width = 152
      Height = 21
      Caption = 'BIZONYLATSZ'#193'M:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label22: TLabel
      Left = 96
      Top = 128
      Width = 158
      Height = 21
      Caption = #193'TADOTT '#214'SSZEG'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label24: TLabel
      Left = 352
      Top = 126
      Width = 30
      Height = 24
      Caption = 'Ft'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object KIBANKSzamPANEL: TPanel
      Left = 376
      Top = 45
      Width = 57
      Height = 41
      BevelOuter = bvNone
      Caption = 'TRB'
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object KIOSSZEGEDIT: TEdit
      Left = 264
      Top = 127
      Width = 89
      Height = 25
      BevelInner = bvNone
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '1254000'
      OnEnter = BEOSSZEGEDITEnter
      OnExit = BEOSSZEGEDITExit
      OnKeyDown = KIOSSZEGEDITKeyDown
    end
    object KIBIZPANEL: TPanel
      Left = 272
      Top = 85
      Width = 113
      Height = 25
      BevelOuter = bvNone
      Caption = 'KIBIZPANEL'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object KIOKEGOMB: TBitBtn
      Left = 32
      Top = 168
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'TRANZAKCI'#211' RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = KIOKEGOMBClick
    end
    object KIMEGSEMGOMB: TBitBtn
      Left = 272
      Top = 168
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = KIMEGSEMGOMBClick
    end
  end
  object PILLKESZPANEL: TPanel
    Left = -1500
    Top = 96
    Width = 537
    Height = 209
    Color = clYellow
    TabOrder = 3
    object Label6: TLabel
      Left = 80
      Top = 24
      Width = 371
      Height = 31
      Caption = 'E-KERESKEDELMI P'#201'NZT'#193'R'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label16: TLabel
      Left = 136
      Top = 56
      Width = 260
      Height = 27
      Caption = 'PILLANATNYI K'#201'SZLETE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object KESZLETDISPLAYPANEL: TPanel
      Left = 176
      Top = 96
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Caption = '12 550 000 Ft'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object PILLVISSZAGOMB: TBitBtn
      Left = 152
      Top = 160
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = PILLVISSZAGOMBClick
    end
  end
  object BIZONYLATPANEL: TPanel
    Left = 30
    Top = 88
    Width = 537
    Height = 209
    BevelOuter = bvNone
    Color = clYellow
    TabOrder = 4
    object Label1: TLabel
      Left = 80
      Top = 8
      Width = 395
      Height = 22
      Caption = 'ELEKTROMOS KERESKED'#201'S BIZONYLATAI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object BIZRACS: TDBGrid
      Left = 8
      Top = 32
      Width = 521
      Height = 137
      DataSource = TRADESOURCE
      FixedColor = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
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
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'BIZONYLAT'
          Title.Color = 13697023
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 72
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = 13697023
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 72
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'OSSZEG'
          Title.Alignment = taCenter
          Title.Caption = 'FORINT'
          Title.Color = 13697023
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 72
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'TARSPENZTAR'
          Title.Alignment = taCenter
          Title.Caption = 'PTAR'
          Title.Color = 13697023
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 42
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTAROS'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'ROS'
          Title.Color = 13697023
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 227
          Visible = True
        end>
    end
    object BIZVISSZAGOMB: TBitBtn
      Left = 96
      Top = 176
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = BIZVISSZAGOMBClick
    end
    object REPRINTGOMB: TBitBtn
      Left = 280
      Top = 176
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = #218'JRANYOMTAT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = REPRINTGOMBClick
    end
  end
  object valutaDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    AllowStreamedConnected = False
    Left = 40
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = True
    DefaultDatabase = valutaDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object TRADESOURCE: TDataSource
    DataSet = VALUTATABLA
    Left = 16
    Top = 64
  end
  object VALUTATABLA: TIBTable
    Database = valutaDBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'BIZONYLATSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 8
      end
      item
        Name = 'PENZTARSZAM'
        DataType = ftSmallint
      end
      item
        Name = 'OSSZEG'
        DataType = ftInteger
      end
      item
        Name = 'BIZONYLATTIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end
      item
        Name = 'PENZTAROS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'TARSPENZTAR'
        Attributes = [faFixed]
        DataType = ftString
        Size = 4
      end
      item
        Name = 'PLOMBASZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end
      item
        Name = 'SZALLITONEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <
      item
        Name = 'ALTXMATBIZONYLAT'
        DescFields = 'DATUM'
        Fields = 'DATUM'
        Options = [ixDescending]
      end>
    StoreDefs = True
    TableName = 'MATBIZONYLAT'
    Left = 8
    Top = 8
    object VALUTATABLADATUM: TIBStringField
      FieldName = 'DATUM'
      FixedChar = True
      Size = 10
    end
    object VALUTATABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      FixedChar = True
      Size = 8
    end
    object VALUTATABLAPENZTARSZAM: TSmallintField
      FieldName = 'PENZTARSZAM'
    end
    object VALUTATABLAOSSZEG: TIntegerField
      FieldName = 'OSSZEG'
      DisplayFormat = '### ### ###'
    end
    object VALUTATABLABIZONYLATTIPUS: TIBStringField
      FieldName = 'BIZONYLATTIPUS'
      FixedChar = True
      Size = 1
    end
    object VALUTATABLASTORNO: TSmallintField
      FieldName = 'STORNO'
    end
    object VALUTATABLAPENZTAROS: TIBStringField
      FieldName = 'PENZTAROS'
      FixedChar = True
      Size = 25
    end
    object VALUTATABLATARSPENZTAR: TIBStringField
      FieldName = 'TARSPENZTAR'
      FixedChar = True
      Size = 4
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = valutaDBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 104
    Top = 8
  end
end
