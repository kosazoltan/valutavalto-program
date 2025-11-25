object Form1: TForm1
  Left = 372
  Top = 99
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 587
  ClientWidth = 395
  Color = 16311512
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape5: TShape
    Left = 0
    Top = 0
    Width = 395
    Height = 587
    Align = alClient
    Brush.Color = 16311512
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Shape4: TShape
    Left = 136
    Top = 540
    Width = 113
    Height = 30
    Shape = stEllipse
  end
  object Label1: TLabel
    Left = 48
    Top = 16
    Width = 294
    Height = 22
    Caption = 'Western Union havi forgalmi adatai.'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 48
    Top = 48
    Width = 281
    Height = 24
    Caption = 'K'#201'REM A K'#205'V'#193'NT H'#211'NAPOT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 66
    Top = 90
    Width = 252
    Height = 44
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 104
    Top = 152
    Width = 169
    Height = 73
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 16
    Top = 304
    Width = 361
    Height = 217
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label3: TLabel
    Left = 144
    Top = 544
    Width = 88
    Height = 22
    Caption = 'dekanySoft'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object STARTGOMB: TButton
    Left = 112
    Top = 162
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'START'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPGOMB: TButton
    Left = 112
    Top = 192
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = KILEPGOMBClick
  end
  object Memo: TMemo
    Left = 32
    Top = 320
    Width = 329
    Height = 192
    BorderStyle = bsNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object NAPCSUSZKA: TProgressBar
    Left = 24
    Top = 248
    Width = 337
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 3
    Visible = False
  end
  object IRODACSUSZKA: TProgressBar
    Left = 24
    Top = 272
    Width = 337
    Height = 17
    Min = 0
    Max = 100
    Smooth = True
    TabOrder = 4
    Visible = False
  end
  object EVCOMBO: TComboBox
    Left = 72
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
    TabOrder = 5
    Text = '2022'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 144
    Top = 96
    Width = 169
    Height = 31
    Cursor = crHandPoint
    DropDownCount = 12
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 6
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 352
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 56
    Top = 384
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 352
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\V4.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 384
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 352
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 384
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 248
    Top = 392
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
    Left = 280
    Top = 392
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 312
    Top = 392
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 392
  end
end
