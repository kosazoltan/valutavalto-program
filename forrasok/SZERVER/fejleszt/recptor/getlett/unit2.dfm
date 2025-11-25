object GETLETTER: TGETLETTER
  Left = 211
  Top = 119
  BorderStyle = bsNone
  Caption = 'GETLETTER'
  ClientHeight = 119
  ClientWidth = 862
  Color = 16311512
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
    Left = 24
    Top = 24
    Width = 819
    Height = 41
    Caption = #193'TAD'#193'S-'#193'TV'#201'TEL R'#214'GZIT'#201'SE A T'#193'VOLI SZERVEREN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 40
    Top = 72
    Width = 777
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTIMERTimer
    Left = 8
    Top = 16
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'lc_ctype=WIN1250'
      'user_name=WORKUSER'
      'password=work116U')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 16
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 112
    Top = 16
  end
end
