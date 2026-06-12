object Form1: TForm1
  Left = 192
  Top = 124
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
  object Label1: TLabel
    Left = 168
    Top = 168
    Width = 164
    Height = 24
    Caption = 'KIT KERESSEK ?'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
  end
  object BitBtn1: TBitBtn
    Left = 32
    Top = 40
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'KERES'#201'S'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 32
    Top = 104
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object keredit: TEdit
    Left = 344
    Top = 168
    Width = 273
    Height = 32
    CharCase = ecUpperCase
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    Text = 'KEREDIT'
  end
  object Panel1: TPanel
    Left = 112
    Top = 232
    Width = 633
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object Panel2: TPanel
    Left = 112
    Top = 280
    Width = 633
    Height = 41
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object BitBtn3: TBitBtn
    Left = 32
    Top = 72
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'TAL'#193'LATOK T'#214'RL'#201'SE'
    TabOrder = 5
    OnClick = BitBtn3Click
  end
  object FEJQUERY: TIBQuery
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 32
  end
  object FEJDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = FEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 32
  end
  object FEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FEJDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 32
  end
  object GQUERY: TIBQuery
    Database = GDBASE
    Transaction = GTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 208
    Top = 72
  end
  object GDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\FEJLESZT\PERSONAL\PERSEEK\PERSEEK.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 72
  end
  object GTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GDBASE
    AutoStopAction = saNone
    Left = 288
    Top = 72
  end
  object TETQUERY: TIBQuery
    Database = TETDBASE
    Transaction = TETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 352
    Top = 40
  end
  object TETDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 392
    Top = 40
  end
  object TETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETDBASE
    AutoStopAction = saNone
    Left = 432
    Top = 40
  end
  object fejtabla: TIBTable
    Database = FEJDBASE
    Transaction = FEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 32
  end
end
