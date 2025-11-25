object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 329
  ClientWidth = 441
  Color = 11591728
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
    Left = 48
    Top = 24
    Width = 357
    Height = 24
    Caption = 'HAVI NYIT'#211' - Z'#193'R'#211' K'#201'SZLETEK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 120
    Top = 56
    Width = 211
    Height = 24
    Caption = 'MEGHAT'#193'ROZ'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 264
    Width = 409
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 0
  end
  object CSIK2: TProgressBar
    Left = 16
    Top = 288
    Width = 409
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 1
  end
  object PROGRESSPANEL: TPanel
    Left = 16
    Top = 128
    Width = 409
    Height = 41
    BevelOuter = bvNone
    Color = 11591728
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object PROG2PANEL: TPanel
    Left = 16
    Top = 184
    Width = 409
    Height = 41
    BevelOuter = bvNone
    Color = 11591728
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object BOOKTABLA: TIBTable
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 96
  end
  object BOOKQUERY: TIBQuery
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 96
  end
  object BOOKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 96
  end
  object BOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BOOKDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 96
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KilepoTimer
    Left = 120
    Top = 96
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 96
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
    Left = 216
    Top = 96
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 248
    Top = 96
  end
end
