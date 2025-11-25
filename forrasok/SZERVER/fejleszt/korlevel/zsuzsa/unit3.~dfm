object READTIMEFORM: TREADTIMEFORM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'READTIMEFORM'
  ClientHeight = 606
  ClientWidth = 862
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
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 849
    Height = 585
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 0
    object Label1: TLabel
      Left = 56
      Top = 16
      Width = 189
      Height = 22
      Caption = 'DOLGOZ'#211'K LIST'#193'JA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 456
      Top = 16
      Width = 212
      Height = 22
      Caption = 'K'#214'RLEVELEK LIST'#193'JA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 32
      Top = 552
      Width = 228
      Height = 22
      Caption = 'A K'#214'RLEV'#201'L OLVAS'#193'SA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object DOLGOZOLISTA: TListBox
      Left = 32
      Top = 40
      Width = 233
      Height = 505
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = clSilver
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 0
      OnClick = DOLGOZOLISTAClick
      OnKeyDown = DOLGOZOLISTAKeyDown
    end
    object TARTALOMLISTA: TListBox
      Left = 280
      Top = 40
      Width = 545
      Height = 505
      BorderStyle = bsNone
      Color = clSilver
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 1
      OnClick = DOLGOZOLISTAClick
      OnKeyDown = DOLGOZOLISTAKeyDown
    end
    object visszagomb: TBitBtn
      Left = 688
      Top = 552
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 2
      OnClick = visszagombClick
    end
    object readedit: TEdit
      Left = 272
      Top = 552
      Width = 289
      Height = 29
      BorderStyle = bsNone
      Color = 4539717
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      ReadOnly = True
      TabOrder = 3
    end
  end
  object SIGNQUERY: TIBQuery
    Database = SIGNDBASE
    Transaction = SIGNTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 376
    Top = 16
  end
  object SIGNDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SIGNTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 408
    Top = 16
  end
  object SIGNTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SIGNDBASE
    AutoStopAction = saNone
    Left = 440
    Top = 16
  end
end
