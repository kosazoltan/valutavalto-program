object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 529
  ClientWidth = 420
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
  object Shape4: TShape
    Left = 0
    Top = 0
    Width = 420
    Height = 529
    Align = alClient
    Brush.Color = 16311512
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 72
    Top = 16
    Width = 289
    Height = 22
    Caption = 'Western Union havi forgalmi adatai'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 72
    Top = 56
    Width = 281
    Height = 24
    Caption = 'K'#201'REM A KIV'#193'NT H'#211'NAPOT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 88
    Top = 88
    Width = 249
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 120
    Top = 160
    Width = 193
    Height = 73
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 32
    Top = 296
    Width = 353
    Height = 209
    Pen.Width = 2
    Shape = stRoundRect
  end
  object EVCOMBO: TComboBox
    Left = 96
    Top = 96
    Width = 73
    Height = 32
    Cursor = crHandPoint
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 0
    OnChange = EVCOMBOChange
    OnClick = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 168
    Top = 96
    Width = 161
    Height = 31
    Cursor = crHandPoint
    DropDownCount = 12
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 1
    OnChange = EVCOMBOChange
    OnClick = EVCOMBOChange
  end
  object Memo: TMemo
    Left = 48
    Top = 312
    Width = 321
    Height = 177
    BorderStyle = bsNone
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object STARTGOMB: TBitBtn
    Left = 128
    Top = 168
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'STARTGOMB'
    TabOrder = 3
    OnClick = STARTGOMBClick
  end
  object KILEPGOMB: TBitBtn
    Left = 128
    Top = 200
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 4
    OnClick = KILEPGOMBClick
  end
  object NAPCSUSZKA: TProgressBar
    Left = 48
    Top = 272
    Width = 337
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 5
    Visible = False
  end
  object IRODACSUSZKA: TProgressBar
    Left = 48
    Top = 248
    Width = 337
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 6
    Visible = False
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 456
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 80
    Top = 456
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V9.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 112
    Top = 456
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 144
    Top = 456
  end
  object recquery: TIBQuery
    Database = recdbase
    Transaction = rectranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 392
  end
  object recdbase: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = rectranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 392
  end
  object rectranz: TIBTransaction
    Active = False
    DefaultDatabase = recdbase
    AutoStopAction = saNone
    Left = 120
    Top = 392
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 280
    Top = 384
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 248
    Top = 384
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 216
    Top = 384
  end
end
