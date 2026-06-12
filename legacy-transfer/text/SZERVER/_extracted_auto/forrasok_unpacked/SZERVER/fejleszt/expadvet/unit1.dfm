object Form1: TForm1
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 523
  ClientWidth = 390
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
  object Shape3: TShape
    Left = 0
    Top = 0
    Width = 390
    Height = 523
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 275
    Height = 23
    Caption = 'EXPRESSZ '#201'KSZERH'#193'Z HAVI '
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 112
    Top = 40
    Width = 171
    Height = 21
    Caption = #193'TAD'#193'S-'#193'TV'#201'TELEI'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 72
    Top = 106
    Width = 249
    Height = 41
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label3: TLabel
    Left = 120
    Top = 80
    Width = 166
    Height = 19
    Caption = 'V'#193'LASSZ H'#211'NAPOT !'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 80
    Top = 200
    Width = 233
    Height = 241
    Brush.Color = 11599871
    Pen.Width = 2
    Shape = stRoundRect
  end
  object STARTGOMB: TBitBtn
    Left = 72
    Top = 160
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'GY'#220'JT'#201'S INDUL'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = STARTGOMBClick
  end
  object KILEPGOMB: TBitBtn
    Left = 72
    Top = 456
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = KILEPGOMBClick
  end
  object EVCOMBO: TComboBox
    Left = 80
    Top = 112
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
    TabOrder = 2
    Text = '2022'
  end
  object HOCOMBO: TComboBox
    Left = 152
    Top = 112
    Width = 161
    Height = 29
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ItemHeight = 21
    ParentFont = False
    TabOrder = 3
    Text = 'SZEPTEMBER'
    OnChange = HOCOMBOChange
  end
  object Memo: TMemo
    Left = 96
    Top = 216
    Width = 201
    Height = 209
    BorderStyle = bsNone
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object INFOTABLA: TPanel
    Left = 82
    Top = 330
    Width = 228
    Height = 70
    Color = clTeal
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    Visible = False
    object Label4: TLabel
      Left = 8
      Top = 8
      Width = 202
      Height = 13
      Caption = 'AZ EXCELT'#193'BLA MEGTAL'#193'LHAT'#211
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 80
      Top = 52
      Width = 50
      Height = 13
      Caption = 'HELYEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object EPATHPANEL: TPanel
      Left = 2
      Top = 25
      Width = 225
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 224
  end
  object ADVETQUERY: TIBQuery
    Database = ADVETDBASE
    Transaction = ADVETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 160
  end
  object VDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\V162.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 224
  end
  object ADVETDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\EXPADVET.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ADVETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 160
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 224
  end
  object ADVETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ADVETDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 160
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 224
  end
  object ADVETTABLA: TIBTable
    Database = ADVETDBASE
    Transaction = ADVETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 160
  end
  object VTETQUERY: TIBQuery
    Database = VTETDBASE
    Transaction = VTETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 128
  end
  object VTETDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VTETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 128
  end
  object VTETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VTETDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 128
  end
  object WUNITABLA: TIBTable
    Database = WUNIDBASE
    Transaction = WUNITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 192
  end
  object WUNIQUERY: TIBQuery
    Database = WUNIDBASE
    Transaction = WUNITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 192
  end
  object WUNITRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUNIDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 192
  end
  object WUNIDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySoft'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WUNITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 192
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KilepoTimer
    Left = 24
    Top = 72
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 264
  end
  object ARTDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 264
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 264
  end
end
