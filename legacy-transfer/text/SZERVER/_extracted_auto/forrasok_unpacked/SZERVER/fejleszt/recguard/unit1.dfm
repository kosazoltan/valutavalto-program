object Form1: TForm1
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 35
  ClientWidth = 554
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
  object JEL: TPanel
    Left = 0
    Top = 0
    Width = 25
    Height = 25
    BevelOuter = bvNone
    Caption = '6'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
  end
  object CIKLUS: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = CIKLUSTimer
    Left = 48
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
  end
  object RECEPTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 144
  end
  object KAMERAQUERY: TIBQuery
    Database = KAMERADBASE
    Transaction = KAMERATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
  end
  object KAMERADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KAMERA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KAMERATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
  end
  object KAMERATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KAMERADBASE
    AutoStopAction = saNone
    Left = 280
  end
end
