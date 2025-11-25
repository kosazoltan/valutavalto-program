object Form1: TForm1
  Left = 211
  Top = 306
  Width = 870
  Height = 299
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
    Left = 208
    Top = 32
    Width = 427
    Height = 36
    Caption = 'REND'#214'RS'#201'GI MEGKERES'#201'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Panel1: TPanel
    Left = 16
    Top = 160
    Width = 801
    Height = 41
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 16
    Top = 208
    Width = 801
    Height = 41
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object BitBtn1: TBitBtn
    Left = 152
    Top = 112
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    TabOrder = 2
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 504
    Top = 112
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    TabOrder = 3
    OnClick = BitBtn2Click
  end
  object BitBtn3: TBitBtn
    Left = 328
    Top = 112
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'BEDOLGOZ'#193'S'
    TabOrder = 4
    OnClick = BitBtn3Click
  end
  object ibquery: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 16
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 16
  end
  object IBTabla: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 48
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 688
    Top = 16
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\POLICE.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 720
    Top = 16
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 752
    Top = 16
  end
  object PTABLA: TIBTable
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'POLICE'
    Left = 656
    Top = 16
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 720
    Top = 80
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V32.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 760
    Top = 80
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 808
    Top = 80
  end
end
