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
  object Button1: TButton
    Left = 48
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 48
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 208
    Top = 192
    Width = 289
    Height = 41
    Caption = 'Panel1'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object FORGQUERY: TIBQuery
    Database = FORGDBASE
    Transaction = FORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 200
    Top = 32
  end
  object FORGTABLA: TIBTable
    Database = FORGDBASE
    Transaction = FORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'PENZTAR;DATUM'
    TableName = 'FORGALOM'
    Left = 168
    Top = 32
  end
  object FORGDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\SUMAXA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FORGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 232
    Top = 32
  end
  object FORGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FORGDBASE
    AutoStopAction = saNone
    Left = 272
    Top = 40
  end
  object SUMQUERY: TIBQuery
    Database = SUMDBASE
    Transaction = SUMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 392
    Top = 32
  end
  object SUMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\SUMAXA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SUMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 432
    Top = 32
  end
  object SUMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SUMDBASE
    AutoStopAction = saNone
    Left = 472
    Top = 32
  end
end
