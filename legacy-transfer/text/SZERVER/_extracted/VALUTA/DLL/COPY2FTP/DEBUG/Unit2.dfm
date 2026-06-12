object Form2: TForm2
  Left = -1200
  Top = 114
  Width = 203
  Height = 109
  Caption = 'Form2'
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
  object MQUERY: TIBQuery
    Database = MDBASE
    Transaction = MTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object MDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = MTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 16
  end
  object MTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 16
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 30
    OnTimer = KILEPOTimer
    Left = 136
    Top = 16
  end
end
