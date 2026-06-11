object XTRANZFORM: TXTRANZFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'XTRANZFORM'
  ClientHeight = 334
  ClientWidth = 660
  Color = 4473924
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
    Left = 344
    Top = 32
    Width = 253
    Height = 24
    Caption = 'EGYEDI KEZEL'#201'SI D'#205'JAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KILEPOGOMB: TButton
    Left = 16
    Top = 280
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = KILEPOGOMBClick
  end
  object EVCOMBO: TComboBox
    Left = 16
    Top = 8
    Width = 73
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 1
    Text = '2013'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 96
    Top = 8
    Width = 169
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 2
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object XKEZDIJRACS: TDBGrid
    Left = 16
    Top = 80
    Width = 633
    Height = 185
    Color = 11184810
    DataSource = xksource
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 3
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnKeyUp = XKEZDIJRACSKeyUp
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Color = 7829367
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsItalic]
        Width = 140
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BIZONYLAT'
        Title.Alignment = taCenter
        Title.Color = 7829367
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsItalic]
        Width = 143
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BIZONYLATFORINT'
        Title.Alignment = taCenter
        Title.Caption = 'FORINT '#214'SSZEG'
        Title.Color = 7829367
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsItalic]
        Width = 153
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EGYEDIKEZDIJ'
        Title.Alignment = taCenter
        Title.Caption = 'EGYEDI KEZ-D'#205'J'
        Title.Color = 7829367
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsItalic]
        Width = 151
        Visible = True
      end>
  end
  object TIPUSPANEL: TPanel
    Left = 256
    Top = 280
    Width = 393
    Height = 33
    BevelOuter = bvNone
    Color = 4473924
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object HONAPRENDBENGOMB: TBitBtn
    Left = 16
    Top = 48
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'H'#211'NAP RENDBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = HONAPRENDBENGOMBClick
  end
  object BitBtn1: TBitBtn
    Left = 128
    Top = 280
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'NYOMTAT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 6
    OnClick = BitBtn1Click
  end
  object XKTABLA: TIBTable
    Database = XKDBASE
    Transaction = XKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'XKEZ1310'
    Left = 328
    Top = 144
    object XKTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
    object XKTABLABIZONYLAT: TIBStringField
      DisplayWidth = 10
      FieldName = 'BIZONYLAT'
      Size = 10
    end
    object XKTABLABIZONYLATFORINT: TIntegerField
      FieldName = 'BIZONYLATFORINT'
      DisplayFormat = '### ### ###'
    end
    object XKTABLAEGYEDIKEZDIJ: TIntegerField
      FieldName = 'EGYEDIKEZDIJ'
      DisplayFormat = '### ### ###'
    end
    object XKTABLATIPUS: TIBStringField
      FieldName = 'TIPUS'
      Size = 1
    end
  end
  object XKDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = XKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 360
    Top = 144
  end
  object XKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = XKDBASE
    AutoStopAction = saNone
    Left = 392
    Top = 144
  end
  object xksource: TDataSource
    DataSet = XKTABLA
    Left = 296
    Top = 144
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 144
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 144
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 96
    Top = 144
  end
end
