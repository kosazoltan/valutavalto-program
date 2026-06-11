object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 453
  ClientWidth = 444
  Color = clRed
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
    Left = 5
    Top = 5
    Width = 434
    Height = 442
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 0
    object Label1: TLabel
      Left = 56
      Top = 32
      Width = 337
      Height = 21
      Caption = 'K'#214'RLEVELEK '#201'V ELEJI NYIT'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Memo1: TMemo
      Left = 24
      Top = 72
      Width = 385
      Height = 345
      BorderStyle = bsNone
      Color = 11599871
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        '')
      ParentFont = False
      TabOrder = 0
    end
  end
  object KTABLA: TIBTable
    Database = KDBASE
    Transaction = KTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object KQUERY: TIBQuery
    Database = KDBASE
    Transaction = KTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object KDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object KTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object SQUERY: TIBQuery
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 288
    Top = 8
  end
  object SDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 320
    Top = 8
  end
  object STRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SDBASE
    AutoStopAction = saNone
    Left = 352
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 3500
    OnTimer = KilepoTimer
    Left = 160
    Top = 8
  end
end
