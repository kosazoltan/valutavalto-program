object TRBDISPLAY: TTRBDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'TRBDISPLAY'
  ClientHeight = 530
  ClientWidth = 750
  Color = 16311512
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
    Width = 750
    Height = 530
    Brush.Color = 16311512
    Pen.Color = clGradientActiveCaption
    Pen.Width = 8
  end
  object Label1: TLabel
    Left = 88
    Top = 32
    Width = 589
    Height = 43
    Caption = 'A TRB TRANZAKCI'#211'K KIJELZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 88
    Top = 120
    Width = 593
    Height = 345
    Brush.Color = 11599871
    Pen.Width = 3
    Shape = stRoundRect
  end
  object BitBtn1: TBitBtn
    Left = 600
    Top = 480
    Width = 115
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object TRBRACS: TDBGrid
    Left = 120
    Top = 128
    Width = 529
    Height = 329
    BorderStyle = bsNone
    Color = 11599871
    DataSource = TRBSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Title.Alignment = taCenter
        Title.Caption = 'Valuta'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KULDO'
        Title.Alignment = taCenter
        Title.Caption = 'K'#252'ld'#246
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KULDOTT'
        Title.Alignment = taCenter
        Title.Caption = 'K'#252'ld'#246'tt'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FOGADO'
        Title.Alignment = taCenter
        Title.Caption = 'Fogad'#243
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FOGADOTT'
        Title.Alignment = taCenter
        Title.Caption = 'Fogadott'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'STATUS'
        Title.Alignment = taCenter
        Title.Caption = 'OK'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clNavy
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end>
  end
  object IDOSZAKPANEL: TPanel
    Left = 40
    Top = 80
    Width = 673
    Height = 33
    BevelOuter = bvNone
    Caption = 'FFFFFFFFFFFFF'
    Color = 16311512
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object TRBTABLA: TIBTable
    Database = trbdbase
    Transaction = TRBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'KULDO'
        DataType = ftInteger
      end
      item
        Name = 'FOGADO'
        DataType = ftInteger
      end
      item
        Name = 'KULDOTT'
        DataType = ftFloat
      end
      item
        Name = 'FOGADOTT'
        DataType = ftFloat
      end
      item
        Name = 'STATUS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 2
      end>
    IndexDefs = <
      item
        Name = 'IDX_TRBGYUJTO'
        Fields = 'VALUTANEM;KULDO;FOGADO'
      end>
    StoreDefs = True
    TableName = 'TRBGYUJTO'
    Left = 112
    Top = 336
    object TRBTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object TRBTABLAKULDO: TIntegerField
      Alignment = taCenter
      FieldName = 'KULDO'
    end
    object TRBTABLAFOGADO: TIntegerField
      Alignment = taCenter
      FieldName = 'FOGADO'
    end
    object TRBTABLAKULDOTT: TFloatField
      FieldName = 'KULDOTT'
      DisplayFormat = '###,###,###'
    end
    object TRBTABLAFOGADOTT: TFloatField
      FieldName = 'FOGADOTT'
      DisplayFormat = '###,###,###'
    end
    object TRBTABLASTATUS: TIBStringField
      FieldName = 'STATUS'
      FixedChar = True
      Size = 2
    end
  end
  object trbdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 144
    Top = 336
  end
  object TRBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = trbdbase
    AutoStopAction = saNone
    Left = 176
    Top = 336
  end
  object TRBSOURCE: TDataSource
    DataSet = TRBTABLA
    Left = 216
    Top = 336
  end
end
