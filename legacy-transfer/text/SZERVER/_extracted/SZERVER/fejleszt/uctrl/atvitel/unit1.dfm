object Form1: TForm1
  Left = 192
  Top = 125
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
    Left = 40
    Top = 32
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 40
    Top = 64
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 144
    Top = 136
    Width = 257
    Height = 409
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'Memo1')
    ParentFont = False
    TabOrder = 2
  end
  object Memo2: TMemo
    Left = 416
    Top = 136
    Width = 353
    Height = 401
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'Memo2')
    ParentFont = False
    TabOrder = 3
  end
  object U19QUERY: TIBQuery
    Database = U19DBASE
    Transaction = U19TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 32
  end
  object U19DBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL19.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = U19TRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 32
  end
  object U19TRANZ: TIBTransaction
    Active = False
    DefaultDatabase = U19DBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 240
    Top = 32
  end
  object U20QUERY: TIBQuery
    Database = U20DBASE
    Transaction = U20TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 72
  end
  object U20DBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = U20TRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 72
  end
  object U20TRANZ: TIBTransaction
    Active = False
    DefaultDatabase = U20DBASE
    AutoStopAction = saNone
    Left = 248
    Top = 72
  end
  object U20TABLA: TIBTable
    Database = U20DBASE
    Transaction = U20TRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 136
    Top = 72
  end
end
