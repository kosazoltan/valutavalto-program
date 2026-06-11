object ARCHIVEFORM: TARCHIVEFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'ARCHIVEFORM'
  ClientHeight = 357
  ClientWidth = 833
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ARCBACKGOMB: TButton
    Left = 624
    Top = 320
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = ARCBACKGOMBClick
  end
  object ARCREADGOMB: TBitBtn
    Left = 8
    Top = 320
    Width = 225
    Height = 25
    Cursor = crHandPoint
    Caption = 'LEV'#201'L OLVAS'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = ARCREADGOMBClick
  end
  object ARCRACS: TDBGrid
    Left = 8
    Top = 40
    Width = 817
    Height = 273
    Cursor = crHandPoint
    DataSource = ARCSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = ARCRACSDblClick
    OnKeyUp = ARCRACSKeyUp
    Columns = <
      item
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IKTATOSZAM'
        ReadOnly = True
        Title.Alignment = taCenter
        Title.Caption = 'IKTAT'#211'SZ'#193'M'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TARTALOM'
        ReadOnly = True
        Title.Alignment = taCenter
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsItalic]
        Visible = True
      end>
  end
  object INFOCSIK: TPanel
    Left = 224
    Top = 160
    Width = 337
    Height = 41
    Caption = 'Bet'#246'lt'#246'm a k'#246'rlevelet ...'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object FOCIMPANEL: TPanel
    Left = 144
    Top = 2
    Width = 545
    Height = 36
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object ARCQUERY: TIBQuery
    Database = ARCDBASE
    Transaction = ARCTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 8
    Top = 8
    object ARCQUERYDATUM: TIBStringField
      FieldName = 'DATUM'
      Origin = 'KORL2015.DATUM'
      FixedChar = True
      Size = 10
    end
    object ARCQUERYIKTATOSZAM: TIBStringField
      FieldName = 'IKTATOSZAM'
      Origin = 'KORL2015.IKTATOSZAM'
      FixedChar = True
      Size = 10
    end
    object ARCQUERYSORREND: TSmallintField
      FieldName = 'SORREND'
      Origin = 'KORL2015.SORREND'
    end
    object ARCQUERYSORSZAM: TSmallintField
      FieldName = 'SORSZAM'
      Origin = 'KORL2015.SORSZAM'
    end
    object ARCQUERYFILENEV: TIBStringField
      FieldName = 'FILENEV'
      Origin = 'KORL2015.FILENEV'
      FixedChar = True
      Size = 15
    end
    object ARCQUERYTARTALOM: TIBStringField
      FieldName = 'TARTALOM'
      Origin = 'KORL2015.TARTALOM'
      FixedChar = True
      Size = 80
    end
    object ARCQUERYSTORNO: TSmallintField
      FieldName = 'STORNO'
      Origin = 'KORL2015.STORNO'
    end
    object ARCQUERYSORTEMP: TSmallintField
      FieldName = 'SORTEMP'
      Origin = 'KORL2015.SORTEMP'
    end
  end
  object ARCDBASE: TIBDatabase
    DatabaseName = ':'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARCTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object ARCTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARCDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object ARCSOURCE: TDataSource
    DataSet = ARCQUERY
    Left = 104
    Top = 8
  end
end
