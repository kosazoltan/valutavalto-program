object Form1: TForm1
  Left = 487
  Top = 329
  Width = 379
  Height = 220
  Caption = 'AUT'#211'P'#193'LY'#193'K D'#205'JAK M'#211'DOS'#205'T'#193'SA ...'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 371
    Height = 186
    Align = alClient
    Brush.Color = 6710886
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 32
    Top = 16
    Width = 328
    Height = 24
    Caption = 'AUT'#211'P'#193'LYAD'#205'JAK M'#211'DOS'#205'T'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object BitBtn1: TBitBtn
    Left = 24
    Top = 80
    Width = 321
    Height = 25
    Cursor = crHandPoint
    Caption = 'D'#237'jak m'#243'dos'#237't'#225'sa'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 24
    Top = 120
    Width = 321
    Height = 25
    Cursor = crHandPoint
    Caption = 'Kil'#233'p'#233's'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 48
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\TRADE.GDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=masterkey'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 48
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 48
  end
end
