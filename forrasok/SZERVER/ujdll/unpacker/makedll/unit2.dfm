object UNPACKER: TUNPACKER
  Left = 196
  Top = 134
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'UNPACKER'
  ClientHeight = 160
  ClientWidth = 1272
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1280
    Height = 160
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 0
    object Memo1: TMemo
      Left = -3
      Top = 29
      Width = 1270
      Height = 150
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        'CSOMAG T'#193'BL'#193'INAK DEK'#211'DOL'#193'SA ...')
      ParentFont = False
      TabOrder = 0
    end
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 24
  end
  object VDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 24
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 24
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 24
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 3500
    OnTimer = KILEPOTimer
    Left = 168
    Top = 24
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 24
  end
  object TEMPDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 240
    Top = 24
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    AutoStopAction = saNone
    Left = 272
    Top = 24
  end
  object RPTABLA: TIBTable
    Database = RPDBASE
    Transaction = RPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 64
  end
  object RPQUERY: TIBQuery
    Database = RPDBASE
    Transaction = RPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 64
  end
  object RPDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTPARA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 64
  end
  object RPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RPDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 64
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 64
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
    Left = 208
    Top = 64
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 64
  end
end
