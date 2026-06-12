object Form1: TForm1
  Left = 192
  Top = 114
  Width = 402
  Height = 446
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 168
    Top = 224
    Width = 71
    Height = 29
    Caption = 'H'#243'nap'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object Button1: TButton
    Left = 112
    Top = 280
    Width = 121
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = Button1Click
  end
  object hoedit: TEdit
    Left = 112
    Top = 224
    Width = 49
    Height = 37
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Text = '6'
  end
  object Button2: TButton
    Left = 112
    Top = 320
    Width = 121
    Height = 25
    Caption = 'KIL'#201'P'
    TabOrder = 2
    OnClick = Button2Click
  end
  object penztarpanel: TPanel
    Left = 16
    Top = 40
    Width = 321
    Height = 41
    Caption = 'penztarpanel'
    TabOrder = 3
  end
  object datumpanel: TPanel
    Left = 16
    Top = 88
    Width = 321
    Height = 41
    Caption = 'datumpanel'
    TabOrder = 4
  end
  object statuspanel: TPanel
    Left = 16
    Top = 144
    Width = 321
    Height = 41
    Caption = 'statuspanel'
    TabOrder = 5
  end
  object KESZPANEL: TPanel
    Left = 24
    Top = 360
    Width = 337
    Height = 41
    Caption = 'K'#201'SZEN VAGYOK'
    Color = clRed
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 6
    Visible = False
  end
  object PQUERY: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PCONTROL.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 8
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 8
  end
  object WQUERY: TIBQuery
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 48
  end
  object WDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 48
  end
  object WTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 48
  end
  object BFQUERY: TIBQuery
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 88
  end
  object BFDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 88
  end
  object BFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BFDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 88
  end
  object wtabla: TIBTable
    Database = WDBASE
    Transaction = WTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Top = 8
  end
  object BFTABLA: TIBTable
    Database = BFDBASE
    Transaction = BFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Top = 88
  end
end
