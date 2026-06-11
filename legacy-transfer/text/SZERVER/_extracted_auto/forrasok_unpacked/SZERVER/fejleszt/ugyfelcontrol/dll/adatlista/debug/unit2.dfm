object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 601
  ClientWidth = 854
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
  object RADIOPANEL: TPanel
    Left = 280
    Top = 120
    Width = 481
    Height = 41
    BevelOuter = bvNone
    Color = clSilver
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 481
      Height = 41
      Align = alClient
      Brush.Color = 13697023
    end
    object KFTRADIO: TRadioButton
      Left = 24
      Top = 12
      Width = 113
      Height = 17
      Caption = 'KFT szerint'
      Color = 13697023
      ParentColor = False
      TabOrder = 0
      OnClick = KFTRADIOClick
    end
    object KORZETRADIO: TRadioButton
      Left = 176
      Top = 12
      Width = 113
      Height = 17
      Caption = 'K'#246'rzet szerint'
      Color = 13697023
      ParentColor = False
      TabOrder = 1
      OnClick = KORZETRADIOClick
    end
    object PENZTARRADIO: TRadioButton
      Left = 320
      Top = 12
      Width = 153
      Height = 17
      Caption = 'P'#233'nzt'#225'r szerint'
      Color = 13697023
      ParentColor = False
      TabOrder = 2
      OnClick = PenztarRadioClick
    end
  end
  object PTMEGSEMGOMB: TBitBtn
    Left = -1989
    Top = 232
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    Visible = False
    OnClick = PtMegsemGombClick
  end
  object PENZTARCOMBO: TComboBox
    Left = -1989
    Top = 288
    Width = 321
    Height = 25
    DropDownCount = 18
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ItemHeight = 17
    ParentFont = False
    TabOrder = 2
    Visible = False
    OnChange = PenztarComboChange
  end
  object KORZETCOMBO: TComboBox
    Left = -1999
    Top = 224
    Width = 321
    Height = 31
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ItemHeight = 23
    ParentFont = False
    TabOrder = 3
    OnChange = KORZETCOMBOChange
  end
  object KORZETOKEGOMB: TBitBtn
    Left = -888
    Top = 312
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'RENDBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    Visible = False
    OnClick = KORZETOKEGOMBClick
  end
  object KFTOKEGOMB: TBitBtn
    Left = -789
    Top = 248
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'EGYS'#201'G RENDBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    Visible = False
    OnClick = KFTOKEGOMBClick
  end
  object FOCIMALAP: TPanel
    Left = -1897
    Top = 144
    Width = 549
    Height = 35
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 6
    Visible = False
    object FOCIMPANEL: TPanel
      Left = 2
      Top = 2
      Width = 545
      Height = 31
      Caption = 'FOCIMPANEL'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object KFTPANEL: TPanel
    Left = -1897
    Top = 272
    Width = 321
    Height = 33
    BevelOuter = bvNone
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 7
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 321
      Height = 33
      Align = alClient
      Brush.Color = clYellow
    end
    object RBEST: TRadioButton
      Left = 24
      Top = 8
      Width = 73
      Height = 17
      Caption = 'BEST'
      Color = clYellow
      ParentColor = False
      TabOrder = 0
      OnClick = RBESTClick
    end
    object REXPRESSZ: TRadioButton
      Left = 88
      Top = 8
      Width = 105
      Height = 17
      Caption = 'EXPRESSZ'
      Color = clYellow
      ParentColor = False
      TabOrder = 1
      OnClick = RBESTClick
    end
    object RALL: TRadioButton
      Left = 200
      Top = 8
      Width = 113
      Height = 17
      Caption = 'TELJES C'#201'G'
      Color = clYellow
      ParentColor = False
      TabOrder = 2
      OnClick = RBESTClick
    end
  end
  object PTOKEGOMB: TBitBtn
    Left = -955
    Top = 352
    Width = 153
    Height = 25
    Cursor = crHandPoint
    Caption = 'RENDBEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 8
    Visible = False
    OnClick = PTokeGombClick
  end
  object KERTDATUMPANEL: TPanel
    Left = -1897
    Top = 432
    Width = 481
    Height = 41
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 9
    Visible = False
    object Label1: TLabel
      Left = 16
      Top = 12
      Width = 186
      Height = 18
      Caption = 'V'#193'LASZTOTT ID'#336'SZAK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object KERTDATUMSPANEL: TPanel
      Left = 222
      Top = 2
      Width = 257
      Height = 37
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
  end
  object RADIOCIMPANEL: TPanel
    Left = -1999
    Top = 92
    Width = 481
    Height = 25
    BevelOuter = bvNone
    Caption = 'MELYIK EGYS'#201'G SZERINT V'#193'LOGASSAK'
    Color = clLime
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 10
    Visible = False
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 184
    Top = 56
  end
  object BIZLATOKQUERY: TIBQuery
    Database = BIZLATOKDBASE
    Transaction = BIZLATOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 312
    Top = 56
  end
  object BIZLATOKDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZLATOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 352
    Top = 56
  end
  object BIZLATOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZLATOKDBASE
    AutoStopAction = saNone
    Left = 392
    Top = 56
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 488
    Top = 40
  end
  object RECDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 520
    Top = 40
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    AutoStopAction = saNone
    Left = 552
    Top = 40
  end
end
