object ARFOLYAMTMKFORM: TARFOLYAMTMKFORM
  Left = 237
  Top = 111
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'ARFOLYAMTMKFORM'
  ClientHeight = 769
  ClientWidth = 1019
  Color = clActiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = -6
    Top = -30
    Width = 1024
    Height = 785
    Color = 4539717
    TabOrder = 0
    object Label1: TLabel
      Left = 176
      Top = 40
      Width = 714
      Height = 37
      Caption = 'A VALUTA '#193'RFOLYAMOK KARBANTART'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label16: TLabel
      Left = 352
      Top = 104
      Width = 308
      Height = 24
      Caption = '(VALUTA M'#211'DOSIT'#193'SA -> ENTER)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object ARFOLYAMRACS: TDBGrid
      Left = 128
      Top = 184
      Width = 761
      Height = 513
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = clBtnFace
      DataSource = ARFOLYAMSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clNavy
      TitleFont.Height = -19
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = ARFOLYAMRACSDblClick
      OnKeyDown = ARFOLYAMRACSKeyDown
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'VALUTANEM'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clTeal
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Alignment = taCenter
          Title.Caption = 'DNEM'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 82
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VALUTANEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Times New Roman'
          Font.Style = [fsBold, fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'VALUTA MEGNEVEZ'#201'SE'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 247
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VETELIARFOLYAM'
          Title.Alignment = taCenter
          Title.Caption = 'V'#201'TELI '#193'RF.'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 133
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELADASIARFOLYAM'
          Title.Alignment = taCenter
          Title.Caption = 'ELAD'#193'SI '#193'RF.'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 136
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELSZAMOLASIARFOLYAM'
          Title.Alignment = taCenter
          Title.Caption = 'ELSZ-I '#193'RF.'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clBlack
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 123
          Visible = True
        end>
    end
    object ESCAPEGOMB: TBitBtn
      Left = 712
      Top = 704
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA A F'#336'MEN'#368'RE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = ESCAPEGOMBClick
    end
    object LETOLTOGOMB: TBitBtn
      Left = 128
      Top = 704
      Width = 209
      Height = 25
      Cursor = crHandPoint
      Caption = #193'RFOLYAMOK LET'#214'LT'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = LETOLTOGOMBClick
    end
    object NYOMTATOGOMB: TBitBtn
      Left = 552
      Top = 704
      Width = 150
      Height = 25
      Cursor = crHandPoint
      Caption = 'NYOMTAT'#193'S  (F8)'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = NYOMTATOGOMBClick
    end
    object NYOMTATOPANEL: TPanel
      Left = 144
      Top = 264
      Width = 465
      Height = 113
      BevelOuter = bvNone
      Color = 11599871
      TabOrder = 4
      OnClick = NYOMTATOPANELClick
      object Shape6: TShape
        Left = 8
        Top = 8
        Width = 449
        Height = 97
        Shape = stRoundRect
      end
      object Shape1: TShape
        Left = 0
        Top = 0
        Width = 465
        Height = 113
        Align = alClient
        Pen.Color = clMaroon
        Pen.Width = 2
      end
      object ARFNYOMGOMB: TBitBtn
        Left = 16
        Top = 24
        Width = 433
        Height = 25
        Cursor = crHandPoint
        Caption = #193'RFOLYAMOKAT NYOMTATOK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
        OnClick = ARFNYOMGOMBClick
        OnEnter = ARFNYOMGOMBEnter
        OnExit = ARFNYOMGOMBExit
      end
      object ELSZARFNYOMGOMB: TBitBtn
        Left = 16
        Top = 64
        Width = 433
        Height = 25
        Cursor = crHandPoint
        Caption = 'ELSZ'#193'MOL'#211' '#193'RFOLYAMOKAT NYOMTATOK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = ELSZARFNYOMGOMBClick
        OnEnter = ARFNYOMGOMBEnter
        OnExit = ARFNYOMGOMBExit
      end
    end
    object MNBLETOLTOGOMB: TBitBtn
      Left = 704
      Top = 104
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'MNB '#193'RFOLYAM LET'#214'LT'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = MNBLETOLTOGOMBClick
    end
    object GOMBTAKAROPANEL: TPanel
      Left = 24
      Top = 736
      Width = 921
      Height = 41
      BevelOuter = bvNone
      Color = 4539717
      TabOrder = 6
    end
    object KEZIALLITOGOMB: TBitBtn
      Left = 344
      Top = 704
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#201'ZI '#193'RFOLYAM'#193'LLIT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = KEZIALLITOGOMBClick
    end
  end
  object TMKPANEL: TPanel
    Left = -1980
    Top = 110
    Width = 513
    Height = 481
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 1
    object Panel3: TPanel
      Left = 16
      Top = 40
      Width = 481
      Height = 209
      BevelOuter = bvNone
      Color = clSilver
      TabOrder = 0
      object Shape2: TShape
        Left = 0
        Top = 0
        Width = 481
        Height = 209
        Align = alClient
        Brush.Color = clSilver
        Pen.Width = 3
      end
      object Label2: TLabel
        Left = 72
        Top = 16
        Width = 153
        Height = 28
        Caption = 'VALUTANEM:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 16
        Top = 50
        Width = 215
        Height = 21
        Caption = 'VALUTA MEGNEVEZ'#201'SE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 80
        Top = 140
        Width = 150
        Height = 19
        Caption = 'V'#201'TELI '#193'RFOLYAM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label5: TLabel
        Left = 72
        Top = 176
        Width = 161
        Height = 19
        Caption = 'ELAD'#193'SI '#193'RFOLYAM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 32
        Top = 106
        Width = 203
        Height = 19
        Caption = 'ELSZ'#193'MOL'#193'SI '#193'RFOLYAM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label11: TLabel
        Left = 328
        Top = 138
        Width = 63
        Height = 22
        Caption = 'FT/100'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label12: TLabel
        Left = 328
        Top = 174
        Width = 63
        Height = 22
        Caption = 'FT/100'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label13: TLabel
        Left = 328
        Top = 104
        Width = 63
        Height = 22
        Caption = 'FT/100'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DNEM1LABEL: TLabel
        Left = 400
        Top = 138
        Width = 39
        Height = 22
        Caption = 'AAA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DNEM2LABEL: TLabel
        Left = 400
        Top = 174
        Width = 39
        Height = 22
        Caption = 'AAA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DNEM3LABEL: TLabel
        Left = 400
        Top = 104
        Width = 39
        Height = 22
        Caption = 'AAA'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object VARFEDIT: TEdit
        Tag = 2
        Left = 240
        Top = 136
        Width = 81
        Height = 30
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        Text = '12345'
        OnChange = ELSZARFEDITChange
        OnEnter = DNEVEDITEnter
        OnExit = DNEVEDITExit
        OnKeyDown = VARFEDITKeyDown
      end
      object EARFEDIT: TEdit
        Tag = 3
        Left = 240
        Top = 168
        Width = 81
        Height = 30
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        Text = '12345'
        OnChange = ELSZARFEDITChange
        OnEnter = DNEVEDITEnter
        OnExit = DNEVEDITExit
        OnKeyDown = EARFEDITKeyDown
      end
      object ELSZARFEDIT: TEdit
        Tag = 4
        Left = 240
        Top = 102
        Width = 81
        Height = 30
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        Text = '12345'
        OnChange = ELSZARFEDITChange
        OnEnter = DNEVEDITEnter
        OnExit = ELSZARFEDITExit
        OnKeyDown = ELSZARFEDITKeyDown
      end
      object DNEMPANEL: TPanel
        Left = 312
        Top = 10
        Width = 73
        Height = 33
        BevelOuter = bvNone
        Caption = 'USD'
        Color = clSilver
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clTeal
        Font.Height = -32
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
      end
      object DNEVPANEL: TPanel
        Left = 232
        Top = 40
        Width = 241
        Height = 41
        BevelOuter = bvNone
        Caption = 'AUSZTR'#193'L DOLL'#193'R'
        Color = clSilver
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object Panel5: TPanel
        Left = 8
        Top = 80
        Width = 465
        Height = 9
        TabOrder = 5
      end
    end
    object Panel4: TPanel
      Left = 16
      Top = 264
      Width = 481
      Height = 161
      BevelOuter = bvNone
      Color = clGray
      TabOrder = 1
      object Shape3: TShape
        Left = 0
        Top = 0
        Width = 481
        Height = 161
        Align = alClient
        Brush.Color = clGray
        Pen.Width = 3
      end
      object Label7: TLabel
        Left = 40
        Top = 24
        Width = 135
        Height = 24
        Caption = 'NYIT'#211#214'SSZEG'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label8: TLabel
        Left = 88
        Top = 56
        Width = 86
        Height = 24
        Caption = 'BEV'#201'TEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label9: TLabel
        Left = 104
        Top = 88
        Width = 67
        Height = 24
        Caption = 'KIAD'#193'S'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object Label10: TLabel
        Left = 40
        Top = 120
        Width = 131
        Height = 24
        Caption = 'Z'#193'R'#211#214'SSZEG'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object DNEM4LABEL: TLabel
        Left = 416
        Top = 24
        Width = 33
        Height = 20
        Caption = 'AAA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object DNEM5LABEL: TLabel
        Left = 416
        Top = 56
        Width = 33
        Height = 20
        Caption = 'AAA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object DNEM6LABEL: TLabel
        Left = 416
        Top = 88
        Width = 33
        Height = 20
        Caption = 'AAA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object DNEM7LABEL: TLabel
        Left = 416
        Top = 120
        Width = 33
        Height = 20
        Caption = 'AAA'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
      end
      object NYITOPANEL: TPanel
        Left = 208
        Top = 24
        Width = 193
        Height = 25
        Caption = '234 500 000'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object BEVETELPANEL: TPanel
        Left = 208
        Top = 56
        Width = 193
        Height = 25
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object KIADASPANEL: TPanel
        Left = 208
        Top = 88
        Width = 193
        Height = 25
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object ZAROPANEL: TPanel
        Left = 208
        Top = 120
        Width = 193
        Height = 25
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
      end
    end
    object SICCGOMB: TBitBtn
      Left = 272
      Top = 448
      Width = 179
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = SICCGOMBClick
    end
    object arfolyamokegomb: TBitBtn
      Left = 64
      Top = 448
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'ARFOLYAMOK RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = arfolyamokegombClick
    end
  end
  object ARFOLYAMSOURCE: TDataSource
    DataSet = ARFOLYAMQUERY
    Left = 104
    Top = 504
  end
  object ARFOLYAMDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 32
    Top = 176
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = ARFOLYAMDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 64
    Top = 176
  end
  object HARDWARETABLA: TIBTable
    Database = HARDWAREDBASE
    Transaction = HARDWARETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'HARDWARE'
    Left = 8
    Top = 8
  end
  object HARDWAREDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HARDWARETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object HARDWARETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HARDWAREDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
  object HARDWAREQUERY: TIBQuery
    Database = HARDWAREDBASE
    Transaction = HARDWARETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 112
    Top = 8
  end
  object ARFOLYAMQUERY: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 96
    Top = 176
    object ARFOLYAMQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'ARFOLYAM.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object ARFOLYAMQUERYVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
      Origin = 'ARFOLYAM.VALUTANEV'
      FixedChar = True
    end
    object ARFOLYAMQUERYVETELIARFOLYAM: TFloatField
      FieldName = 'VETELIARFOLYAM'
      Origin = 'ARFOLYAM.VETELIARFOLYAM'
      DisplayFormat = '### ###.#'
    end
    object ARFOLYAMQUERYELADASIARFOLYAM: TFloatField
      FieldName = 'ELADASIARFOLYAM'
      Origin = 'ARFOLYAM.ELADASIARFOLYAM'
      DisplayFormat = '### ###.#'
    end
    object ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'ARFOLYAM.ELSZAMOLASIARFOLYAM'
      DisplayFormat = '### ###.#'
    end
    object ARFOLYAMQUERYMODOSITOSZAZALEK: TFloatField
      FieldName = 'MODOSITOSZAZALEK'
      Origin = 'ARFOLYAM.MODOSITOSZAZALEK'
    end
    object ARFOLYAMQUERYNYITO: TIntegerField
      FieldName = 'NYITO'
      Origin = 'ARFOLYAM.NYITO'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYBEVETEL: TIntegerField
      FieldName = 'BEVETEL'
      Origin = 'ARFOLYAM.BEVETEL'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYKIADAS: TIntegerField
      FieldName = 'KIADAS'
      Origin = 'ARFOLYAM.KIADAS'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYZARO: TIntegerField
      FieldName = 'ZARO'
      Origin = 'ARFOLYAM.ZARO'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYK1VETEL: TFloatField
      FieldName = 'K1VETEL'
      Origin = 'ARFOLYAM.K1VETEL'
      DisplayFormat = '### ###'
    end
    object ARFOLYAMQUERYK2VETEL: TFloatField
      FieldName = 'K2VETEL'
      Origin = 'ARFOLYAM.K2VETEL'
      DisplayFormat = '### ###'
    end
    object ARFOLYAMQUERYK1ELADAS: TFloatField
      FieldName = 'K1ELADAS'
      Origin = 'ARFOLYAM.K1ELADAS'
      DisplayFormat = '### ###'
    end
    object ARFOLYAMQUERYK2ELADAS: TFloatField
      FieldName = 'K2ELADAS'
      Origin = 'ARFOLYAM.K2ELADAS'
      DisplayFormat = '### ###'
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 776
    Top = 224
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
    Left = 808
    Top = 224
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 840
    Top = 224
  end
end
