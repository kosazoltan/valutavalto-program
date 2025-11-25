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
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 168
    Top = 160
    Width = 28
    Height = 13
    Caption = 'BEST'
  end
  object Label2: TLabel
    Left = 368
    Top = 160
    Width = 28
    Height = 13
    Caption = 'EAST'
  end
  object Label3: TLabel
    Left = 544
    Top = 152
    Width = 46
    Height = 13
    Caption = 'PANNON'
  end
  object BitBtn1: TBitBtn
    Left = 32
    Top = 32
    Width = 75
    Height = 25
    Caption = 'BitBtn1'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 120
    Top = 32
    Width = 75
    Height = 25
    Caption = 'BitBtn2'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object BEST: TPanel
    Left = 104
    Top = 184
    Width = 185
    Height = 41
    Caption = 'BEST'
    TabOrder = 2
  end
  object EAST: TPanel
    Left = 304
    Top = 184
    Width = 185
    Height = 41
    Caption = 'EAST'
    TabOrder = 3
  end
  object PANNON: TPanel
    Left = 496
    Top = 184
    Width = 185
    Height = 41
    Caption = 'PANNON'
    TabOrder = 4
  end
  object penztar: TPanel
    Left = 488
    Top = 40
    Width = 137
    Height = 41
    Caption = 'penztar'
    TabOrder = 5
  end
  object honap: TPanel
    Left = 640
    Top = 40
    Width = 121
    Height = 41
    Caption = 'honap'
    TabOrder = 6
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 32
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 32
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 336
    Top = 32
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 384
    Top = 40
  end
end
