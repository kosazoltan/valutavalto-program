object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 770
  ClientWidth = 1030
  Color = clBtnFace
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
    Width = 1030
    Height = 770
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Panel1: TPanel
    Left = 4
    Top = 4
    Width = 1020
    Height = 760
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 328
      Top = 24
      Width = 360
      Height = 43
      Caption = #220'gyfelek karbantart'#225'sa'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape1: TShape
      Left = 264
      Top = 88
      Width = 489
      Height = 41
      Shape = stRoundRect
    end
    object NATURPANEL: TPanel
      Left = -2200
      Top = 136
      Width = 993
      Height = 609
      BevelOuter = bvNone
      TabOrder = 0
      Visible = False
      object Label2: TLabel
        Left = 312
        Top = 16
        Width = 380
        Height = 31
        Caption = 'Term'#233'szetes szem'#233'lyek adatb'#225'zisa'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object NATURRACS: TDBGrid
        Left = 24
        Top = 64
        Width = 945
        Height = 489
        DataSource = NATURFORRAS
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'NEV'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Width = 229
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ANYJANEVE'
            Title.Alignment = taCenter
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'SZULETESIHELY'
            Title.Alignment = taCenter
            Title.Caption = 'SZ'#220'L HELYE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'SZULETESIIDO'
            Title.Caption = 'SZ'#220'L IDEJE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clBlack
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'IRSZAM'
            Title.Alignment = taCenter
            Title.Caption = 'IR SZ'#193'M'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VAROS'
            Title.Alignment = taCenter
            Title.Caption = 'V'#193'ROS'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'UTCA'
            Title.Alignment = taCenter
            Title.Caption = 'UTCA- H'#193'ZSZ'#193'M'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'LAKCIM'
            Title.Alignment = taCenter
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'LAKCIMKARTYA'
            Title.Alignment = taCenter
            Title.Caption = 'LC CARD'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TARTOZKODASIHELY'
            Title.Alignment = taCenter
            Title.Caption = 'TART HELY'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'OKMANYTIPUS'
            Title.Alignment = taCenter
            Title.Caption = 'OKMTIP'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'AZONOSITO'
            Title.Alignment = taCenter
            Title.Caption = 'AZONOSIT'#211
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'ELOZONEV'
            Title.Alignment = taCenter
            Title.Caption = 'EL'#214'Z'#214' NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'LEANYKORI'
            Title.Alignment = taCenter
            Title.Caption = 'LE'#193'NYKORI'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'KULFOLDI'
            Title.Alignment = taCenter
            Title.Caption = 'K'#220'LF'#214'LDI'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'TOROLVE'
            Title.Alignment = taCenter
            Title.Caption = 'T'#214'R'#214'LVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'UGYFELSZAM'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L SZ'#193'MA'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end>
      end
      object DELETEGOMB: TBitBtn
        Left = 104
        Top = 568
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = #220'GYF'#201'L T'#214'RL'#201'SE'
        TabOrder = 1
        OnClick = DELETEGOMBClick
      end
      object RETURNGOMB: TBitBtn
        Left = 744
        Top = 568
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Cancel = True
        Caption = 'VISSZA A MEN'#220'RE'
        TabOrder = 2
        OnClick = RETURNGOMBClick
      end
    end
    object NATURGOMB: TBitBtn
      Left = 272
      Top = 96
      Width = 235
      Height = 25
      Cursor = crHandPoint
      Caption = 'TERM'#201'SZETES SZEM'#201'LYEK'
      TabOrder = 1
      OnClick = NATURGOMBClick
    end
    object JOGIGOMB: TBitBtn
      Left = 512
      Top = 96
      Width = 233
      Height = 25
      Cursor = crHandPoint
      Caption = 'JOGISZEM'#201'LYEK'
      TabOrder = 2
      OnClick = JOGIGOMBClick
    end
    object JOGIPANEL: TPanel
      Left = -2500
      Top = 136
      Width = 993
      Height = 609
      BevelOuter = bvNone
      TabOrder = 3
      Visible = False
      object Label3: TLabel
        Left = 352
        Top = 16
        Width = 296
        Height = 31
        Caption = 'Jogi szem'#233'lyek adatb'#225'zisa'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -27
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object JOGIRACS: TDBGrid
        Left = 24
        Top = 64
        Width = 945
        Height = 489
        DataSource = JOGIFORRAS
        Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'MS Sans Serif'
        TitleFont.Style = []
        Columns = <
          item
            Expanded = False
            FieldName = 'JOGISZEMELYNEV'
            Title.Alignment = taCenter
            Title.Caption = 'JOGI SZEM'#201'LY NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TELEPHELYCIM'
            Title.Alignment = taCenter
            Title.Caption = 'TELEPHELY CIME'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FOTEVEKENYSEG'
            Title.Alignment = taCenter
            Title.Caption = 'F'#336' TEV'#201'KENYS'#201'GE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'OKIRATSZAM'
            Title.Alignment = taCenter
            Title.Caption = 'OKIRAT SZ'#193'MA'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'ADOSZAM'
            Title.Alignment = taCenter
            Title.Caption = 'AD'#211'SZ'#193'MA'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'MEGBIZOTTNEVE'
            Title.Alignment = taCenter
            Title.Caption = 'MB. NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'MEGBIZOTTBEOSZTASA'
            Title.Alignment = taCenter
            Title.Caption = 'MB BEOSZT'#193'SA'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'KEPVISELONEV'
            Title.Alignment = taCenter
            Title.Caption = 'K'#201'PVIS NEVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'KEPVISBEO'
            Title.Alignment = taCenter
            Title.Caption = 'K'#201'PVIS BEO'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'TOROLVE'
            Title.Alignment = taCenter
            Title.Caption = 'T'#214'R'#214'LVE'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end
          item
            Alignment = taCenter
            Expanded = False
            FieldName = 'UGYFELSZAM'
            Title.Alignment = taCenter
            Title.Caption = #220'GYF'#201'L SZ'#193'MA'
            Title.Font.Charset = EASTEUROPE_CHARSET
            Title.Font.Color = clWindowText
            Title.Font.Height = -15
            Title.Font.Name = 'Arial'
            Title.Font.Style = [fsBold]
            Visible = True
          end>
      end
      object JOGITORLOGOMB: TBitBtn
        Left = 40
        Top = 568
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Caption = 'JOGI SZEM'#201'LY T'#214'RL'#201'SE'
        TabOrder = 1
        OnClick = JOGITORLOGOMBClick
      end
      object backgomb: TBitBtn
        Left = 744
        Top = 568
        Width = 201
        Height = 25
        Cursor = crHandPoint
        Cancel = True
        Caption = 'VISSZA A MEN'#220'RE'
        TabOrder = 2
        OnClick = RETURNGOMBClick
      end
    end
  end
  object NATURQUERY: TIBQuery
    Database = NATURDBASE
    Transaction = NATURTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 800
    Top = 24
  end
  object NATURDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NATURTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 832
    Top = 24
  end
  object NATURTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NATURDBASE
    AutoStopAction = saNone
    Left = 864
    Top = 24
  end
  object NATURFORRAS: TDataSource
    DataSet = NATURTABLA
    Left = 800
    Top = 64
  end
  object JOGIQUERY: TIBQuery
    Database = JOGIDBASE
    Transaction = JOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM JOGISZEMELY')
    Left = 24
    Top = 48
  end
  object JOGIDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JOGITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 48
  end
  object JOGITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JOGIDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 48
  end
  object JOGIFORRAS: TDataSource
    DataSet = JOGITABLA
    Left = 120
    Top = 48
  end
  object JOGITABLA: TIBTable
    Database = JOGIDBASE
    Transaction = JOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'JOGISZEMELYNEV'
    TableName = 'JOGISZEMELY'
    Left = 160
    Top = 48
  end
  object NATURTABLA: TIBTable
    Database = NATURDBASE
    Transaction = NATURTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'NEV'
    TableName = 'UGYFEL'
    Left = 904
    Top = 24
  end
end
