object ARFOLYAMELTERITES: TARFOLYAMELTERITES
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'ARFOLYAMELTERITES'
  ClientHeight = 532
  ClientWidth = 752
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object FUGGONY: TPanel
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Color = clWhite
    TabOrder = 0
    object Shape5: TShape
      Left = 0
      Top = 0
      Width = 750
      Height = 530
      Brush.Color = 11599871
      Pen.Color = clSkyBlue
      Pen.Width = 8
    end
    object Shape4: TShape
      Left = 88
      Top = 46
      Width = 569
      Height = 49
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label3: TLabel
      Left = 112
      Top = 48
      Width = 529
      Height = 43
      Caption = #193'RFOLYAM  KEDVEZM'#201'NYEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape1: TShape
      Left = 120
      Top = 176
      Width = 521
      Height = 105
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape2: TShape
      Left = 50
      Top = 426
      Width = 543
      Height = 38
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape3: TShape
      Left = 600
      Top = 426
      Width = 113
      Height = 38
      Pen.Width = 2
      Shape = stRoundRect
    end
    object IRODAPANEL: TPanel
      Left = 136
      Top = 232
      Width = 489
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object idoszakPanel: TPanel
      Left = 272
      Top = 192
      Width = 257
      Height = 33
      BevelOuter = bvNone
      Caption = '2009.05.01 - 2009.06.07'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object CSIK: TProgressBar
      Left = 56
      Top = 438
      Width = 529
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 2
    end
    object BitBtn1: TBitBtn
      Left = 608
      Top = 432
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 3
    end
  end
  object STARTTIMER: TTimer
    Enabled = False
    OnTimer = STARTTIMERTimer
    Left = 16
    Top = 168
  end
  object KEDVEZTABLA: TIBTable
    Database = KEDVEZDBASE
    Transaction = KEDVEZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODA'
        DataType = ftSmallint
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftSmallint
      end
      item
        Name = 'DATUM'
        DataType = ftString
        Size = 10
      end
      item
        Name = 'VALUTANEM'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'UJARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'PENZTAROSNEV'
        DataType = ftString
        Size = 25
      end
      item
        Name = 'BIZONYLATSZAM'
        DataType = ftString
        Size = 7
      end
      item
        Name = 'BANKJEGY'
        DataType = ftFloat
      end
      item
        Name = 'RATETYPE'
        DataType = ftSmallint
      end
      item
        Name = 'ENGEDMENY'
        DataType = ftFloat
      end>
    IndexDefs = <
      item
        Name = 'IDX_ARFOLYAMELTERITES'
        Fields = 'IRODA;VALUTANEM'
      end>
    IndexFieldNames = 'IRODA;VALUTANEM'
    StoreDefs = True
    TableName = 'ARFOLYAMELTERITES'
    Left = 128
    Top = 112
  end
  object KEDVEZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = KEDVEZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 160
    Top = 112
  end
  object KEDVEZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KEDVEZDBASE
    AutoStopAction = saNone
    Left = 192
    Top = 112
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 50
    OnTimer = KILEPOTIMERTimer
    Left = 56
    Top = 168
  end
  object ARFEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 328
    Top = 112
  end
  object ARFETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFEDBASE
    AutoStopAction = saNone
    Left = 360
    Top = 112
  end
  object ARFETABLA: TIBTable
    Database = ARFEDBASE
    Transaction = ARFETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'ARFE0903'
    Left = 296
    Top = 112
    object ARFETABLADATUM: TIBStringField
      FieldName = 'DATUM'
      Size = 10
    end
    object ARFETABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object ARFETABLAARFOLYAM: TFloatField
      FieldName = 'ARFOLYAM'
    end
    object ARFETABLAUJARFOLYAM: TFloatField
      FieldName = 'UJARFOLYAM'
    end
    object ARFETABLAPENZTAROSNEV: TIBStringField
      FieldName = 'PENZTAROSNEV'
      Size = 25
    end
    object ARFETABLABIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Size = 7
    end
    object ARFETABLABANKJEGY: TIntegerField
      FieldName = 'BANKJEGY'
    end
    object ARFETABLAENGEDMENYTIPUS: TSmallintField
      FieldName = 'ENGEDMENYTIPUS'
    end
  end
  object ARFEQUERY: TIBQuery
    Database = ARFEDBASE
    Transaction = ARFETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 112
  end
  object KEDVEZQUERY: TIBQuery
    Database = KEDVEZDBASE
    Transaction = KEDVEZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 112
  end
end
