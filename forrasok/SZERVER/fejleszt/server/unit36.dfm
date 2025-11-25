object ATLAGDISPLAY: TATLAGDISPLAY
  Left = 199
  Top = 114
  BorderStyle = bsNone
  Caption = 'ATLAGDISPLAY'
  ClientHeight = 446
  ClientWidth = 742
  Color = 8421631
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object IDOSZAKPANEL: TPanel
    Left = 8
    Top = 8
    Width = 721
    Height = 41
    Caption = #193'TLAG'#193'RFOLYAMOK 2001.11.11 - 2002.12.12 K'#214'Z'#214'TT'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 8
    Top = 56
    Width = 225
    Height = 353
    TabOrder = 1
    object VALUTALISTA: TListBox
      Left = 8
      Top = 48
      Width = 209
      Height = 297
      Cursor = crHandPoint
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ItemHeight = 16
      ParentFont = False
      TabOrder = 0
      OnClick = VALUTALISTAClick
      OnDblClick = VALUTALISTADblClick
      OnEnter = VALUTALISTAEnter
      OnExit = VALUTALISTAExit
      OnKeyUp = VALUTALISTAKeyUp
      OnMouseMove = VALUTALISTAMouseMove
    end
    object Panel5: TPanel
      Left = 8
      Top = 8
      Width = 209
      Height = 33
      Caption = 'VALUT'#193'K'
      Color = 2720
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object Panel3: TPanel
    Left = 240
    Top = 56
    Width = 489
    Height = 353
    TabOrder = 2
    object VALUTAPANEL: TPanel
      Left = 8
      Top = 8
      Width = 473
      Height = 33
      Caption = 'AUSZTR'#193'L DOLL'#193'R'
      Color = 170
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object MARGERACS: TDBGrid
      Left = 8
      Top = 48
      Width = 473
      Height = 297
      Cursor = crHandPoint
      DataSource = MARGESOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnEnter = MARGERACSEnter
      OnExit = MARGERACSExit
      OnMouseMove = MARGERACSMouseMove
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'MEGNEVEZES'
          Title.Alignment = taCenter
          Title.Caption = 'EGYS'#201'G MEGNEVEZ'#201'SE'
          Title.Color = clRed
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VETELATLAG'
          Title.Alignment = taCenter
          Title.Caption = 'V'#201'TEL '#193'TLAG'
          Title.Color = clRed
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELADATLAG'
          Title.Alignment = taCenter
          Title.Caption = 'ELAD '#193'TLAG'
          Title.Color = clRed
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'MARGE'
          Title.Alignment = taCenter
          Title.Color = clRed
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
  end
  object BitBtn1: TBitBtn
    Left = 632
    Top = 416
    Width = 99
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = BitBtn1Click
  end
  object EXCELGOMB: TBitBtn
    Left = 8
    Top = 416
    Width = 225
    Height = 25
    Cursor = crHandPoint
    Caption = 'EXCEL-T'#193'BLA AZ ASZTALRA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = EXCELGOMBClick
  end
  object ATLAGDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ATLAGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 304
    Top = 360
  end
  object ATLAGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ATLAGDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 360
  end
  object MARGESOURCE: TDataSource
    DataSet = ATLAGQUERY
    Left = 376
    Top = 360
  end
  object ATLAGQUERY: TIBQuery
    Database = ATLAGDBASE
    Transaction = ATLAGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM ATLAGARFOLYAM')
    Left = 424
    Top = 360
    object ATLAGQUERYIRODA: TSmallintField
      FieldName = 'IRODA'
      Origin = 'ATLAGARFOLYAM.IRODA'
    end
    object ATLAGQUERYERTEKTAR: TSmallintField
      FieldName = 'ERTEKTAR'
      Origin = 'ATLAGARFOLYAM.ERTEKTAR'
    end
    object ATLAGQUERYMEGNEVEZES: TIBStringField
      FieldName = 'MEGNEVEZES'
      Origin = 'ATLAGARFOLYAM.MEGNEVEZES'
      FixedChar = True
      Size = 33
    end
    object ATLAGQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'ATLAGARFOLYAM.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object ATLAGQUERYVETELBANKJEGY: TFloatField
      FieldName = 'VETELBANKJEGY'
      Origin = 'ATLAGARFOLYAM.VETELBANKJEGY'
    end
    object ATLAGQUERYVETELERTEK: TFloatField
      FieldName = 'VETELERTEK'
      Origin = 'ATLAGARFOLYAM.VETELERTEK'
    end
    object ATLAGQUERYELADBANKJEGY: TFloatField
      FieldName = 'ELADBANKJEGY'
      Origin = 'ATLAGARFOLYAM.ELADBANKJEGY'
    end
    object ATLAGQUERYELADERTEK: TFloatField
      FieldName = 'ELADERTEK'
      Origin = 'ATLAGARFOLYAM.ELADERTEK'
    end
    object ATLAGQUERYVETELATLAG: TFloatField
      FieldName = 'VETELATLAG'
      Origin = 'ATLAGARFOLYAM.VETELATLAG'
      DisplayFormat = '###,###,###'
    end
    object ATLAGQUERYELADATLAG: TFloatField
      FieldName = 'ELADATLAG'
      Origin = 'ATLAGARFOLYAM.ELADATLAG'
      DisplayFormat = '###,###,###'
    end
    object ATLAGQUERYVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
      Origin = 'ATLAGARFOLYAM.VALUTANEV'
      FixedChar = True
    end
    object ATLAGQUERYMARGE: TFloatField
      FieldName = 'MARGE'
      Origin = 'ATLAGARFOLYAM.MARGE'
      DisplayFormat = '0.####'
    end
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTIMERTimer
    Left = 16
    Top = 16
  end
  object ARFOLYAMQUERY: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 360
  end
  object ARFOLYAMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 544
    Top = 360
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFOLYAMDBASE
    AutoStopAction = saNone
    Left = 576
    Top = 360
  end
end
