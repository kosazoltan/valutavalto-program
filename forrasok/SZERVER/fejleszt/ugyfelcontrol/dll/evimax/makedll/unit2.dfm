object Form2: TForm2
  Left = 411
  Top = 214
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 537
  ClientWidth = 1001
  Color = clBackground
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object munkapanel: TPanel
    Left = 200
    Top = 120
    Width = 617
    Height = 281
    BevelOuter = bvNone
    Color = clSilver
    TabOrder = 0
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 559
      Height = 24
      Caption = #201'VES '#201'RT'#201'KHAT'#193'R FELETTI '#220'GYFELEK LIST'#193'JA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 112
      Top = 72
      Width = 143
      Height = 21
      Caption = 'K'#233'rem a t'#225'rgy'#233'vet:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 88
      Top = 112
      Width = 165
      Height = 21
      Caption = 'K'#233'rem az '#233'rt'#233'khat'#225'rt:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 400
      Top = 110
      Width = 22
      Height = 27
      Caption = 'Ft'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object STARTGOMB: TBitBtn
      Left = 128
      Top = 216
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'LEGY'#220'JT'#201'S INDUL'
      Enabled = False
      TabOrder = 2
      OnClick = STARTGOMBClick
    end
    object EVEDIT: TEdit
      Left = 264
      Top = 68
      Width = 65
      Height = 32
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = ' '
      OnEnter = EVEDITEnter
      OnExit = EVEDITExit
      OnKeyDown = EVEDITKeyDown
    end
    object FORINTEDIT: TEdit
      Left = 264
      Top = 108
      Width = 137
      Height = 32
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = ' '
      OnEnter = EVEDITEnter
      OnExit = EVEDITExit
      OnKeyDown = FORINTEDITKeyDown
    end
    object VISSZAGOMB: TBitBtn
      Left = 312
      Top = 216
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
  end
  object GYUJTOPANEL: TPanel
    Left = -1988
    Top = 272
    Width = 617
    Height = 129
    BevelOuter = bvNone
    Caption = ' '
    Color = clGray
    TabOrder = 1
    Visible = False
    object Label5: TLabel
      Left = 200
      Top = 8
      Width = 189
      Height = 22
      Caption = 'ADATOK LEGY'#220'JT'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Stencil'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object CSIK: TProgressBar
      Left = 8
      Top = 96
      Width = 601
      Height = 17
      Min = 0
      Max = 26
      Smooth = True
      Step = 1
      TabOrder = 0
    end
    object NEVPANEL: TPanel
      Left = 8
      Top = 40
      Width = 593
      Height = 41
      BevelOuter = bvNone
      Color = clGray
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object ZAROPANEL: TPanel
    Left = -1987
    Top = 280
    Width = 377
    Height = 97
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 2
    Visible = False
    object ZAROGOMB: TBitBtn
      Left = 128
      Top = 32
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A MEN'#220'RE'
      TabOrder = 0
      OnClick = ZAROGOMBClick
    end
  end
  object BQUERY: TIBQuery
    Database = BDBASE
    Transaction = BTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 488
    Top = 80
  end
  object BDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 80
  end
  object BTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BDBASE
    AutoStopAction = saNone
    Left = 568
    Top = 80
  end
  object LQUERY: TIBQuery
    Database = LDBASE
    Transaction = LTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 488
    Top = 128
  end
  object LDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = LTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 128
  end
  object LTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = LDBASE
    AutoStopAction = saNone
    Left = 568
    Top = 128
  end
end
