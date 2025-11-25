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
    Left = 24
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object ListBox1: TListBox
    Left = 160
    Top = 128
    Width = 553
    Height = 409
    ItemHeight = 13
    ScrollWidth = 2
    TabOrder = 1
  end
  object datumpanel: TPanel
    Left = 168
    Top = 80
    Width = 185
    Height = 41
    Caption = 'datumpanel'
    TabOrder = 2
  end
  object penztarpanel: TPanel
    Left = 368
    Top = 80
    Width = 337
    Height = 41
    Caption = 'penztarpanel'
    TabOrder = 3
  end
  object dbquery: TIBQuery
    Database = dbdbase
    Transaction = dbtranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 200
    Top = 16
  end
  object dbdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = dbtranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 232
    Top = 16
  end
  object dbtranz: TIBTransaction
    Active = False
    DefaultDatabase = dbdbase
    AutoStopAction = saNone
    Left = 272
    Top = 16
  end
  object dataquery: TIBQuery
    Database = datadbase
    Transaction = datatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 344
    Top = 16
  end
  object datadbase: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = datatranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 376
    Top = 16
  end
  object datatranz: TIBTransaction
    Active = False
    DefaultDatabase = datadbase
    AutoStopAction = saNone
    Left = 408
    Top = 16
  end
  object dbtabla: TIBTable
    Database = dbdbase
    Transaction = dbtranz
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'DAYB1101'
    Left = 32
    Top = 8
  end
  object DATATABLA: TIBTable
    Database = datadbase
    Transaction = datatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 448
    Top = 16
  end
end
