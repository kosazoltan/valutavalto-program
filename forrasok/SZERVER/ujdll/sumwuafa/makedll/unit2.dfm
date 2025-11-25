object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 43
  ClientWidth = 332
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object messpanel: TPanel
    Left = 0
    Top = 0
    Width = 330
    Height = 41
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object WTABLA: TIBTable
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'WUNIGYUJTO'
    Left = 40
    Top = 8
  end
  object WQUERY: TIBQuery
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
    Top = 8
  end
  object WDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 104
    Top = 8
  end
  object WTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTimer
    Left = 8
    Top = 8
  end
end
