object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 352
  ClientWidth = 472
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
  object ALAPPANEL: TPanel
    Left = 1
    Top = 1
    Width = 470
    Height = 350
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 0
    object Label1: TLabel
      Left = 32
      Top = 8
      Width = 416
      Height = 21
      Caption = 'OKM'#193'NYOK BEK'#220'LD'#201'SE A SZERVERRE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object MEMO1: TMemo
      Left = 4
      Top = 32
      Width = 462
      Height = 313
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        '')
      ParentFont = False
      TabOrder = 0
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 56
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 96
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
    Left = 88
    Top = 56
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
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
    Top = 96
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 128
    Top = 56
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 128
    Top = 96
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 2700
    OnTimer = KILEPOTimer
    Left = 48
    Top = 136
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 56
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 56
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 56
  end
end
