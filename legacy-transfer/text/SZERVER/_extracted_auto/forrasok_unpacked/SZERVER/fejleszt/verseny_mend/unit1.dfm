object Form1: TForm1
  Left = 584
  Top = 259
  Width = 420
  Height = 199
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
    Left = 40
    Top = 16
    Width = 315
    Height = 29
    Caption = 'EXPRESSZ VERSENY HIBAJAVIT'#211
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 40
    Top = 112
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 224
    Top = 112
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Panel1: TPanel
    Left = 32
    Top = 48
    Width = 353
    Height = 41
    BevelOuter = bvNone
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 168
    Top = 32
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 32
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 32
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 32
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 80
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\V151.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 80
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 80
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 80
  end
  object PROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PROSDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 128
  end
  object PROSQUERY: TIBQuery
    Database = PROSDBASE
    Transaction = PROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 128
  end
  object PROSDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 128
  end
end
