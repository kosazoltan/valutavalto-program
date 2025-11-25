object Form1: TForm1
  Left = 192
  Top = 125
  Width = 870
  Height = 640
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 48
    Top = 16
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 48
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Button2'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 136
    Top = 120
    Width = 537
    Height = 41
    Caption = 'Panel1'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 136
    Top = 168
    Width = 529
    Height = 41
    Caption = 'Panel2'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object XQUERY: TIBQuery
    Database = XDBASE
    Transaction = XTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 232
    Top = 32
  end
  object XDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\UGYFEL20.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = XTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 272
    Top = 32
  end
  object XTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = XDBASE
    AutoStopAction = saNone
    Left = 312
    Top = 32
  end
end
