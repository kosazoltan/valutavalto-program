object Form3: TForm3
  Left = 504
  Top = 314
  BorderStyle = bsNone
  Caption = 'Form3'
  ClientHeight = 30
  ClientWidth = 252
  Color = clMoneyGreen
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
    Width = 249
    Height = 25
    BevelOuter = bvNone
    Caption = 'EXCELT'#193'BLA ELK'#201'SZIT'#201'SE'
    Color = clMoneyGreen
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object GYUJTOQUERY: TIBQuery
    Database = GYUJTODBASE
    Transaction = GYUJTOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
  end
  object GYUJTODBASE: TIBDatabase
    DatabaseName = 'C:\JOGISZEMELY\DATABASE\JOGIGYUJTO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYUJTOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
  end
  object GYUJTOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYUJTODBASE
    AutoStopAction = saNone
    Left = 72
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 112
  end
end
