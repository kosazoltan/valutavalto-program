object Form1: TForm1
  Left = 449
  Top = 189
  Width = 390
  Height = 553
  Caption = 'Hi'#225'nyz'#243' '#252'gyfelek '#233's tranzakci'#243'k keres'#233'sese'
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
    Width = 374
    Height = 514
    Align = alClient
    Brush.Color = clMoneyGreen
    Pen.Color = clRed
    Pen.Width = 2
  end
  object Label1: TLabel
    Left = 48
    Top = 8
    Width = 289
    Height = 18
    Caption = 'A HI'#193'NYZ'#211'  PLOMB'#193'K LEGY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 142
    Top = 28
    Width = 11
    Height = 37
    Caption = '-'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 296
    Top = 42
    Width = 48
    Height = 19
    Caption = 'k'#246'z'#246'tt'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 208
    Top = 80
    Width = 113
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 0
    OnClick = BitBtn2Click
  end
  object STARTGOMB: TBitBtn
    Left = 72
    Top = 80
    Width = 121
    Height = 25
    Cursor = crHandPoint
    Caption = 'GY'#220'JT'#201'S INDUL'
    TabOrder = 1
    OnClick = StartGombClick
  end
  object Memo1: TMemo
    Left = 32
    Top = 112
    Width = 313
    Height = 369
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object TOLEVCOMBO: TComboBox
    Left = 8
    Top = 40
    Width = 51
    Height = 21
    ItemHeight = 13
    TabOrder = 3
    Text = ' '
    OnChange = TOLEVCOMBOChange
  end
  object TOLHOCOMBO: TComboBox
    Left = 56
    Top = 40
    Width = 81
    Height = 21
    DropDownCount = 12
    ItemHeight = 13
    TabOrder = 4
    Text = ' '
    OnChange = TOLEVCOMBOChange
  end
  object IGEVCOMBO: TComboBox
    Left = 160
    Top = 40
    Width = 51
    Height = 21
    ItemHeight = 13
    TabOrder = 5
    Text = ' '
    OnChange = TOLEVCOMBOChange
  end
  object IGHOCOMBO: TComboBox
    Left = 208
    Top = 40
    Width = 81
    Height = 21
    DropDownCount = 12
    ItemHeight = 13
    TabOrder = 6
    Text = ' '
    OnChange = TOLEVCOMBOChange
  end
  object VTABLA: TIBTable
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 112
  end
  object VQUERY: TIBQuery
    Database = VDBASE
    Transaction = VTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 152
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
    Left = 16
    Top = 192
  end
  object VTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VDBASE
    AutoStopAction = saNone
    Left = 16
    Top = 224
  end
  object GYQUERY: TIBQuery
    Database = GYDBASE
    Transaction = GYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 288
  end
  object GYDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\PGYUJTO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = GYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 320
  end
  object GYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = GYDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 16
    Top = 360
  end
end
