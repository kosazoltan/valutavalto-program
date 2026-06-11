object Form1: TForm1
  Left = 192
  Top = 124
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
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 80
    Top = 40
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 80
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 160
    Top = 192
    Width = 449
    Height = 41
    Caption = 'Panel1'
    TabOrder = 2
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 40
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V150.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 40
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 40
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 88
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\4\P4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 88
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 88
  end
  object GQUERY: TIBQuery
    Database = GDBASE
    Transaction = GTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 48
  end
  object GDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\GIVEDATA.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 448
    Top = 48
  end
  object GTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GDBASE
    AutoStopAction = saNone
    Left = 488
    Top = 48
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 224
    Top = 40
  end
end
