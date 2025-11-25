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
    Left = 176
    Top = 104
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 176
    Top = 144
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = Button2Click
  end
  object RECQUERY: TIBQuery
    Database = recdbase
    Transaction = rectranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 16
  end
  object recdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = rectranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 16
  end
  object rectranz: TIBTransaction
    Active = False
    DefaultDatabase = recdbase
    AutoStopAction = saNone
    Left = 72
    Top = 16
  end
  object KDQUERY: TIBQuery
    Database = KDDBASE
    Transaction = KDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 56
  end
  object KDDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KEZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KDTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 56
  end
  object KDTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 56
  end
  object KDTABLA: TIBTable
    Database = KDDBASE
    Transaction = KDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 96
  end
end
