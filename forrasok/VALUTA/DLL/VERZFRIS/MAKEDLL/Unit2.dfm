object VFRISS: TVFRISS
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'VERZIOFRISSITOFORM'
  ClientHeight = 606
  ClientWidth = 1016
  Color = 4539717
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object KERET: TShape
    Left = 0
    Top = 0
    Width = 1016
    Height = 606
    Align = alClient
    Brush.Color = 4539717
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 368
    Top = 48
    Width = 214
    Height = 41
    Caption = 'Verzi'#243' frissit'#233's'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object MEMO1: TMemo
    Left = 160
    Top = 144
    Width = 641
    Height = 369
    BorderStyle = bsNone
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'Verzi'#243' frissites megkezdve')
    ParentFont = False
    TabOrder = 0
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 2500
    OnTimer = KILEPOTimer
    Left = 120
    Top = 16
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 784
    Top = 32
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
    Left = 816
    Top = 32
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 848
    Top = 32
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 784
    Top = 80
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
    Left = 816
    Top = 80
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 848
    Top = 80
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 752
    Top = 80
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 752
    Top = 136
  end
  object IBDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 784
    Top = 136
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 816
    Top = 136
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 720
    Top = 136
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 744
    Top = 32
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 728
    Top = 176
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
    Left = 768
    Top = 176
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 808
    Top = 176
  end
end
