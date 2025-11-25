object Form1: TForm1
  Left = 192
  Top = 125
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clMoneyGreen
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 88
    Top = 72
    Width = 680
    Height = 33
    Caption = 'HI'#193'NYZ'#211' '#220'GYFELEK '#201'S TRANZAKCI'#211'K P'#211'TL'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object STARTGOMB: TBitBtn
    Left = 280
    Top = 520
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'PROGRAM INDIT'#193'SA'
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 440
    Top = 520
    Width = 145
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = KILEPOGOMBClick
  end
  object INFOBOX: TListBox
    Left = -1144
    Top = 120
    Width = 585
    Height = 433
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 21
    Items.Strings = (
      ' '
      '        A PROGRAM FELADATA:         A K'#214'ZPONTI SZERVER ADAT-'
      '   B'#193'ZIS'#193'B'#211'L HI'#193'NYZ'#211' NAGY '#220'GYFELEK,  '#201'S TRANZAKCI'#211'JUK '
      '                                           P'#211'TL'#193'SA.'
      ''
      '    A PROGRAM EL'#214'TT LE KELL FUTTATNI A HIBAKERESO.EXE--T'
      '                                   (RINOSZEROSZ-IKON)'
      ''
      '      A  HIBAKERES'#336'   PROGRAM  AZ  '#214'SSZES  VXX.FDB-BEN '
      '     V'#201'GIGN'#201'ZI A K'#201'RT ID'#336'SZAK ALATTI '#214'SSZES BF T'#193'BL'#193'T -'
      '                    '#201'S KIGY'#220'JTI AZOKAT A TRANZAKCI'#211'KAT,'
      '                  AMELYBEN '#201'RV'#201'NYTELEN PLOMBASZ'#193'M VAN.'
      ''
      '       AZ ADATOKAT BEIRJA A PGYUJTO.FDB PGYT'#193'BL'#193'JA - BA. '
      '         (MEZ'#336'K: P'#201'NZTAR,DATUM,NEV,PLOMBA,FIZETENDO,'
      '                                         TIPUS,BIZONYLAT)'
      '')
    ParentFont = False
    TabOrder = 2
    Visible = False
  end
  object mainpanel: TPanel
    Left = 144
    Top = 120
    Width = 585
    Height = 433
    TabOrder = 3
    Visible = False
    object CSIK: TProgressBar
      Left = 16
      Top = 408
      Width = 561
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 0
    end
    object LBOX: TListBox
      Left = 8
      Top = 8
      Width = 561
      Height = 361
      ItemHeight = 13
      TabOrder = 1
    end
    object BitBtn1: TBitBtn
      Left = 440
      Top = 376
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S'
      TabOrder = 2
      OnClick = KILEPOGOMBClick
    end
  end
  object tovabbgomb: TBitBtn
    Left = 344
    Top = 496
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'TOV'#193'BB'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = tovabbgombClick
  end
  object PGYQUERY: TIBQuery
    Database = PGYDBASE
    Transaction = PGYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 240
    Top = 24
  end
  object PGYDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\PGYUJTO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PGYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 280
    Top = 24
  end
  object PGYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PGYDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 24
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 16
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 16
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object ALLUGYFQUERY: TIBQuery
    Database = ALLUGYFDBASE
    Transaction = ALLUGYFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 416
    Top = 8
  end
  object ALLUGYFDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ALLUGYFEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ALLUGYFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 448
    Top = 8
  end
  object ALLUGYFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ALLUGYFDBASE
    AutoStopAction = saNone
    Left = 480
    Top = 8
  end
  object ALLJOGIQUERY: TIBQuery
    Database = ALLJOGIDBASE
    Transaction = ALLJOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 416
    Top = 40
  end
  object ALLJOGIDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ALLJOGI.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ALLJOGITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 448
    Top = 40
  end
  object ALLJOGITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ALLJOGIDBASE
    AutoStopAction = saNone
    Left = 480
    Top = 40
  end
  object ALLUGYFTABLA: TIBTable
    Database = ALLUGYFDBASE
    Transaction = ALLUGYFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 384
    Top = 8
  end
  object ALLJOGITABLA: TIBTable
    Database = ALLJOGIDBASE
    Transaction = ALLJOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 384
    Top = 40
  end
  object UGYFQUERY: TIBQuery
    Database = UGYFDBASE
    Transaction = UGYFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 592
    Top = 16
  end
  object UGYFDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UGYFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 632
    Top = 16
  end
  object UGYFTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = UGYFDBASE
    AutoStopAction = saNone
    Left = 672
    Top = 16
  end
  object UGYFTABLA: TIBTable
    Database = UGYFDBASE
    Transaction = UGYFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'ALAST'
        DataType = ftInteger
      end
      item
        Name = 'BLAST'
        DataType = ftInteger
      end
      item
        Name = 'CLAST'
        DataType = ftInteger
      end
      item
        Name = 'DLAST'
        DataType = ftInteger
      end
      item
        Name = 'ELAST'
        DataType = ftInteger
      end
      item
        Name = 'FLAST'
        DataType = ftInteger
      end
      item
        Name = 'GLAST'
        DataType = ftInteger
      end
      item
        Name = 'HLAST'
        DataType = ftInteger
      end
      item
        Name = 'ILAST'
        DataType = ftInteger
      end
      item
        Name = 'JLAST'
        DataType = ftInteger
      end
      item
        Name = 'KLAST'
        DataType = ftInteger
      end
      item
        Name = 'LLAST'
        DataType = ftInteger
      end
      item
        Name = 'MLAST'
        DataType = ftInteger
      end
      item
        Name = 'NLAST'
        DataType = ftInteger
      end
      item
        Name = 'OLAST'
        DataType = ftInteger
      end
      item
        Name = 'PLAST'
        DataType = ftInteger
      end
      item
        Name = 'QLAST'
        DataType = ftInteger
      end
      item
        Name = 'RLAST'
        DataType = ftInteger
      end
      item
        Name = 'SLAST'
        DataType = ftInteger
      end
      item
        Name = 'TLAST'
        DataType = ftInteger
      end
      item
        Name = 'ULAST'
        DataType = ftInteger
      end
      item
        Name = 'VLAST'
        DataType = ftInteger
      end
      item
        Name = 'WLAST'
        DataType = ftInteger
      end
      item
        Name = 'ZLAST'
        DataType = ftInteger
      end
      item
        Name = 'JOGILAST'
        DataType = ftInteger
      end
      item
        Name = 'XLAST'
        DataType = ftInteger
      end
      item
        Name = 'YLAST'
        DataType = ftInteger
      end>
    StoreDefs = True
    TableName = 'LASTNUMS'
    Left = 560
    Top = 16
  end
  object PGYTABLA: TIBTable
    Database = PGYDBASE
    Transaction = PGYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'PENZTAR'
    TableName = 'PGYUJTO'
    Left = 208
    Top = 24
  end
end
