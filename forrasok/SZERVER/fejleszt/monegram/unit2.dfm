object NYULEXCEL: TNYULEXCEL
  Left = 192
  Top = 124
  Width = 291
  Height = 97
  Caption = 'NYULEXCEL'
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
  object BitBtn1: TBitBtn
    Left = 56
    Top = 16
    Width = 169
    Height = 25
    Caption = 'VISSZA '
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object takaro: TPanel
    Left = -136
    Top = -8
    Width = 273
    Height = 57
    TabOrder = 1
    object Label1: TLabel
      Left = 40
      Top = 16
      Width = 188
      Height = 22
      Caption = 'EXCEL K'#201'SZIT'#201'SE ..'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object MQUERY: TIBQuery
    Database = MDBASE
    Transaction = MTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 24
  end
  object MDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\MONEGRAM.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = MTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 24
  end
  object MTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = MDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 24
  end
end
