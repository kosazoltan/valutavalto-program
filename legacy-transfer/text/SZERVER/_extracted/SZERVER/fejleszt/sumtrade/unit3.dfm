object MEXCEL: TMEXCEL
  Left = 237
  Top = 393
  BorderStyle = bsNone
  Caption = 'MEXCEL'
  ClientHeight = 105
  ClientWidth = 866
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 280
    Top = 35
    Width = 297
    Height = 33
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A KEZD'#336'LAPRA'
    Default = True
    TabOrder = 0
    OnClick = Button1Click
  end
  object MESSPANEL: TPanel
    Left = 0
    Top = 0
    Width = 857
    Height = 97
    BevelOuter = bvNone
    Caption = 'Excelt'#225'bla k'#233'sz'#237't'#233'se folyamatban ...'
    Color = clSilver
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object SMQUERY: TIBQuery
    Database = SMDBASE
    Transaction = SMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 24
  end
  object SMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 24
  end
  object SMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SMDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 24
  end
end
