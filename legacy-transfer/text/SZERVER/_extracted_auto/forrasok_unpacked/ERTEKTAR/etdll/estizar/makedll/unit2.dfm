object MAKEPACK: TMAKEPACK
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Egy napi z'#225'r'#225's becsomagol'#225'sa'
  ClientHeight = 352
  ClientWidth = 463
  Color = clGradientInactiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape3: TShape
    Left = 0
    Top = 0
    Width = 465
    Height = 352
    Brush.Color = 10066329
    Pen.Color = clWhite
    Pen.Width = 6
  end
  object Shape4: TShape
    Left = 56
    Top = 128
    Width = 337
    Height = 153
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape5: TShape
    Left = 56
    Top = 296
    Width = 337
    Height = 41
    Brush.Color = 13697023
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Panel3: TPanel
    Left = 8
    Top = 16
    Width = 433
    Height = 25
    BevelOuter = bvNone
    Caption = 'NAPI Z'#193'R'#193'S CSOMAGJ'#193'NAK ELK'#201'SZIT'#201'SE'
    Color = 10066329
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object Panel4: TPanel
    Left = 8
    Top = 48
    Width = 433
    Height = 25
    BevelOuter = bvNone
    Caption = 'MELYIK NAP Z'#193'R'#193'S'#193'T CSOMAGOLJAM BE ?'
    Color = 10066329
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object NAPTAR: TCalendar
    Left = 64
    Top = 152
    Width = 320
    Height = 120
    BorderStyle = bsNone
    Color = clWhite
    StartOfWeek = 0
    TabOrder = 2
  end
  object ELOHOGOMB: TBitBtn
    Left = 88
    Top = 117
    Width = 129
    Height = 25
    Caption = '<< el'#337'z'#337' h'#243'nap'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    OnClick = ELOHOGOMBClick
  end
  object KOVHOGOMB: TBitBtn
    Left = 240
    Top = 117
    Width = 129
    Height = 25
    Caption = 'k'#246'vetkez'#337' h'#243'nap >>'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 4
    OnClick = KOVHOGOMBClick
  end
  object CSOMAGOLOGOMB: TBitBtn
    Left = 72
    Top = 304
    Width = 151
    Height = 25
    Cursor = crHandPoint
    Caption = 'CSOMAGOL'#193'S MEHET'
    TabOrder = 5
    OnClick = CsomagoloGombClick
  end
  object MEGSEMZARGOMB: TBitBtn
    Left = 228
    Top = 304
    Width = 151
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM CSOMAGOLOK'
    TabOrder = 6
    OnClick = MEGSEMZARGOMBClick
  end
  object EVHONAPPANEL: TPanel
    Left = 8
    Top = 80
    Width = 433
    Height = 25
    BevelOuter = bvNone
    Caption = '2012 szeptember'
    Color = 10066329
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 7
  end
  object uzenopanel: TPanel
    Left = 128
    Top = 184
    Width = 201
    Height = 41
    Caption = 'Csomag felir'#225'sa ...'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object TAKARO: TPanel
    Left = 16
    Top = 48
    Width = 433
    Height = 241
    TabOrder = 9
    object datumpanel: TPanel
      Left = 8
      Top = 8
      Width = 417
      Height = 41
      BevelOuter = bvNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object Memo1: TMemo
      Left = 16
      Top = 56
      Width = 401
      Height = 177
      BevelInner = bvNone
      BorderStyle = bsNone
      Color = clBtnFace
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        ''
        '')
      ParentFont = False
      TabOrder = 1
    end
  end
  object ALSOTAKARO: TPanel
    Left = 16
    Top = 292
    Width = 433
    Height = 48
    TabOrder = 10
    object Shape1: TShape
      Left = 16
      Top = 10
      Width = 402
      Height = 25
    end
    object Panel1: TPanel
      Left = 17
      Top = 11
      Width = 400
      Height = 23
      Color = clWhite
      TabOrder = 0
      object CSUSZKA: TPanel
        Left = 400
        Top = 0
        Width = 100
        Height = 23
        Color = clRed
        TabOrder = 0
      end
    end
  end
  object EREDMENYLAP: TPanel
    Left = -1980
    Top = 8
    Width = 449
    Height = 337
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 11
    Visible = False
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 64
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 64
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 120
    Top = 64
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 64
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 104
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 104
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 104
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 120
    Top = 104
  end
  object PSZALLQUERY: TIBQuery
    Database = PSZALLDBASE
    Transaction = PSZALLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 200
    Top = 64
  end
  object PSZALLDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PSZALLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 232
    Top = 64
  end
  object PSZALLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PSZALLDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 264
    Top = 64
  end
end
