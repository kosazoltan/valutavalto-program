object Form1: TForm1
  Left = 178
  Top = 197
  BorderStyle = bsSingle
  Caption = 'ELEKTROMOS KERESKED'#201'S'
  ClientHeight = 466
  ClientWidth = 996
  Color = 7829367
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 996
    Height = 466
    Align = alClient
    Brush.Color = 7829367
    Pen.Color = clWhite
    Pen.Width = 2
  end
  object Label1: TLabel
    Left = 152
    Top = 80
    Width = 694
    Height = 36
    Caption = 'AZ E-KERESKEDELEM ADATAINAK GY'#220'JT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object IRODAQUERY: TIBQuery
    Database = IRODADBASE
    Transaction = IRODATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 184
  end
  object IRODADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IRODATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 184
  end
  object IRODATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IRODADBASE
    AutoStopAction = saNone
    Left = 104
    Top = 184
  end
  object ACQUERY: TIBQuery
    Database = ACDBASE
    Transaction = ACTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 224
  end
  object ACDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ACTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 224
  end
  object ACTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ACDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 224
  end
end
