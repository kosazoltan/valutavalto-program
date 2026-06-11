object Form1: TForm1
  Left = 507
  Top = 369
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 232
  ClientWidth = 395
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 393
    Height = 225
    Brush.Color = 10551295
    Pen.Width = 3
  end
  object EVCOMBO: TComboBox
    Left = 168
    Top = 56
    Width = 81
    Height = 28
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 0
  end
  object STARTGOMB: TBitBtn
    Left = 80
    Top = 104
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'LEV'#193'LOGAT'#193'S'
    TabOrder = 1
    OnClick = STARTGOMBClick
  end
  object KILEPOGOMB: TBitBtn
    Left = 216
    Top = 104
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 2
    OnClick = KILEPOGOMBClick
  end
  object LCSIK: TProgressBar
    Left = 24
    Top = 136
    Width = 345
    Height = 8
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 3
  end
  object HCSIK: TProgressBar
    Left = 24
    Top = 144
    Width = 345
    Height = 8
    Min = 0
    Max = 150
    Smooth = True
    TabOrder = 4
  end
  object honappanel: TPanel
    Left = 256
    Top = 160
    Width = 113
    Height = 41
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object penztarpanel: TPanel
    Left = 24
    Top = 160
    Width = 217
    Height = 41
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object focimpanel: TPanel
    Left = 32
    Top = 8
    Width = 337
    Height = 41
    BevelOuter = bvNone
    Caption = 'Western Union Forgalom'
    Color = 10551295
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 72
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V3.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 40
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 360
    Top = 8
  end
end
