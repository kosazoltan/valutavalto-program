object QUITFORM: TQUITFORM
  Left = 310
  Top = 480
  BorderStyle = bsNone
  Caption = 'QUITFORM'
  ClientHeight = 100
  ClientWidth = 420
  Color = clBlack
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
    Left = 0
    Top = 0
    Width = 420
    Height = 100
    BevelOuter = bvNone
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object KERDOPANEL: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 100
    BevelOuter = bvNone
    Color = clBlack
    TabOrder = 1
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 420
      Height = 100
      Align = alClient
      Brush.Color = clRed
      Pen.Color = clCream
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 32
      Top = 16
      Width = 355
      Height = 24
      Caption = 'HOLNAP NYITVA LESZ A P'#201'NZT'#193'R ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object NYITVAGOMB: TBitBtn
      Left = 56
      Top = 56
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN, NYITVA  LESZ'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = NYITVAGOMBClick
    end
    object ZARVAGOMB: TBitBtn
      Left = 218
      Top = 58
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM, Z'#193'RVA LESZ'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = ZARVAGOMBClick
    end
  end
  object QUITPANEL: TPanel
    Left = 0
    Top = 0
    Width = 420
    Height = 100
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clBlack
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 420
      Height = 100
      Align = alClient
      Brush.Color = clRed
      Pen.Color = clCream
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 24
      Top = 24
      Width = 396
      Height = 22
      Caption = 'BIZTOS, HOGY KIL'#201'P NAPZ'#193'R'#193'S N'#201'LK'#220'L ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object QUITGOMB: TBitBtn
      Left = 48
      Top = 56
      Width = 163
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'PEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = QUITGOMBClick
    end
    object NONQUITGOMB: TBitBtn
      Left = 216
      Top = 56
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'G NEM L'#201'PEK KI'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NONQUITGOMBClick
    end
  end
  object QUITTIMER: TTimer
    Enabled = False
    Interval = 50
    OnTimer = QUITTIMERTimer
    Left = 144
    Top = 8
  end
  object VALTABLA: TIBTable
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'HARDWARE'
    Left = 16
    Top = 8
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 8
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 112
    Top = 8
  end
end
