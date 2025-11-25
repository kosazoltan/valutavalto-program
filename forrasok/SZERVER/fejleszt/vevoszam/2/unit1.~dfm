object Form1: TForm1
  Left = 192
  Top = 114
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 24
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 24
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 120
    Top = 176
    Width = 617
    Height = 41
    Caption = 'Panel1'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 120
    Top = 232
    Width = 617
    Height = 41
    Caption = 'Panel2'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 24
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 24
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 224
    Top = 24
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 256
    Top = 24
  end
  object VEVOQUERY: TIBQuery
    Database = VEVODBASE
    Transaction = vevotranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 368
    Top = 24
  end
  object VEVODBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\VEVOK.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = vevotranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 400
    Top = 24
  end
  object vevotranz: TIBTransaction
    Active = False
    DefaultDatabase = VEVODBASE
    AutoStopAction = saNone
    Left = 432
    Top = 24
  end
  object TETELQUERY: TIBQuery
    Database = TETELDBASE
    Transaction = TETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 512
    Top = 32
  end
  object TETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETELDBASE
    AutoStopAction = saNone
    Left = 576
    Top = 32
  end
  object TETELDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 544
    Top = 32
  end
end
