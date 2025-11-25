object Form1: TForm1
  Left = 529
  Top = 331
  Width = 326
  Height = 288
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 310
    Height = 249
    Align = alClient
    Brush.Color = clMoneyGreen
    Pen.Color = clRed
    Pen.Width = 2
  end
  object Label2: TLabel
    Left = 56
    Top = 8
    Width = 197
    Height = 21
    Caption = #220'gyf'#233'l '#233's jogi text adatok '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 48
    Top = 32
    Width = 208
    Height = 21
    Caption = 'bedolgoz'#225'sa az FDB fileba'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label1: TLabel
    Left = 16
    Top = 72
    Width = 285
    Height = 23
    Caption = 'A FELDOZ'#193'S ALATTI P'#201'NZT'#193'R'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label4: TLabel
    Left = 88
    Top = 112
    Width = 178
    Height = 23
    Caption = '. SZ'#193'M'#218' P'#201'NZT'#193'R'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object STARTGOMB: TBitBtn
    Left = 16
    Top = 160
    Width = 121
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Enabled = False
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object ENDGOMB: TBitBtn
    Left = 152
    Top = 160
    Width = 123
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = ENDGOMBClick
  end
  object uzeno: TPanel
    Left = 16
    Top = 208
    Width = 281
    Height = 25
    BevelOuter = bvNone
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object PTNUMPANEL: TPanel
    Left = 24
    Top = 104
    Width = 57
    Height = 41
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -29
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object CSIK: TProgressBar
    Left = 16
    Top = 200
    Width = 281
    Height = 9
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 4
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 8
  end
  object UTABLA: TIBTable
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 240
    Top = 8
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ALLUGYFEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 240
    Top = 40
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 272
    Top = 40
  end
  object JTABLA: TIBTable
    Database = JDBASE
    Transaction = JTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object JQUERY: TIBQuery
    Database = JDBASE
    Transaction = JTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object JDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\ALLJOGI.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 40
  end
  object JTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JDBASE
    AutoStopAction = saNone
    Left = 40
    Top = 40
  end
end
