object GETARFOLYAM: TGETARFOLYAM
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'GETARFOLYAM'
  ClientHeight = 318
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
    Height = 313
    Brush.Color = 10066329
    Pen.Color = clWhite
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 24
    Width = 340
    Height = 28
    Caption = #193'RFOLYAMOK ELLEN'#336'RZ'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object MEMOTABLA: TMemo
    Left = 32
    Top = 72
    Width = 337
    Height = 177
    BorderStyle = bsNone
    Color = 10066329
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 0
  end
  object NOCHANGEPANEL: TPanel
    Left = 16
    Top = 64
    Width = 361
    Height = 225
    BevelOuter = bvNone
    Color = 10066329
    TabOrder = 1
    object Shape1: TShape
      Left = 80
      Top = 8
      Width = 209
      Height = 209
      Brush.Color = clLime
      Pen.Width = 2
      Shape = stCircle
    end
    object Label2: TLabel
      Left = 144
      Top = 48
      Width = 93
      Height = 31
      Caption = 'Nem volt'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 96
      Top = 88
      Width = 178
      Height = 31
      Caption = #225'rfolyamv'#225'ltoz'#225's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object NochangeGomb: TBitBtn
      Left = 128
      Top = 152
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'RENDBEN'
      Default = True
      DragCursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = NochangeGombClick
    end
  end
  object CHANGEPANEL: TPanel
    Left = -500
    Top = 16
    Width = 369
    Height = 281
    BevelOuter = bvNone
    Color = 10066329
    TabOrder = 2
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
      OnClick = CHANGEGOMBClick
    end
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 344
    Top = 184
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 344
    Top = 224
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 344
    Top = 256
  end
  object InditoTimer: TTimer
    Enabled = False
    Interval = 250
    OnTimer = INDITOTIMERTimer
    Left = 24
    Top = 264
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 30000
    OnTimer = KILEPOTimer
    Left = 64
    Top = 264
  end
end
