object GETARFOLYAM: TGETARFOLYAM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETARFOLYAM'
  ClientHeight = 54
  ClientWidth = 402
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
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 401
    Height = 81
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 374
    Height = 23
    Caption = 'ELSZ'#193'MOL'#193'SI '#193'RFOLYAM LET'#214'LT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object CHANGEPANEL: TPanel
    Left = -500
    Top = 16
    Width = 369
    Height = 281
    BevelOuter = bvNone
    Color = 10066329
    TabOrder = 0
    object Shape3: TShape
      Left = 104
      Top = 8
      Width = 153
      Height = 145
      Brush.Color = clRed
      Pen.Width = 2
      Shape = stCircle
    end
    object Label4: TLabel
      Left = 8
      Top = 64
      Width = 343
      Height = 24
      Caption = #193'RFOLYAMV'#193'LTOZ'#193'S T'#214'RT'#201'NT !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object changebox: TListBox
      Left = 0
      Top = 160
      Width = 369
      Height = 129
      Color = 11599871
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Courier New'
      Font.Style = [fsBold]
      ItemHeight = 22
      Items.Strings = (
        '')
      ParentFont = False
      TabOrder = 0
    end
    object CHANGEGOMB: TBitBtn
      Left = 136
      Top = 96
      Width = 97
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'Rendben'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 112
  end
  object InditoTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = INDITOTIMERTimer
    Left = 8
    Top = 8
  end
end
