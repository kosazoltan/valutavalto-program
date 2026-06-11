object Form2: TForm2
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 396
  ClientWidth = 816
  Color = clRed
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
    Left = 3
    Top = 3
    Width = 810
    Height = 390
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 0
    object MEMO: TMemo
      Left = 16
      Top = 128
      Width = 769
      Height = 193
      BorderStyle = bsNone
      Color = 13697023
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object KULDOGOMB: TBitBtn
      Left = 96
      Top = 336
      Width = 291
      Height = 25
      Cursor = crHandPoint
      Caption = 'A FENTI K'#214'ZLEM'#201'NY BEK'#220'LD'#201'SE A SZERVERRE'
      TabOrder = 1
      OnClick = KULDOGOMBClick
    end
    object NOKULDOGOMB: TBitBtn
      Left = 392
      Top = 336
      Width = 297
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM K'#220'LD'#214'K BE SEMMIT'
      TabOrder = 2
      OnClick = NOKULDOGOMBClick
    end
    object Panel2: TPanel
      Left = 8
      Top = 8
      Width = 777
      Height = 113
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      object Label1: TLabel
        Left = 40
        Top = 64
        Width = 697
        Height = 19
        Caption = 
          'AZ AL'#193'BBI ABLAKBA BEIRT SZ'#214'VEG BEK'#220'LDHET'#336' A SZERVERRE, AHOL SEM ' +
          'A BEK'#220'LD'#336
      end
      object Label2: TLabel
        Left = 24
        Top = 80
        Width = 732
        Height = 19
        Caption = 
          'P'#201'NZ'#193'ROS, SEM A BEK'#220'LD'#336' P'#201'NZT'#193'R NEM AZONOS'#205'THAT'#211'  '#201'S CSAK 3 VEZE' +
          'T'#336' OLVASHATJA'
      end
      object Label3: TLabel
        Left = 168
        Top = 8
        Width = 436
        Height = 43
        Caption = 'BIZALMAS BEJELENT'#201'S'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -37
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
    end
  end
  object VALUTADBASE: TIBDatabase
    Connected = True
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
    Left = 120
    Top = 160
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 152
    Top = 160
  end
  object SERVERQUERY: TIBQuery
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 152
  end
  object SERVERDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 152
  end
  object SERVERTRANZ: TIBTransaction
    Active = False
    AutoStopAction = saNone
    Left = 328
    Top = 152
  end
  object HARDWAREQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 88
    Top = 160
  end
  object PENZTARQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 200
  end
end
