object TRBDISPLAY: TTRBDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'TRBDISPLAY'
  ClientHeight = 613
  ClientWidth = 870
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
    Width = 870
    Height = 613
    Align = alClient
    Brush.Color = clSkyBlue
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 88
    Top = 32
    Width = 665
    Height = 42
    Caption = 'A TRB TRANZAKCI'#211'K KIJELZ'#201'SE'
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -37
    Font.Name = 'Cooper Black'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 72
    Top = 120
    Width = 713
    Height = 433
    Brush.Color = 11599871
    Pen.Width = 3
  end
  object QUITGOMB: TBitBtn
    Left = 624
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'SZERVER MEN'#218'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = QUITGOMBClick
  end
  object TRBRACS: TDBGrid
    Left = 80
    Top = 128
    Width = 689
    Height = 417
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
        Width = 86
        Visible = True
      end
      item
        Alignment = taCenter
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
        Width = 140
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
        Width = 138
        Visible = True
      end
      item
        Alignment = taCenter
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
        Width = 129
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
        Width = 113
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
        Width = 58
        Visible = True
      end>
  end
  object IDOSZAKPANEL: TPanel
    Left = 40
    Top = 80
    Width = 769
    Height = 33
    BevelOuter = bvNone
    Color = 16311512
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object MASADATGOMB: TBitBtn
    Left = 24
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = MASADATGOMBClick
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 224
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S EGYS'#201'G'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = MASEGYSEGGOMBClick
  end
  object MASIDOSZAKGOMB: TBitBtn
    Left = 424
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'SIK ID'#336'SZAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = MASIDOSZAKGOMBClick
  end
  object trbdbase: TIBDatabase
    Connected = True
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
    Active = True
    DefaultDatabase = trbdbase
    AutoStopAction = saNone
    Left = 176
    Top = 336
  end
  object TRBSOURCE: TDataSource
    DataSet = TRBQUERY
    Left = 216
    Top = 336
  end
  object TRBQUERY: TIBQuery
    Database = trbdbase
    Transaction = TRBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM TRBGYUJTO')
    Left = 144
    Top = 304
    object TRBQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'TRBGYUJTO.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object TRBQUERYKULDO: TIntegerField
      FieldName = 'KULDO'
      Origin = 'TRBGYUJTO.KULDO'
    end
    object TRBQUERYFOGADO: TIntegerField
      FieldName = 'FOGADO'
      Origin = 'TRBGYUJTO.FOGADO'
    end
    object TRBQUERYKULDOTT: TFloatField
      FieldName = 'KULDOTT'
      Origin = 'TRBGYUJTO.KULDOTT'
      DisplayFormat = '### ### ###'
    end
    object TRBQUERYFOGADOTT: TFloatField
      FieldName = 'FOGADOTT'
      Origin = 'TRBGYUJTO.FOGADOTT'
      DisplayFormat = '### ### ###'
    end
    object TRBQUERYSTATUS: TIBStringField
      FieldName = 'STATUS'
      Origin = 'TRBGYUJTO.STATUS'
      FixedChar = True
      Size = 2
    end
    object TRBQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'TRBGYUJTO.CEGBETU'
      FixedChar = True
      Size = 1
    end
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 560
    Top = 224
  end
  object PARADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PARATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 592
    Top = 224
  end
  object PARATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 624
    Top = 224
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 88
    Top = 200
  end
  object TRBTABLA: TIBTable
    Database = trbdbase
    Transaction = TRBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 304
  end
end
