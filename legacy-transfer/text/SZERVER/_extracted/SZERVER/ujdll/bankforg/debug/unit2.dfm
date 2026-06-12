object BANKFORGALOMDISPLAY: TBANKFORGALOMDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'BANKFORGALOMDISPLAY'
  ClientHeight = 613
  ClientWidth = 870
  Color = 4557247
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
    Brush.Color = 4557247
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 176
    Top = 32
    Width = 486
    Height = 42
    Caption = 'ID'#214'SZAKI BANKI FORGALOM'
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -35
    Font.Name = 'Stencil'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object QUITGOMB: TBitBtn
    Left = 640
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'SZERVER MEN'#220'RE'
    TabOrder = 0
    OnClick = QUITGOMBClick
  end
  object idoszakpanel: TPanel
    Left = 136
    Top = 80
    Width = 577
    Height = 33
    BevelOuter = bvNone
    Caption = '2009 SZEPTEMBER 25 - 30'
    Color = 3443135
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object BANKRACS: TDBGrid
    Left = 104
    Top = 128
    Width = 657
    Height = 417
    Color = clYellow
    DataSource = bankforgsource
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -19
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Color = clMoneyGreen
        Title.Font.Charset = ANSI_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -19
        Title.Font.Name = 'Cooper Black'
        Title.Font.Style = [fsItalic]
        Width = 225
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'FELVETTKP'
        Title.Alignment = taCenter
        Title.Caption = 'FELVETT-KP'
        Title.Color = clMoneyGreen
        Title.Font.Charset = ANSI_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -19
        Title.Font.Name = 'Cooper Black'
        Title.Font.Style = [fsItalic]
        Width = 197
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'BEFIZETETTKP'
        Title.Alignment = taCenter
        Title.Caption = 'BEFIZETETT-KP'
        Title.Color = clMoneyGreen
        Title.Font.Charset = ANSI_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -19
        Title.Font.Name = 'Cooper Black'
        Title.Font.Style = [fsItalic]
        Width = 209
        Visible = True
      end>
  end
  object MASADATOKGOMB: TBitBtn
    Left = 40
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    TabOrder = 3
    OnClick = MASADATOKGOMBClick
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 240
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S EGYS'#201'G'
    TabOrder = 4
    OnClick = MASEGYSEGGOMBClick
  end
  object MASIKIDOSZAKGOMB: TBitBtn
    Left = 440
    Top = 568
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ID'#336'SZAK'
    TabOrder = 5
    OnClick = MASIKIDOSZAKGOMBClick
  end
  object PARADBASE: TIBDatabase
    Connected = True
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PARATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 304
    Top = 192
  end
  object PARATRANZ: TIBTransaction
    Active = True
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 336
    Top = 192
  end
  object bankforgsource: TDataSource
    DataSet = BANKQUERY
    Left = 272
    Top = 192
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 368
    Top = 192
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 112
    Top = 192
  end
  object BANKQUERY: TIBQuery
    Database = BANKDBASE
    Transaction = BANKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 448
    Top = 192
    object BANKQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'SUMBANKFORGALOM.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object BANKQUERYFELVETTKP: TFloatField
      FieldName = 'FELVETTKP'
      Origin = 'SUMBANKFORGALOM.FELVETTKP'
      DisplayFormat = '### ### ###'
    end
    object BANKQUERYBEFIZETETTKP: TFloatField
      FieldName = 'BEFIZETETTKP'
      Origin = 'SUMBANKFORGALOM.BEFIZETETTKP'
      DisplayFormat = '### ### ###'
    end
    object BANKQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'SUMBANKFORGALOM.CEGBETU'
      FixedChar = True
      Size = 1
    end
  end
  object BANKDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BANKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 480
    Top = 192
  end
  object BANKTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = BANKDBASE
    AutoStopAction = saNone
    Left = 512
    Top = 192
  end
end
