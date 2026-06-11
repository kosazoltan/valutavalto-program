object GETWUGYF: TGETWUGYF
  Left = 192
  Top = 114
  BorderStyle = bsNone
  ClientHeight = 554
  ClientWidth = 992
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 985
    Height = 550
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clLime
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 985
      Height = 550
      Align = alClient
      Brush.Color = 11599871
      Pen.Color = clRed
      Pen.Width = 6
    end
    object Label1: TLabel
      Left = 160
      Top = 24
      Width = 671
      Height = 55
      Caption = 'V'#193'LASSZA KI AZ '#220'GYFELET'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -48
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 24
      Top = 456
      Width = 185
      Height = 28
      Caption = 'KERESETT N'#201'V:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape1: TShape
      Left = 24
      Top = 496
      Width = 937
      Height = 41
      Brush.Color = clYellow
      Pen.Color = clRed
      Pen.Width = 2
    end
    object KERESEDIT: TEdit
      Left = 216
      Top = 456
      Width = 257
      Height = 24
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnEnter = KERESEDITEnter
    end
    object WUGYFELRACS: TDBGrid
      Left = 24
      Top = 88
      Width = 937
      Height = 353
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 10551295
      DataSource = UGYFELSOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
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
      OnDblClick = WUGYFELRACSDblClick
      OnKeyPress = WUGYFELRACSKeyPress
      Columns = <
        item
          Expanded = False
          FieldName = 'NEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Times New Roman'
          Font.Style = [fsBold, fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'Western Union/'#193'fa '#252'gyfelek'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 236
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ANYJANEVE'
          Font.Charset = ANSI_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'Anyja neve'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 161
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'OKMANYTIPUS'
          Title.Alignment = taCenter
          Title.Caption = 'Okm'#225'ny'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 126
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'AZONOSITO'
          Title.Alignment = taCenter
          Title.Caption = 'Azonos'#237't'#243
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 119
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'LAKCIM'
          Title.Alignment = taCenter
          Title.Caption = 'Lakc'#237'm'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 251
          Visible = True
        end>
    end
    object KARTONGOMB: TBitBtn
      Left = 272
      Top = 504
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'KARTON'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KARTONGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
      OnMouseMove = RENDBENGOMBMouseMove
    end
    object ujugyfelgomb: TBitBtn
      Left = 528
      Top = 504
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J '#220'GYF'#201'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ujugyfelgombClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
      OnMouseMove = RENDBENGOMBMouseMove
    end
    object MEGSEMGOMB: TBitBtn
      Left = 776
      Top = 504
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = MEGSEMGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
      OnMouseMove = RENDBENGOMBMouseMove
    end
    object UGYFELKARTON: TPanel
      Left = 648
      Top = 24
      Width = 937
      Height = 401
      BevelOuter = bvNone
      BevelWidth = 2
      Color = clWhite
      TabOrder = 5
      object Shape3: TShape
        Left = 0
        Top = 0
        Width = 937
        Height = 401
        Align = alClient
        Brush.Color = clYellow
        Pen.Color = clRed
        Pen.Width = 2
      end
      object Label3: TLabel
        Left = 336
        Top = 8
        Width = 259
        Height = 43
        Caption = 'Az '#252'gyf'#233'l adatai:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -37
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object Label4: TLabel
        Left = 24
        Top = 112
        Width = 132
        Height = 16
        Caption = 'AZ '#220'GYF'#201'L NEVE:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label5: TLabel
        Left = 512
        Top = 112
        Width = 99
        Height = 16
        Caption = 'ANYJA NEVE:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label6: TLabel
        Left = 24
        Top = 160
        Width = 140
        Height = 16
        Caption = 'SZ'#220'LET'#201'SI HELYE:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label7: TLabel
        Left = 496
        Top = 168
        Width = 134
        Height = 16
        Caption = 'SZ'#220'LET'#201'SI IDEJE:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label8: TLabel
        Left = 88
        Top = 200
        Width = 68
        Height = 16
        Caption = 'LAKC'#205'ME:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label9: TLabel
        Left = 32
        Top = 288
        Width = 127
        Height = 16
        Caption = 'OKM'#193'NY TIPUSA:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label10: TLabel
        Left = 32
        Top = 336
        Width = 123
        Height = 16
        Caption = 'OKM'#193'NY SZ'#193'MA:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object WNEVEDIT: TEdit
        Tag = 1
        Left = 168
        Top = 112
        Width = 289
        Height = 26
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        MaxLength = 30
        ParentFont = False
        TabOrder = 0
        Text = 'ASDEFRGT HZGTFRDER DEFRGTHZUX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WANYJAEDIT: TEdit
        Tag = 2
        Left = 640
        Top = 112
        Width = 257
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 25
        ParentFont = False
        TabOrder = 1
        Text = 'SEDRFTGZH JUHZGTFRE DFRTX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WSZULHELYEDIT: TEdit
        Tag = 3
        Left = 168
        Top = 152
        Width = 289
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        MaxLength = 25
        ParentFont = False
        TabOrder = 2
        Text = 'ASDFRGTZH GTFRDEVFRX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WSZULIDOEDIT: TEdit
        Tag = 4
        Left = 640
        Top = 165
        Width = 257
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 11
        ParentFont = False
        TabOrder = 3
        Text = 'WSZULIDOEDIT'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WLAKCIMEDIT: TEdit
        Tag = 5
        Left = 168
        Top = 192
        Width = 289
        Height = 22
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 35
        ParentFont = False
        TabOrder = 4
        Text = 'ASEDRFGTZ VFRTGRDER DERFGTZHU ASDFX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WOKMTIPEDIT: TEdit
        Tag = 6
        Left = 168
        Top = 280
        Width = 289
        Height = 29
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 20
        ParentFont = False
        TabOrder = 5
        Text = 'ASEDFRTGH TZGTHUJZTX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WAZONOSITOEDIT: TEdit
        Tag = 7
        Left = 168
        Top = 328
        Width = 289
        Height = 29
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 20
        ParentFont = False
        TabOrder = 6
        Text = 'ASDFGTRED FRTGHZVFDX'
        OnChange = WNEVEDITChange
        OnEnter = WNEVEDITEnter
        OnExit = WNEVEDITExit
        OnKeyDown = WNEVEDITKeyDown
      end
      object WESTERNPANEL: TPanel
        Left = 496
        Top = 216
        Width = 401
        Height = 137
        Color = clBlack
        TabOrder = 7
        object Shape4: TShape
          Left = 1
          Top = 1
          Width = 399
          Height = 135
          Align = alClient
          Brush.Color = clBlack
          Pen.Color = clRed
          Pen.Width = 5
        end
        object Label11: TLabel
          Left = 32
          Top = 16
          Width = 273
          Height = 56
          Caption = 'WESTERN'
          Font.Charset = ANSI_CHARSET
          Font.Color = clYellow
          Font.Height = -48
          Font.Name = 'Bodoni MT Black'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
        end
        object Label12: TLabel
          Left = 184
          Top = 64
          Width = 177
          Height = 56
          Caption = 'UNION'
          Font.Charset = ANSI_CHARSET
          Font.Color = clYellow
          Font.Height = -48
          Font.Name = 'Bodoni MT Black'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
        end
      end
      object METROPANEL: TPanel
        Left = 496
        Top = 216
        Width = 401
        Height = 137
        TabOrder = 8
        object Shape6: TShape
          Left = 1
          Top = 1
          Width = 399
          Height = 135
          Align = alClient
          Brush.Color = clGradientActiveCaption
          Pen.Color = clBlue
          Pen.Width = 5
        end
        object Label14: TLabel
          Left = 136
          Top = 40
          Width = 142
          Height = 57
          Caption = 'METRO'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clYellow
          Font.Height = -48
          Font.Name = 'Arial Narrow'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
        end
      end
      object TESCOPANEL: TPanel
        Left = 496
        Top = 216
        Width = 401
        Height = 137
        TabOrder = 9
        object Shape5: TShape
          Left = 1
          Top = 1
          Width = 399
          Height = 135
          Align = alClient
          Pen.Color = clRed
          Pen.Width = 5
        end
        object Label13: TLabel
          Left = 120
          Top = 40
          Width = 168
          Height = 55
          Caption = 'TESCO'
          Font.Charset = ANSI_CHARSET
          Font.Color = clRed
          Font.Height = -48
          Font.Name = 'Arial Rounded MT Bold'
          Font.Style = []
          ParentFont = False
          Transparent = True
        end
      end
    end
    object RENDBENGOMB: TBitBtn
      Left = 32
      Top = 504
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = RENDBENGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
      OnMouseMove = RENDBENGOMBMouseMove
    end
  end
  object UGYFELSOURCE: TDataSource
    DataSet = WUUGYFELTABLA
    Left = 48
    Top = 16
  end
  object WUUGYFELTABLA: TIBTable
    Database = WUUGYFELDBASE
    Transaction = WUUGYFELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'UGYFELSZAM'
        DataType = ftInteger
      end
      item
        Name = 'NEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 30
      end
      item
        Name = 'ANYJANEVE'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'SZULETESIHELY'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end
      item
        Name = 'SZULETESIIDO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 11
      end
      item
        Name = 'LAKCIM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 35
      end
      item
        Name = 'OKMANYTIPUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end
      item
        Name = 'AZONOSITO'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end>
    IndexDefs = <
      item
        Name = 'IDX_WUGYFEL'
        Fields = 'UGYFELSZAM'
      end
      item
        Name = 'IDX_WUGYFEL1'
        Fields = 'NEV'
      end
      item
        Name = 'ALTXWUGYFEL'
        Fields = 'NEV'
      end>
    IndexFieldNames = 'NEV'
    StoreDefs = True
    TableName = 'WUGYFEL'
    Left = 16
    Top = 48
  end
  object WUUGYFELDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = WUUGYFELTRANZ
    IdleTimer = 0
    SQLDialect = 1
    TraceFlags = []
    Left = 16
    Top = 16
  end
  object WUUGYFELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUUGYFELDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 48
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 56
  end
  object VALUTADBASE: TIBDatabase
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
    Left = 208
    Top = 56
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 240
    Top = 56
  end
  object KILEP: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPTimer
    Left = 88
    Top = 16
  end
end
