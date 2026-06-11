object MAIFORGALOMTABLAFORM: TMAIFORGALOMTABLAFORM
  Left = 188
  Top = 112
  AlphaBlendValue = 225
  BorderIcons = []
  BorderStyle = bsSingle
  BorderWidth = 1
  Caption = 'MAIFORGALOMTABLAFORM'
  ClientHeight = 702
  ClientWidth = 1022
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ESCAPEGOMB: TBitBtn
    Left = 824
    Top = 656
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = ESCAPEGOMBClick
  end
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 1001
    Height = 57
    Caption = 'A MAI NAPI FORGALOM '#214'SSZESIT'#201'SE'
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object Panel2: TPanel
    Left = 208
    Top = 72
    Width = 385
    Height = 49
    Caption = 'V'#193'S'#193'RL'#193'SOK'
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object Panel3: TPanel
    Left = 600
    Top = 72
    Width = 409
    Height = 49
    Caption = 'ELAD'#193'SOK'
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object Panel4: TPanel
    Left = 208
    Top = 128
    Width = 185
    Height = 41
    Caption = 'VALUTA'
    Color = clScrollBar
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel5: TPanel
    Left = 400
    Top = 128
    Width = 193
    Height = 41
    Caption = 'FORINT'
    Color = clScrollBar
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object Panel6: TPanel
    Left = 800
    Top = 128
    Width = 209
    Height = 41
    Caption = 'FORINT'
    Color = clScrollBar
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object Panel7: TPanel
    Left = 600
    Top = 128
    Width = 193
    Height = 41
    Caption = 'VALUTA'
    Color = clScrollBar
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object Panel8: TPanel
    Left = 8
    Top = 72
    Width = 193
    Height = 97
    Caption = 'VALUTANEM'
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
  end
  object SVFORINTPANEL: TPanel
    Left = 208
    Top = 552
    Width = 385
    Height = 41
    Caption = '123.456.789 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 9
  end
  object Panel10: TPanel
    Left = 8
    Top = 552
    Width = 185
    Height = 41
    Caption = 'FT '#214'SSZESEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 10
  end
  object SEFORINTPANEL: TPanel
    Left = 608
    Top = 552
    Width = 401
    Height = 41
    Caption = '123.456.789 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 11
  end
  object Panel12: TPanel
    Left = 8
    Top = 600
    Width = 185
    Height = 41
    Caption = 'MIND'#214'SSZESEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 12
  end
  object MINDOSSZPANEL: TPanel
    Left = 208
    Top = 600
    Width = 801
    Height = 41
    Caption = '123.456.789 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 13
  end
  object FORGALOMRACS: TDBGrid
    Left = 8
    Top = 168
    Width = 1001
    Height = 377
    DataSource = NAPIZARSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 14
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEV'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        Title.Alignment = taCenter
        Title.Caption = '***'
        Title.Color = clSilver
        Width = 201
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETEL'
        Title.Alignment = taCenter
        Title.Caption = '***'
        Title.Color = clSilver
        Width = 192
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETELFORINT'
        Title.Alignment = taCenter
        Title.Caption = '***'
        Title.Color = clSilver
        Width = 197
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADAS'
        Title.Alignment = taCenter
        Title.Caption = '***'
        Title.Color = clSilver
        Width = 200
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADASFORINT'
        Title.Alignment = taCenter
        Title.Caption = '***'
        Title.Color = clSilver
        Width = 206
        Visible = True
      end>
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'BLOKKFEJ'
    Left = 8
    Top = 16
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 16
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 128
    Top = 16
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'BIZONYLATSZAM'
    TableName = 'BLOKKTETEL'
    Left = 864
    Top = 24
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
    Left = 936
    Top = 24
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 968
    Top = 24
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 904
    Top = 24
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object NAPIZARSOURCE: TDataSource
    DataSet = NAPIZARQUERY
    Enabled = False
    Left = 16
    Top = 504
  end
  object NAPIZARQUERY: TIBQuery
    Database = NAPIZARDBASE
    Transaction = NAPIZARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM NAPIZAR')
    Left = 24
    Top = 656
    object NAPIZARQUERYVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
      Origin = 'NAPIZAR.VALUTANEV'
      FixedChar = True
    end
    object NAPIZARQUERYVETEL: TIntegerField
      FieldName = 'VETEL'
      Origin = 'NAPIZAR.VETEL'
      DisplayFormat = '### ### ###'
    end
    object NAPIZARQUERYELADAS: TIntegerField
      FieldName = 'ELADAS'
      Origin = 'NAPIZAR.ELADAS'
      DisplayFormat = '### ### ###'
    end
    object NAPIZARQUERYVETELFORINT: TIntegerField
      FieldName = 'VETELFORINT'
      Origin = 'NAPIZAR.VETELFORINT'
      DisplayFormat = '### ### ###'
    end
    object NAPIZARQUERYELADASFORINT: TIntegerField
      FieldName = 'ELADASFORINT'
      Origin = 'NAPIZAR.ELADASFORINT'
      DisplayFormat = '### ### ###'
    end
  end
  object NAPIZARDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NAPIZARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 656
  end
  object NAPIZARTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = NAPIZARDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 656
  end
end
