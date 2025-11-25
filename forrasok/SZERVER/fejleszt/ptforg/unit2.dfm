object EREDMENYFORM: TEREDMENYFORM
  Left = 198
  Top = 114
  BorderStyle = bsNone
  Caption = 'EREDMENYFORM'
  ClientHeight = 614
  ClientWidth = 856
  Color = 8947848
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 856
    Height = 614
    Align = alClient
    Brush.Color = 8947848
    Pen.Color = clRed
    Pen.Width = 5
  end
  object VISSZAGOMB: TBitBtn
    Left = 584
    Top = 568
    Width = 241
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = VISSZAGOMBClick
  end
  object EREDMENYRACS: TDBGrid
    Left = 48
    Top = 128
    Width = 777
    Height = 417
    Cursor = crHandPoint
    DataSource = EREDMENYSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = EREDMENYRACSDblClick
    OnKeyDown = EREDMENYRACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'KULDO'
        Title.Alignment = taCenter
        Title.Caption = 'K'#220'LD'#336
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 71
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'FOGADO'
        Title.Alignment = taCenter
        Title.Caption = 'FOGAD'#211
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 88
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KULDOTTBANKJEGY'
        Title.Alignment = taCenter
        Title.Caption = 'K'#220'LDVE'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 120
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FOGADOTTBANKJEGY'
        Title.Alignment = taCenter
        Title.Caption = 'FOGADVA'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 135
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Title.Alignment = taCenter
        Title.Caption = 'VALNEM'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 81
        Visible = True
      end
      item
        Color = 13697023
        Expanded = False
        FieldName = 'DIFFRENT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'ELT'#201'R'#201'S'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 131
        Visible = True
      end
      item
        Alignment = taCenter
        Color = 16765183
        Expanded = False
        FieldName = 'DATUM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Color = clYellow
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -19
        Title.Font.Name = 'Arial'
        Title.Font.Style = []
        Width = 122
        Visible = True
      end>
  end
  object infopanel: TPanel
    Left = 56
    Top = 56
    Width = 777
    Height = 33
    BevelOuter = bvNone
    Caption = '(A kiv'#225'lasztott sorra dupla-klikk vagy Enter)'
    Color = 8947848
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object FELLABGOMB: TBitBtn
    Left = 318
    Top = 568
    Width = 241
    Height = 25
    Cursor = crHandPoint
    Caption = 'F'#201'LL'#193'BAS TRANZAKCI'#211' KIJELZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = FELLABGOMBClick
  end
  object OSSZESGOMB: TBitBtn
    Left = 48
    Top = 568
    Width = 241
    Height = 25
    Cursor = crHandPoint
    Caption = 'AZ '#214'SSZES TRANZAKCI'#211' KIJELZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = OSSZESGOMBClick
  end
  object FOCIMPANEL: TPanel
    Left = 16
    Top = 16
    Width = 833
    Height = 41
    BevelOuter = bvNone
    Caption = 'F'#201'LL'#193'BAS TRANZAKCI'#211'K KIMUTAT'#193'SA'
    Color = 8947848
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object EREDMENYQUERY: TIBQuery
    Database = EREDMENYDBASE
    Transaction = EREDMENYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object EREDMENYTABLA: TIBTable
    Database = EREDMENYDBASE
    Transaction = EREDMENYTRANZ
    Active = True
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'KULDO'
        DataType = ftSmallint
      end
      item
        Name = 'FOGADO'
        DataType = ftSmallint
      end
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'KULDOTTBANKJEGY'
        DataType = ftInteger
      end
      item
        Name = 'FOGADOTTBANKJEGY'
        DataType = ftInteger
      end
      item
        Name = 'DIFFRENT'
        DataType = ftInteger
      end
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end>
    Filter = 'diffrent<>0'
    Filtered = True
    IndexDefs = <
      item
        Name = 'IDX_COMPARE'
        Fields = 'KULDO;VALUTANEM'
      end
      item
        Name = 'IDX_COMPARE1'
        Fields = 'FOGADO;VALUTANEM'
      end
      item
        Name = 'ALTXCOMPARE'
        Fields = 'DIFFRENT'
      end>
    IndexFieldNames = 'KULDO;VALUTANEM'
    StoreDefs = True
    TableName = 'COMPARE'
    Left = 8
    Top = 8
    object EREDMENYTABLAKULDO: TSmallintField
      FieldName = 'KULDO'
    end
    object EREDMENYTABLAFOGADO: TSmallintField
      FieldName = 'FOGADO'
    end
    object EREDMENYTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object EREDMENYTABLAKULDOTTBANKJEGY: TIntegerField
      FieldName = 'KULDOTTBANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object EREDMENYTABLAFOGADOTTBANKJEGY: TIntegerField
      FieldName = 'FOGADOTTBANKJEGY'
      DisplayFormat = '### ### ###'
    end
    object EREDMENYTABLADIFFRENT: TIntegerField
      FieldName = 'DIFFRENT'
      DisplayFormat = '### ### ###'
    end
    object EREDMENYTABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
  end
  object EREDMENYDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\ptforg.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = EREDMENYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object EREDMENYTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = EREDMENYDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object EREDMENYSOURCE: TDataSource
    DataSet = EREDMENYTABLA
    Left = 136
    Top = 8
  end
end
