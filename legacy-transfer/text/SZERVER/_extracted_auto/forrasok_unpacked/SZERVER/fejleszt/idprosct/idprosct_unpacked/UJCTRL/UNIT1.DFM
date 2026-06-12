object Form1: TForm1
  Left = 192
  Top = 114
  Width = 365
  Height = 640
  Caption = 'ID-K'#211'D ELLEN'#336'RZ'#201'S ....'
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
    Left = 48
    Top = 32
    Width = 247
    Height = 29
    Caption = 'ID-K'#211'D ELLEN'#336'RZ'#201'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 104
    Top = 164
    Width = 114
    Height = 20
    Caption = 'P'#201'NZT'#193'R = '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object STARTGOMB: TButton
    Left = 80
    Top = 128
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'ELLEN'#214'RZ'#201'S INDUL'
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object EVCOMBO: TComboBox
    Left = 80
    Top = 80
    Width = 73
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 1
    Text = '2013'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 152
    Top = 80
    Width = 129
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 2
    Text = 'szeptember'
    OnChange = EVCOMBOChange
  end
  object KILEPOGOMB: TBitBtn
    Left = 80
    Top = 560
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    TabOrder = 3
    OnClick = KILEPOGOMBClick
  end
  object ListBox: TListBox
    Left = 24
    Top = 200
    Width = 305
    Height = 345
    ItemHeight = 13
    TabOrder = 4
  end
  object PENZTARPANEL: TPanel
    Left = 208
    Top = 160
    Width = 49
    Height = 25
    BevelOuter = bvNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object PQuery: TIBQuery
    Database = PDBASE
    Transaction = PTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 488
  end
  object PDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PTAROSOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 488
  end
  object PTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 488
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 88
    Top = 448
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 120
    Top = 448
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 152
    Top = 448
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 448
  end
end
