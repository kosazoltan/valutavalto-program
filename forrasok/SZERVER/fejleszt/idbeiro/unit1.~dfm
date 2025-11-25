object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 135
  ClientWidth = 649
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object BitBtn1: TBitBtn
    Left = 152
    Top = 80
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'PROGRAM INDUL'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 336
    Top = 80
    Width = 169
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object IDPANEL: TPanel
    Left = 120
    Top = 8
    Width = 121
    Height = 41
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
  end
  object NEVPANEL: TPanel
    Left = 248
    Top = 8
    Width = 377
    Height = 41
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object PENZTARPANEL: TPanel
    Left = 8
    Top = 8
    Width = 97
    Height = 41
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object PROSTABLA: TIBTable
    Database = PROSDBASE
    Transaction = prostranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 16
  end
  object PROSQUERY: TIBQuery
    Database = PROSDBASE
    Transaction = prostranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 16
  end
  object PROSDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = prostranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 16
  end
  object prostranz: TIBTransaction
    Active = False
    DefaultDatabase = PROSDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 16
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 56
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 56
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
    Left = 104
    Top = 56
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 56
  end
end
