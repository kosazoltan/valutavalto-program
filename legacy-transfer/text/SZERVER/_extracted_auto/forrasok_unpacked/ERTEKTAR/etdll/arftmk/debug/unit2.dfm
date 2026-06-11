object ARFOLYAMFORM: TARFOLYAMFORM
  Left = 237
  Top = 111
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'ARFOLYAMFORM'
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
      Left = 168
      Top = 64
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
    object Label2: TLabel
      Left = 352
      Top = 120
      Width = 312
      Height = 21
      Caption = 'P'#201'NZT'#193'RSZ'#193'MA '#201'S MEGNEVEZ'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
    end
    object ARFOLYAMRACS: TDBGrid
      Left = 136
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
    object GOMBTAKAROPANEL: TPanel
      Left = 24
      Top = 736
      Width = 921
      Height = 41
      BevelOuter = bvNone
      Color = 4539717
      TabOrder = 2
    end
    object PTARCOMBO: TComboBox
      Left = 136
      Top = 144
      Width = 761
      Height = 31
      DropDownCount = 25
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 3
      OnChange = PTARCOMBOChange
    end
  end
  object ARFOLYAMSOURCE: TDataSource
    DataSet = ARFOLYAMQUERY
    Left = 24
    Top = 352
  end
  object ETARDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ETARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object ETARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ETARDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
  object ETARQUERY: TIBQuery
    Database = ETARDBASE
    Transaction = ETARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 16
    Top = 16
  end
  object SERVERQUERY: TIBQuery
    Database = SERVERDBASE
    Transaction = SERVERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 890
    Top = 18
  end
  object SERVERDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SERVERTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 930
    Top = 18
  end
  object SERVERTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SERVERDBASE
    AutoStopAction = saNone
    Left = 970
    Top = 18
  end
  object ARFOLYAMQUERY: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM ARFOLYAM')
    Left = 18
    Top = 74
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
    object ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TIntegerField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'ARFOLYAM.ELSZAMOLASIARFOLYAM'
      DisplayFormat = '###,##'
    end
    object ARFOLYAMQUERYVETELIARFOLYAM: TIntegerField
      FieldName = 'VETELIARFOLYAM'
      Origin = 'ARFOLYAM.VETELIARFOLYAM'
      DisplayFormat = '###,##'
    end
    object ARFOLYAMQUERYELADASIARFOLYAM: TIntegerField
      FieldName = 'ELADASIARFOLYAM'
      Origin = 'ARFOLYAM.ELADASIARFOLYAM'
      DisplayFormat = '###,##'
    end
  end
  object ARFOLYAMDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 50
    Top = 74
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = ARFOLYAMDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 82
    Top = 74
  end
end
