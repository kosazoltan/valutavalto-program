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
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 112
    Top = 96
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object FAROKPANEL: TPanel
    Left = 232
    Top = 184
    Width = 345
    Height = 41
    Caption = 'FAROKPANEL'
    TabOrder = 1
  end
  object PATHPANEL: TPanel
    Left = 232
    Top = 232
    Width = 345
    Height = 41
    Caption = 'PATHPANEL'
    TabOrder = 2
  end
  object uzenopanel: TPanel
    Left = 232
    Top = 280
    Width = 345
    Height = 41
    Caption = 'uzenopanel'
    TabOrder = 3
  end
  object PTSEDIT: TEdit
    Left = 112
    Top = 40
    Width = 81
    Height = 45
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    Text = '123'
  end
  object DAYBQUERY: TIBQuery
    Database = DAYBDBASE
    Transaction = DAYBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 368
    Top = 24
  end
  object DAYBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = DAYBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 400
    Top = 24
  end
  object DAYBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBDBASE
    AutoStopAction = saNone
    Left = 432
    Top = 24
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 64
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 368
    Top = 64
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 400
    Top = 64
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 432
    Top = 64
  end
  object UGYQUERY: TIBQuery
    Database = UGYDBASE
    Transaction = UGYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 104
  end
  object UGYDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFFORG.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UGYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 368
    Top = 104
  end
  object UGYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UGYDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 400
    Top = 104
  end
end
