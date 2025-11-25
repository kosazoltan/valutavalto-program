object Form1: TForm1
  Left = 192
  Top = 114
  Width = 696
  Height = 480
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
    Left = 8
    Top = 16
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object kilepgomb: TBitBtn
    Left = 8
    Top = 48
    Width = 75
    Height = 25
    Caption = 'KILEP'
    TabOrder = 1
    Visible = False
  end
  object TRADETABLA: TIBTable
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 16
  end
  object TRADEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 16
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 16
  end
  object HAVIQUERY: TIBQuery
    Database = HAVIDBASE
    Transaction = HAVITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 56
  end
  object HAVIDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\STRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HAVITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 56
  end
  object HAVITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HAVIDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 56
  end
end
