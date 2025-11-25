object ATLAGARFOLYAM: TATLAGARFOLYAM
  Left = 266
  Top = 171
  BorderStyle = bsNone
  Caption = 'ATLAGARFOLYAM'
  ClientHeight = 530
  ClientWidth = 749
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 750
    Height = 530
    Brush.Color = 8421631
    Pen.Color = 170
    Pen.Width = 8
  end
  object Shape2: TShape
    Left = 24
    Top = 80
    Width = 697
    Height = 345
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 32
    Top = 16
    Width = 689
    Height = 57
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape4: TShape
    Left = 24
    Top = 456
    Width = 577
    Height = 25
    Shape = stRoundRect
  end
  object FOCIMPANEL: TPanel
    Left = 40
    Top = 24
    Width = 673
    Height = 41
    BevelOuter = bvNone
    Caption = #193'TLAGOS '#193'RFOLYAM 2009.01.03 '#201'S 2009.02.22 K'#214'Z'#214'TTI ID'#214'SZAKBAN'
    Color = 11599871
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clMaroon
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object CSIK: TProgressBar
    Left = 32
    Top = 460
    Width = 561
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 1
  end
  object BitBtn1: TBitBtn
    Left = 608
    Top = 456
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = BitBtn1Click
  end
  object FUGGONY: TPanel
    Left = 48
    Top = 88
    Width = 641
    Height = 329
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 3
    object Label1: TLabel
      Left = 80
      Top = 24
      Width = 518
      Height = 43
      Caption = #193'TLAG'#193'RFOLYAM SZ'#193'MIT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object IRODAPANEL: TPanel
      Left = 48
      Top = 104
      Width = 585
      Height = 41
      BevelInner = bvRaised
      BevelWidth = 2
      Color = 7405424
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clTeal
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object STARTTIMER: TTimer
    Enabled = False
    OnTimer = STARTTIMERTimer
    Left = 240
    Top = 232
  end
  object VALUTASOURCE: TDataSource
    DataSet = ATLAGTABLA
    Left = 280
    Top = 232
  end
  object MERGESOURCE: TDataSource
    DataSet = ATLAGTABLA
    Left = 240
    Top = 360
  end
  object ATLAGTABLA: TIBTable
    Database = ATLAGDBASE
    Transaction = ATLAGTRANZ
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
        Name = 'MEGNEVEZES'
        Attributes = [faFixed]
        DataType = ftString
        Size = 33
      end
      item
        Name = 'VALUTANEM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'VETELBANKJEGY'
        DataType = ftFloat
      end
      item
        Name = 'VETELERTEK'
        DataType = ftFloat
      end
      item
        Name = 'ELADBANKJEGY'
        DataType = ftFloat
      end
      item
        Name = 'ELADERTEK'
        DataType = ftFloat
      end
      item
        Name = 'VETELATLAG'
        DataType = ftFloat
      end
      item
        Name = 'ELADATLAG'
        DataType = ftFloat
      end
      item
        Name = 'VALUTANEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end
      item
        Name = 'MARGE'
        DataType = ftFloat
      end
      item
        Name = 'CEGBETU'
        Attributes = [faFixed]
        DataType = ftString
        Size = 1
      end>
    IndexDefs = <
      item
        Name = 'IDX_ATLAGARFOLYAM'
        Fields = 'IRODA;VALUTANEM'
      end
      item
        Name = 'ALTXATLAGARFOLYAM'
        Fields = 'VALUTANEM'
      end>
    IndexFieldNames = 'IRODA;VALUTANEM'
    StoreDefs = True
    TableName = 'ATLAGARFOLYAM'
    Left = 568
    Top = 368
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
    Left = 600
    Top = 368
  end
  object ATLAGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ATLAGDBASE
    AutoStopAction = saNone
    Left = 632
    Top = 368
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 304
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 272
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 272
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 272
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTIMERTimer
    Left = 208
    Top = 232
  end
  object AtlagQuery: TIBQuery
    Database = ATLAGDBASE
    Transaction = ATLAGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 528
    Top = 368
  end
end
