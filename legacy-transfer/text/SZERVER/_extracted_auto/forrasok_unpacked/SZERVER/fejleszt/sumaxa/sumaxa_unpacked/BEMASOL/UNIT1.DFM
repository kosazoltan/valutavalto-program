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
    Left = 32
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 40
    Top = 64
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 208
    Top = 200
    Width = 273
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
  object READTABLA: TIBTable
    Database = READDBASE
    Transaction = READTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'PENZTAR;DATUM'
    TableName = 'SUMFORG'
    Left = 160
    Top = 32
  end
  object READDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\SUMAXA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = READTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 32
  end
  object READTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = READDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 32
  end
  object WRITEQUERY: TIBQuery
    Database = WRITEDBASE
    Transaction = WRITETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 400
    Top = 32
  end
  object WRITEDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WRITETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 440
    Top = 32
  end
  object WRITETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WRITEDBASE
    AutoStopAction = saNone
    Left = 480
    Top = 32
  end
  object writetabla: TIBTable
    Database = WRITEDBASE
    Transaction = WRITETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
    Top = 32
  end
end
