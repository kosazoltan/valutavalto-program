object MATRICANYOMTATO: TMATRICANYOMTATO
  Left = 192
  Top = 125
  Width = 870
  Height = 640
  Caption = 'MATRICANYOMTATO'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object BitBtn1: TBitBtn
    Left = 40
    Top = 48
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object MATQUERY: TIBQuery
    Database = MATDBASE
    Transaction = MATTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 152
    Top = 40
  end
  object MATDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = MATTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 184
    Top = 40
  end
  object MATTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MATDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 40
  end
end
