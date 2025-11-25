object CONFIRMFORM: TCONFIRMFORM
  Left = 394
  Top = 264
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = '                Tranzakci'#243' befejezve'
  ClientHeight = 262
  ClientWidth = 308
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
  object Label2: TLabel
    Left = 40
    Top = 160
    Width = 234
    Height = 22
    Caption = 'TRANZAKCI'#211' RENDBEN ?'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 308
    Height = 262
    Align = alClient
    Brush.Color = 16756991
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object KITOLPANEL: TPanel
    Left = 8
    Top = 72
    Width = 289
    Height = 33
    BevelOuter = bvNone
    Caption = ' '
    Color = 16756991
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object MENNYITPANEL: TPanel
    Left = 8
    Top = 112
    Width = 289
    Height = 33
    BevelOuter = bvNone
    Caption = ' '
    Color = 16756991
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
  end
  object IGENGOMB: TBitBtn
    Left = 40
    Top = 200
    Width = 107
    Height = 25
    Cursor = crHandPoint
    Caption = 'IGEN'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = IGENGOMBClick
  end
  object NEMGOMB: TBitBtn
    Left = 160
    Top = 200
    Width = 105
    Height = 25
    Cursor = crHandPoint
    Caption = 'NEM'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = NEMGOMBClick
  end
  object TRANSPANEL: TPanel
    Left = 8
    Top = 32
    Width = 289
    Height = 33
    BevelOuter = bvNone
    Caption = ' '
    Color = 16756991
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel1: TPanel
    Left = 32
    Top = 160
    Width = 257
    Height = 33
    BevelOuter = bvNone
    Caption = 'TRANZAKCI'#211' RENDBEN VAN ?'
    Color = 16756991
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clMaroon
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 16
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 8
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 136
    Top = 8
  end
end
