object Form1: TForm1
  Left = 424
  Top = 236
  Width = 292
  Height = 391
  Caption = 'P'#201'NZT'#193'RG'#201'P Z'#193'R'#193'SA'
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
    Left = 96
    Top = 8
    Width = 80
    Height = 25
    Caption = 'TESZT'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 80
    Top = 40
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 88
    Top = 312
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'KILEP'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object MEMO: TMemo
    Left = 24
    Top = 80
    Width = 225
    Height = 225
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 55
    OnTimer = KILEPOTimer
    Left = 40
    Top = 16
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 40
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 8
    Top = 80
  end
end
