object AFATABLAZATFORM: TAFATABLAZATFORM
  Left = 200
  Top = 133
  AlphaBlend = True
  BorderStyle = bsNone
  Caption = 'AFATABLAZATFORM'
  ClientHeight = 392
  ClientWidth = 742
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
  object Panel10: TPanel
    Left = 8
    Top = 6
    Width = 730
    Height = 380
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object Panel11: TPanel
      Left = 8
      Top = 8
      Width = 129
      Height = 41
      Caption = 'D'#193'TUM'
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object Panel12: TPanel
      Left = 336
      Top = 8
      Width = 185
      Height = 41
      Caption = 'WESTERN UNION'
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object Panel13: TPanel
      Left = 528
      Top = 8
      Width = 89
      Height = 41
      Caption = 'METROAFA'
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object Panel14: TPanel
      Left = 624
      Top = 8
      Width = 89
      Height = 41
      Caption = 'TESCOAFA'
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
    object Panel15: TPanel
      Left = 144
      Top = 8
      Width = 185
      Height = 89
      Caption = 'T'#201'TEL'
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
    object DATUMLISTBOX: TListBox
      Left = 8
      Top = 56
      Width = 129
      Height = 281
      Cursor = crHandPoint
      ItemHeight = 18
      TabOrder = 5
      OnClick = DATUMLISTBOXClick
      OnDblClick = DATUMLISTBOXClick
      OnKeyUp = DATUMLISTBOXKeyUp
    end
    object Panel17: TPanel
      Left = 144
      Top = 104
      Width = 185
      Height = 41
      Caption = 'NYIT'#211
      Color = clSilver
      TabOrder = 6
    end
    object Panel18: TPanel
      Left = 144
      Top = 152
      Width = 185
      Height = 41
      Caption = 'BEV'#201'TEL'
      Color = clSilver
      TabOrder = 7
    end
    object Panel19: TPanel
      Left = 144
      Top = 200
      Width = 185
      Height = 41
      Caption = 'KIAD'#193'S'
      Color = clSilver
      TabOrder = 8
    end
    object Panel20: TPanel
      Left = 144
      Top = 248
      Width = 185
      Height = 41
      Caption = 'VISSZAT'#201'R'#205'T'#201'S'
      Color = clSilver
      TabOrder = 9
    end
    object Panel21: TPanel
      Left = 144
      Top = 296
      Width = 185
      Height = 41
      Caption = 'Z'#193'R'#211
      Color = clSilver
      TabOrder = 10
    end
    object WUUNYPANEL: TPanel
      Left = 336
      Top = 104
      Width = 89
      Height = 41
      Caption = '123 456 789'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 11
    end
    object WUHNYPANEL: TPanel
      Left = 432
      Top = 104
      Width = 89
      Height = 41
      Caption = 'WUHNYPANEL'
      Color = clWhite
      TabOrder = 12
    end
    object ANYPANEL: TPanel
      Left = 528
      Top = 104
      Width = 89
      Height = 41
      Caption = 'ANYPANEL'
      Color = clWhite
      TabOrder = 13
    end
    object WUUBPANEL: TPanel
      Left = 336
      Top = 152
      Width = 89
      Height = 41
      Caption = 'WUUBPANEL'
      Color = clWhite
      TabOrder = 14
    end
    object WUUKPANEL: TPanel
      Left = 336
      Top = 200
      Width = 89
      Height = 41
      Caption = 'WUUKPANEL'
      Color = clWhite
      TabOrder = 15
    end
    object WUUVPANEL: TPanel
      Left = 336
      Top = 248
      Width = 89
      Height = 41
      Caption = '--'
      Color = clWhite
      TabOrder = 16
    end
    object WUUZPANEL: TPanel
      Left = 336
      Top = 296
      Width = 89
      Height = 41
      Caption = 'WUUZPANEL'
      Color = clWhite
      TabOrder = 17
    end
    object WUHBPANEL: TPanel
      Left = 432
      Top = 152
      Width = 89
      Height = 41
      Caption = 'WUHBPANEL'
      Color = clWhite
      TabOrder = 18
    end
    object WUHKPANEL: TPanel
      Left = 432
      Top = 200
      Width = 89
      Height = 41
      Caption = 'WUHKPANEL'
      Color = clWhite
      TabOrder = 19
    end
    object WUHVPANEL: TPanel
      Left = 432
      Top = 248
      Width = 89
      Height = 41
      Caption = '--'
      Color = clWhite
      TabOrder = 20
    end
    object WUHZPANEL: TPanel
      Left = 432
      Top = 296
      Width = 89
      Height = 41
      Caption = 'WUHZPANEL'
      Color = clWhite
      TabOrder = 21
    end
    object ABPANEL: TPanel
      Left = 528
      Top = 152
      Width = 89
      Height = 41
      Caption = 'ABPANEL'
      Color = clWhite
      TabOrder = 22
    end
    object AKPANEL: TPanel
      Left = 528
      Top = 200
      Width = 89
      Height = 41
      Caption = 'AKPANEL'
      Color = clWhite
      TabOrder = 23
    end
    object AVPANEL: TPanel
      Left = 528
      Top = 248
      Width = 89
      Height = 41
      Caption = 'AVPANEL'
      Color = clWhite
      TabOrder = 24
    end
    object AZPANEL: TPanel
      Left = 528
      Top = 296
      Width = 89
      Height = 41
      Caption = 'AZPANEL'
      Color = clWhite
      TabOrder = 25
    end
    object Panel41: TPanel
      Left = 432
      Top = 56
      Width = 89
      Height = 41
      Caption = 'HUF'
      Color = clSilver
      TabOrder = 26
    end
    object Panel42: TPanel
      Left = 336
      Top = 56
      Width = 89
      Height = 41
      Caption = 'USD'
      Color = clSilver
      TabOrder = 27
    end
    object Panel43: TPanel
      Left = 528
      Top = 56
      Width = 89
      Height = 41
      Caption = 'HUF'
      Color = clSilver
      TabOrder = 28
    end
    object Panel44: TPanel
      Left = 624
      Top = 56
      Width = 89
      Height = 41
      Caption = 'HUF'
      Color = clSilver
      TabOrder = 29
    end
    object ESCAPEGOMB: TBitBtn
      Left = 624
      Top = 344
      Width = 89
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 30
      OnClick = ESCAPEGOMBClick
    end
    object INYPANEL: TPanel
      Left = 624
      Top = 104
      Width = 89
      Height = 41
      Caption = 'INYPANEL'
      Color = clWhite
      TabOrder = 31
    end
    object IBPANEL: TPanel
      Left = 624
      Top = 152
      Width = 89
      Height = 41
      Caption = 'IBPANEL'
      Color = clWhite
      TabOrder = 32
    end
    object IKPANEL: TPanel
      Left = 624
      Top = 200
      Width = 89
      Height = 41
      Caption = 'IKPANEL'
      Color = clWhite
      TabOrder = 33
    end
    object IVPANEL: TPanel
      Left = 624
      Top = 248
      Width = 89
      Height = 41
      Caption = 'IVPANEL'
      Color = clWhite
      TabOrder = 34
    end
    object IZPANEL: TPanel
      Left = 624
      Top = 296
      Width = 89
      Height = 41
      Caption = 'IZPANEL'
      Color = clWhite
      TabOrder = 35
    end
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 272
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
    Left = 64
    Top = 272
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 272
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 312
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 312
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 96
    Top = 312
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 240
  end
end
