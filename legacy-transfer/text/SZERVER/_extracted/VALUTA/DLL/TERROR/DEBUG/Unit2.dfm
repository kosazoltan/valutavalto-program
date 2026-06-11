object TERROR: TTERROR
  Left = 413
  Top = 375
  BorderStyle = bsNone
  Caption = 'TERROR'
  ClientHeight = 236
  ClientWidth = 292
  Color = 11599871
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label2: TLabel
    Left = 64
    Top = 40
    Width = 152
    Height = 17
    Caption = 'AZ  '#220'GYF'#201'L  NEVE '
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -15
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 64
    Top = 56
    Width = 154
    Height = 17
    Caption = 'SZEREPEL AZ ENSZ'
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -15
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label4: TLabel
    Left = 64
    Top = 72
    Width = 151
    Height = 17
    Caption = 'TERRORLIST'#193'J'#193'N'
    Font.Charset = ANSI_CHARSET
    Font.Color = clRed
    Font.Height = -15
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label1: TLabel
    Left = 16
    Top = 176
    Width = 83
    Height = 13
    Caption = 'ENGED'#201'LYEZ'#336':'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 292
    Height = 33
    Caption = 'TERRORLITSA ELLEN'#336'RZ'#201'SE'
    Color = clRed
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object ENGEDELYGOMB: TBitBtn
    Left = 16
    Top = 124
    Width = 265
    Height = 25
    Cursor = crHandPoint
    Caption = 'Tranzakci'#243' enged'#233'lyezve'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = ENGEDELYGOMBClick
  end
  object STOPGOMB: TBitBtn
    Left = 16
    Top = 96
    Width = 265
    Height = 25
    Cursor = crHandPoint
    Caption = 'Tranzakci'#243' le'#225'll'#237't'#225'sa'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = STOPGOMBClick
  end
  object ENGEDELYEZOEDIT: TEdit
    Left = 105
    Top = 172
    Width = 176
    Height = 21
    CharCase = ecUpperCase
    TabOrder = 3
    OnKeyDown = ENGEDELYEZOEDITKeyDown
  end
  object ENGEDELYEZOGOMB: TBitBtn
    Left = 40
    Top = 200
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'ENGED'#201'LYEZVE'
    Default = True
    TabOrder = 4
    OnClick = ENGEDELYEZOGOMBClick
  end
  object MEGSEMGOMB: TBitBtn
    Left = 152
    Top = 200
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM'
    TabOrder = 5
    OnClick = STOPGOMBClick
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 104
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 72
  end
  object TEMPDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    AutoStopAction = saNone
    Left = 40
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 40
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 40
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 40
  end
end
