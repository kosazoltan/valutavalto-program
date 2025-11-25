object Form1: TForm1
  Left = 192
  Top = 114
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
    Left = 40
    Top = 32
    Width = 209
    Height = 25
    Caption = 'ALLAMPOLG'#193'R V'#193'LASZT'#193'S'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 32
    Top = 104
    Width = 217
    Height = 25
    Caption = 'KILEP'#201'S'
    TabOrder = 1
    OnClick = Button2Click
  end
  object BitBtn1: TBitBtn
    Left = 40
    Top = 64
    Width = 209
    Height = 25
    Caption = 'ORSZ'#193'G V'#193'LASZT'#193'S'
    TabOrder = 2
    OnClick = BitBtn1Click
  end
  object Panel1: TPanel
    Left = 280
    Top = 32
    Width = 521
    Height = 57
    Caption = 'Panel1'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = ibtranz
    BufferChunks = 1000
    CachedUpdates = False
    Left = 280
    Top = 104
  end
  object IBDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ibtranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 320
    Top = 104
  end
  object ibtranz: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 360
    Top = 104
  end
end
