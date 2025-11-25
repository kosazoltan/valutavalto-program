object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 430
  ClientWidth = 678
  Color = clActiveBorder
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object KILEPOGOMB: TPanel
    Left = 192
    Top = 152
    Width = 305
    Height = 41
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'RE'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = KILEPOGOMBClick
  end
  object TAKAROPANEL: TPanel
    Left = 136
    Top = 112
    Width = 457
    Height = 105
    TabOrder = 1
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 424
      Height = 23
      Caption = 'AZ EXCELT'#193'BLA K'#201'SZ'#205'T'#201'SE FOLYAMATBAN'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object CSIK: TProgressBar
      Left = 16
      Top = 64
      Width = 425
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 0
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 16
    Top = 8
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 16
    Top = 40
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 72
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 16
    Top = 104
  end
  object MEZOSOURCE: TDataSource
    DataSet = UQUERY
    Enabled = False
    Left = 16
    Top = 144
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 400
    Top = 8
  end
  object FEJDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 432
    Top = 8
  end
  object FEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FEJDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 464
    Top = 8
  end
  object FEJSOURCE: TDataSource
    DataSet = FEJQUERY
    Enabled = False
    Left = 504
    Top = 8
  end
end
