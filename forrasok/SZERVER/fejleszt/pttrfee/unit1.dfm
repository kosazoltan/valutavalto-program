object Form1: TForm1
  Left = 464
  Top = 286
  AlphaBlend = True
  AlphaBlendValue = 200
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 266
  ClientWidth = 452
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
    Width = 452
    Height = 266
    Align = alClient
    Brush.Color = 6710886
    Pen.Color = clYellow
    Pen.Width = 4
  end
  object Label1: TLabel
    Left = 24
    Top = 24
    Width = 407
    Height = 33
    Caption = 'HAVI TRANZAKCI'#211' DIJAK LIST'#193'JA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -29
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 104
    Top = 80
    Width = 257
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 24
    Top = 152
    Width = 393
    Height = 41
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 168
    Top = 224
    Width = 105
    Height = 33
    Brush.Color = 10526880
    Pen.Width = 2
    Shape = stEllipse
  end
  object Label2: TLabel
    Left = 184
    Top = 230
    Width = 74
    Height = 19
    Caption = 'dekanySoft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object EVCOMBO: TComboBox
    Left = 112
    Top = 88
    Width = 81
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 0
    Text = '2013'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 192
    Top = 88
    Width = 161
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 1
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object HOOKEGOMB: TBitBtn
    Left = 32
    Top = 160
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'H'#211'NAP RENDBEN'
    TabOrder = 2
    OnClick = HOOKEGOMBClick
  end
  object KILEPESGOMB: TBitBtn
    Left = 224
    Top = 160
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 3
    OnClick = KILEPESGOMBClick
  end
  object takaropanel: TPanel
    Left = 314
    Top = 70
    Width = 431
    Height = 155
    BevelOuter = bvNone
    Color = 6710886
    TabOrder = 4
    Visible = False
    object gomb: TBitBtn
      Left = 104
      Top = 64
      Width = 209
      Height = 33
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = KILEPESGOMBClick
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 40
  end
  object RECDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 8
    Top = 72
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 8
    Top = 104
  end
  object TDTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TDDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 104
  end
  object TDDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\TRANZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TDTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 72
  end
  object TDQUERY: TIBQuery
    Database = TDDBASE
    Transaction = TDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 40
  end
  object TDTABLA: TIBTable
    Database = TDDBASE
    Transaction = TDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 8
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 250
    OnTimer = KILEPOTIMERTimer
    Left = 8
    Top = 8
  end
  object KDQUERY: TIBQuery
    Database = KDDBASE
    Transaction = KDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 224
  end
  object KDDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\KEZDIJ.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = KDTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 224
  end
  object KDTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KDDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 224
  end
  object kdtabla: TIBTable
    Database = KDDBASE
    Transaction = KDTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 104
    Top = 224
  end
end
