object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = '0/'
  ClientHeight = 329
  ClientWidth = 441
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 441
    Height = 329
    Color = clSilver
    TabOrder = 0
    object Label1: TLabel
      Left = 40
      Top = 24
      Width = 356
      Height = 21
      Caption = #193'TAD'#193'S-'#193'TV'#201'TEL TRANZAKCI'#211'K '
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 88
      Top = 48
      Width = 245
      Height = 19
      Caption = 'EXCEL T'#193'BL'#193'BA R'#214'GZIT'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object CSIK: TProgressBar
      Left = 16
      Top = 264
      Width = 409
      Height = 17
      Min = 0
      Max = 170
      Smooth = True
      TabOrder = 0
    end
    object PROGRESSPANEL: TPanel
      Left = 16
      Top = 88
      Width = 409
      Height = 41
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object PROG3PANEL: TPanel
      Left = 16
      Top = 208
      Width = 409
      Height = 41
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object PROG2PANEL: TPanel
      Left = 16
      Top = 160
      Width = 409
      Height = 41
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object CSIK2: TProgressBar
      Left = 16
      Top = 288
      Width = 409
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 4
    end
  end
  object BOOKQUERY: TIBQuery
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
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
    Left = 40
    Top = 8
  end
  object BOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BOOKDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 8
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
    Left = 160
    Top = 8
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 192
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPOTimer
    Left = 400
    Top = 8
  end
end
