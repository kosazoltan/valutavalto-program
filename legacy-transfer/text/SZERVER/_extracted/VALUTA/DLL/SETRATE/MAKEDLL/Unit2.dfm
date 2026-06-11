object SETRATETYPE: TSETRATETYPE
  Left = 463
  Top = 192
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'SETRATETYPE'
  ClientHeight = 238
  ClientWidth = 376
  Color = clRed
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
    Left = 4
    Top = 4
    Width = 368
    Height = 229
    Color = clWhite
    TabOrder = 0
    object Label1: TLabel
      Left = 32
      Top = 8
      Width = 306
      Height = 28
      Caption = #193'RFOLYAMV'#193'LTOZTAT'#193'S '
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 128
      Top = 32
      Width = 92
      Height = 28
      Caption = 'INDOKA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object GOMB3: TBitBtn
      Tag = 30
      Left = 4
      Top = 128
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGYEDI  '#193'RFOLYAM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = GOMB3Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
    object GOMB4: TBitBtn
      Tag = 34
      Left = 4
      Top = 168
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = 'JUTAL'#201'K N'#201'LK'#220'LI '#220'GYVEZET'#336'I'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = GOMB4Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
    object GOMB11: TBitBtn
      Tag = 11
      Left = 4
      Top = 88
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = 'VIP K'#193'RTYA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = GOMB1Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
  end
  object Panel2: TPanel
    Left = 4
    Top = 163
    Width = 368
    Height = 185
    Color = clWhite
    TabOrder = 1
    object Label3: TLabel
      Left = 96
      Top = 16
      Width = 177
      Height = 28
      Caption = 'ENGED'#201'LYEZ'#336
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object GOMB5: TBitBtn
      Tag = 31
      Left = 4
      Top = 64
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYVEZET'#336
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = GOMB5Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
    object GOMB6: TBitBtn
      Tag = 32
      Left = 4
      Top = 104
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = 'F'#336#201'RT'#201'KT'#193'ROS'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = GOMB6Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
    object GOMB7: TBitBtn
      Tag = 33
      Left = 4
      Top = 144
      Width = 357
      Height = 25
      Cursor = crHandPoint
      Caption = #201'RT'#201'KT'#193'ROS'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = GOMB7Click
      OnEnter = GOMB1Enter
      OnExit = GOMB1Exit
      OnMouseMove = GOMB1MouseMove
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = valutatranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 40
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = valutatranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 40
  end
  object valutatranz: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 72
    Top = 40
  end
end
