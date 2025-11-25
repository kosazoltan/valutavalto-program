object CIMLETCONTROL: TCIMLETCONTROL
  Left = 192
  Top = 114
  Width = 380
  Height = 148
  Caption = 'CIMLETCONTROL'
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
  object Label1: TLabel
    Left = 56
    Top = 32
    Width = 285
    Height = 24
    Caption = 'CIMLETEK ELLEN'#336'RZ'#201'SE ...'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object INDITO: TTimer
    Enabled = False
    Interval = 200
    OnTimer = INDITOTimer
    Left = 40
    Top = 160
  end
  object vALUTAquery: TIBQuery
    Database = VALUTAdbase
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 80
  end
  object VALUTAdbase: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 80
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTAdbase
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 72
    Top = 80
  end
  object XQUERY: TIBQuery
    Database = XDBASE
    Transaction = XTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 264
    Top = 80
  end
  object XDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = XTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 296
    Top = 80
  end
  object XTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = XDBASE
    AutoStopAction = saNone
    Left = 328
    Top = 80
  end
  object CQUERY: TIBQuery
    Database = CDBASE
    Transaction = CTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 80
  end
  object CDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = CTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 184
    Top = 80
  end
  object CTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 80
  end
  object Ctabla: TIBTable
    Database = CDBASE
    Transaction = CTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'CIMINI'
    Left = 128
    Top = 80
  end
end
