object CIMLETNYOM: TCIMLETNYOM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'CIMLETNYOM'
  ClientHeight = 423
  ClientWidth = 501
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 500
    Height = 420
    TabOrder = 0
    object Label2: TLabel
      Left = 128
      Top = 136
      Width = 3
      Height = 13
      Caption = #160
    end
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 498
      Height = 418
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 56
      Top = 40
      Width = 381
      Height = 34
      Caption = 'C'#205'MLETEK KINYOMTAT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object STARTGOMB: TBitBtn
      Left = 48
      Top = 360
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'NYOMAT'#193'S INDUL'
      TabOrder = 6
      OnClick = STARTGOMBClick
    end
    object ALLMARKGOMB: TBitBtn
      Left = 184
      Top = 360
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'MINDEN KIJEL'#214'L'#201'SE'
      TabOrder = 7
      OnClick = ALLMARKGOMBClick
    end
    object EXITGOMB: TBitBtn
      Left = 320
      Top = 360
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S'
      TabOrder = 8
      OnClick = EXITGOMBClick
    end
    object BX1: TCheckBox
      Left = 88
      Top = 112
      Width = 305
      Height = 17
      Caption = 'Valutav'#225'lt'#225's c'#237'mletek nyomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 0
    end
    object BX2: TCheckBox
      Left = 88
      Top = 144
      Width = 289
      Height = 17
      Caption = 'Kezel'#233'si d'#237'j c'#237'mletek nyomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 1
    end
    object BX3: TCheckBox
      Left = 88
      Top = 176
      Width = 289
      Height = 17
      Caption = 'Western Union c'#237'mletek nyomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 2
    end
    object BX4: TCheckBox
      Left = 88
      Top = 208
      Width = 241
      Height = 17
      Caption = 'AFA cimletek nyomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 3
    end
    object BX5: TCheckBox
      Left = 88
      Top = 240
      Width = 289
      Height = 17
      Caption = 'Foglal'#243'k c'#237'mleteinek nyomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 4
    end
    object BX6: TCheckBox
      Left = 88
      Top = 272
      Width = 313
      Height = 17
      Caption = 'Elektromos keresked'#233's c'#237'mlet nomtat'#225'sa'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 5
    end
    object LISTPANEL: TPanel
      Left = -1800
      Top = 88
      Width = 449
      Height = 257
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 9
      Visible = False
      object DISPLAYBOX: TMemo
        Left = 8
        Top = 16
        Width = 433
        Height = 225
        BorderStyle = bsNone
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
      end
    end
    object BitBtn1: TBitBtn
      Left = 112
      Top = 320
      Width = 273
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#218'LT'#201'V Z'#193'R'#211'-K'#201'SZLET VALUTACIMLEZET'#201'S'
      TabOrder = 10
      OnClick = BitBtn1Click
    end
    object TAKARO: TPanel
      Left = -1980
      Top = 305
      Width = 449
      Height = 97
      BevelOuter = bvNone
      Caption = 'NYOMTAT'#193'S INDUL ....'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 11
      Visible = False
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 350
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object VDATAQUERY: TIBQuery
    Database = VDATADBASE
    Transaction = VDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 248
    Top = 16
  end
  object VDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 280
    Top = 16
  end
  object VDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDATADBASE
    AutoStopAction = saNone
    Left = 312
    Top = 16
  end
end
