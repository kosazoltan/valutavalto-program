object Form1: TForm1
  Left = 468
  Top = 299
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 465
  ClientWidth = 395
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 393
    Height = 457
    Color = clWhite
    TabOrder = 0
    object Label1: TLabel
      Left = 136
      Top = 0
      Width = 123
      Height = 41
      Caption = 'MEN'#368
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object comctrlgomb: TBitBtn
      Left = 32
      Top = 48
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'KOMMUNIK'#193'CI'#211' KONTROL'
      TabOrder = 0
      OnClick = comctrlgombClick
    end
    object prosbegomb: TBitBtn
      Left = 32
      Top = 80
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'ROS BEL'#201'P'#201'SE'
      TabOrder = 1
      OnClick = prosbegombClick
    end
    object KISVALTOGOMB: TBitBtn
      Left = 32
      Top = 112
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY KISEBB '#214'SSZEG'#220' V'#193'LT'#193'S'
      TabOrder = 2
      OnClick = KISVALTOGOMBClick
    end
    object NAGYVALTOGOMB: TBitBtn
      Left = 32
      Top = 144
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'NAGY '#214'SSZEG'#368' V'#193'LT'#193'S'
      TabOrder = 3
      OnClick = NAGYVALTOGOMBClick
    end
    object PROSKIGOMB: TBitBtn
      Left = 32
      Top = 240
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'ROS KIL'#201'P'#201'SE'
      TabOrder = 4
      OnClick = PROSKIGOMBClick
    end
    object TERMZAROGOMB: TBitBtn
      Left = 32
      Top = 304
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'TERMIN'#193'L LEZ'#193'R'#193'SA'
      TabOrder = 5
      OnClick = TERMZAROGOMBClick
    end
    object STORNOGOMB: TBitBtn
      Left = 32
      Top = 176
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'UTOLS'#211' TRANZAKCI'#211' STORN'#211'JA'
      TabOrder = 6
      OnClick = STORNOGOMBClick
    end
    object KILEPGOMB: TBitBtn
      Left = 32
      Top = 416
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      TabOrder = 7
      OnClick = KILEPGOMBClick
    end
    object VISSZAVETGOMB: TBitBtn
      Left = 32
      Top = 208
      Width = 329
      Height = 25
      Cursor = crHandPoint
      Caption = #193'RU VISSZAV'#201'T'
      TabOrder = 8
      OnClick = VISSZAVETGOMBClick
    end
    object PARALETOLTGOMB: TBitBtn
      Left = 32
      Top = 272
      Width = 329
      Height = 25
      Caption = 'PARAM'#201'TER LET'#214'LT'#201'S'
      TabOrder = 9
      OnClick = PARALETOLTGOMBClick
    end
    object REPLYCOMGOMB: TBitBtn
      Left = 32
      Top = 336
      Width = 329
      Height = 25
      Caption = 'EL'#336'Z'#336' PARANCS ISM'#201'TL'#201'SE'
      TabOrder = 10
      OnClick = REPLYCOMGOMBClick
    end
    object REPRINTGOMB: TBitBtn
      Left = 32
      Top = 368
      Width = 329
      Height = 25
      Caption = #218'JRANYOMTAT'#193'S'
      TabOrder = 11
      OnClick = REPRINTGOMBClick
    end
  end
  object XQUERY: TIBQuery
    Database = XDBASE
    Transaction = XTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
  end
  object XDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = XTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
  end
  object XTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = XDBASE
    AutoStopAction = saNone
    Left = 96
  end
end
