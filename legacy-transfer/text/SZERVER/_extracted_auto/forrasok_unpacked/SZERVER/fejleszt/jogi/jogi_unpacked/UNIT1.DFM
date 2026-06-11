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
  object Label1: TLabel
    Left = 152
    Top = 24
    Width = 483
    Height = 36
    Caption = 'JOGI SZEM'#201'LYEK LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object Button1: TButton
    Left = 104
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 104
    Top = 128
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
  end
  object JOGIQUERY: TIBQuery
    Database = JOGIDBASE
    Transaction = JOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 96
  end
  object JOGIDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\JOGISZEMELY.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JOGITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 96
  end
  object JOGITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JOGIDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 96
  end
  object PTQUERY: TIBQuery
    Database = PTDBASE
    Transaction = PTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 128
  end
  object PTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V22.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 128
  end
  object PTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PTDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 128
  end
  object pttabla: TIBTable
    Database = PTDBASE
    Transaction = PTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 440
    Top = 128
  end
end
