object PERSONALBEDOLGOZAS: TPERSONALBEDOLGOZAS
  Left = 393
  Top = 117
  AlphaBlend = True
  AlphaBlendValue = 180
  BorderStyle = bsNone
  Caption = 'PERSONALBEDOLGOZAS'
  ClientHeight = 101
  ClientWidth = 506
  Color = 16311512
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
    Left = 8
    Top = 16
    Width = 474
    Height = 29
    Caption = 'SZEM'#201'LYES ADATOK BEDOLGOZ'#193'SA'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 80
    Width = 465
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object CIMPANEL: TPanel
    Left = 16
    Top = 48
    Width = 465
    Height = 25
    Caption = #220'GYFELEK'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 300
    OnTimer = KILEPOTIMERTimer
    Left = 8
    Top = 8
  end
  object PERSONQUERY: TIBQuery
    Database = PERSONDBASE
    Transaction = PERSONTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
  end
  object PERSONDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PERSONAL.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PERSONTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
  end
  object PERSONTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PERSONDBASE
    AutoStopAction = saNone
    Left = 240
  end
end
