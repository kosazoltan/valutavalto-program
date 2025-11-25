object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object BitBtn1: TBitBtn
    Left = 88
    Top = 112
    Width = 81
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object Memo1: TMemo
    Left = 88
    Top = 152
    Width = 681
    Height = 353
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object EVTIZEDPANEL: TPanel
    Left = 184
    Top = 104
    Width = 185
    Height = 41
    Caption = '2011'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object HONAPPANEL: TPanel
    Left = 376
    Top = 104
    Width = 185
    Height = 41
    Caption = '12'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object PENZTARPANEL: TPanel
    Left = 568
    Top = 104
    Width = 185
    Height = 41
    Caption = '125'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object VALTOTABLA: TIBTable
    Database = VALTODBASE
    Transaction = VALTOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 40
  end
  object VALTOQUERY: TIBQuery
    Database = VALTODBASE
    Transaction = VALTOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 224
    Top = 40
  end
  object VALTODBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALTOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 40
  end
  object VALTOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALTODBASE
    AutoStopAction = saNone
    Left = 288
    Top = 40
  end
  object TRANZQUERY: TIBQuery
    Database = TRANZDBASE
    Transaction = tranztranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
    Top = 40
  end
  object TRANZDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZS.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = tranztranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 392
    Top = 40
  end
  object tranztranz: TIBTransaction
    Active = False
    DefaultDatabase = TRANZDBASE
    AutoStopAction = saNone
    Left = 424
    Top = 40
  end
end
