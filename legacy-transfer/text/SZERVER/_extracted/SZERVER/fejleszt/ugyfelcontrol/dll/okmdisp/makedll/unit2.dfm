object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 537
  ClientWidth = 976
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
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 0
    Width = 505
    Height = 537
    Color = clSilver
    ParentColor = False
    TabOrder = 0
    object IMAGEPANEL: TPanel
      Left = 0
      Top = 0
      Width = 497
      Height = 530
      BevelOuter = bvNone
      TabOrder = 0
      object VETITO: TImage
        Left = 0
        Top = 0
        Width = 497
        Height = 530
        Align = alClient
        Stretch = True
      end
    end
  end
  object OKMANYPANEL: TPanel
    Left = 505
    Top = -8
    Width = 470
    Height = 537
    BevelOuter = bvNone
    Color = clSkyBlue
    TabOrder = 1
    object Label1: TLabel
      Left = 96
      Top = 32
      Width = 333
      Height = 31
      Caption = 'V'#193'LASZTOTT '#220'GYF'#201'L'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object TOTALKEPGOMB: TBitBtn
      Left = 144
      Top = 400
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'NAGYITOTT K'#201'P'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 9
      OnClick = TOTALKEPGOMBClick
    end
    object OKMNEVPANEL: TPanel
      Left = 32
      Top = 88
      Width = 420
      Height = 41
      BevelOuter = bvNone
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object OKMCIMPANEL: TPanel
      Left = 32
      Top = 136
      Width = 420
      Height = 41
      BevelOuter = bvNone
      Color = clMoneyGreen
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object INFOPANEL: TPanel
      Left = 32
      Top = 184
      Width = 420
      Height = 41
      BevelOuter = bvNone
      Caption = 'ELK'#220'LDTEM A K'#201'R'#201'ST A SZERVERRE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Stencil'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
    end
    object CSIK: TProgressBar
      Left = 32
      Top = 240
      Width = 417
      Height = 17
      Min = 0
      Max = 100
      Smooth = True
      TabOrder = 3
    end
    object VALASZPANEL: TPanel
      Left = 32
      Top = 272
      Width = 417
      Height = 41
      BevelOuter = bvNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object ELOOKMGOMB: TBitBtn
      Left = 64
      Top = 360
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'EL'#214'Z'#336' OKM'#193'NY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = ELOOKMGOMBClick
    end
    object KOVOKMGOMB: TBitBtn
      Left = 248
      Top = 360
      Width = 177
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'VETKEZ'#336' OKM'#193'NY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = KOVOKMGOMBClick
    end
    object GOMBTAKARO: TPanel
      Left = 32
      Top = 344
      Width = 409
      Height = 97
      BevelOuter = bvNone
      Color = clSkyBlue
      TabOrder = 5
    end
    object BACKGOMB: TBitBtn
      Left = 184
      Top = 480
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 8
      OnClick = BACKGOMBClick
    end
  end
  object RECQUERY: TIBQuery
    Database = RECDBASE
    Transaction = RECTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 24
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
    Left = 64
    Top = 24
  end
  object RECTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 24
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 136
    Top = 24
  end
  object BIZLATOKQUERY: TIBQuery
    Database = BIZLATOKDBASE
    Transaction = BIZLATOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 72
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
    Left = 64
    Top = 64
  end
  object BIZLATOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZLATOKDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 64
  end
end
