object Form1: TForm1
  Left = 461
  Top = 248
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 442
  ClientWidth = 434
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 434
    Height = 442
    Align = alClient
    Brush.Color = clRed
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object BitBtn1: TBitBtn
    Left = 128
    Top = 72
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = #218'J '#201'V NYIT'#193'SA'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 128
    Top = 392
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 16
    Top = 112
    Width = 401
    Height = 265
    Color = 11599871
    Lines.Strings = (
      '')
    TabOrder = 2
  end
  object Panel1: TPanel
    Left = 8
    Top = 16
    Width = 417
    Height = 41
    BevelOuter = bvNone
    Caption = 'K'#214'RLEVELEK '#201'VI NYIT'#193'SA'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object KQUERY: TIBQuery
    Database = KDBASE
    Transaction = KTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 120
  end
  object KDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KORLEVEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 160
    Top = 120
  end
  object KTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 120
  end
  object ktabla: TIBTable
    Database = KDBASE
    Transaction = KTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 120
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 3500
    OnTimer = KILEPOTimer
    Left = 24
    Top = 120
  end
  object SQUERY: TIBQuery
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 160
  end
  object SDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KORLEVEL.FDB'
    Params.Strings = (
      'user_name=sysdba'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 128
    Top = 160
  end
  object STRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SDBASE
    AutoStopAction = saNone
    Left = 160
    Top = 160
  end
  object PTQUERY: TIBQuery
    Database = PTDBASE
    Transaction = PTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 96
    Top = 208
  end
  object PTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 136
    Top = 208
  end
  object PTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PTDBASE
    AutoStopAction = saNone
    Left = 168
    Top = 208
  end
end
