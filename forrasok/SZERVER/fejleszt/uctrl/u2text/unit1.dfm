object Form1: TForm1
  Left = 334
  Top = 238
  Width = 691
  Height = 149
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 675
    Height = 110
    Align = alClient
  end
  object Label1: TLabel
    Left = 24
    Top = 16
    Width = 631
    Height = 23
    Caption = #220'GYFEL '#201'S JOGISZEM'#201'LY ADATB'#193'ZIS BEK'#220'LD'#201'SE A SZERVERRE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object startgomb: TBitBtn
    Left = 112
    Top = 56
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'PROGRAM INDUL'
    TabOrder = 0
    OnClick = startgombClick
  end
  object BitBtn2: TBitBtn
    Left = 344
    Top = 56
    Width = 217
    Height = 25
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 56
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 56
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 56
  end
end
