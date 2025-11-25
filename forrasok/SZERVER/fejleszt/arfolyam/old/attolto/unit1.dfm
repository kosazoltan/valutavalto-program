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
  object BitBtn1: TBitBtn
    Left = 32
    Top = 32
    Width = 75
    Height = 25
    Caption = 'INDUL'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 32
    Top = 64
    Width = 75
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo1: TMemo
    Left = 184
    Top = 128
    Width = 481
    Height = 369
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
  end
  object ARFQUERY: TIBQuery
    Database = ARFDBASE
    Transaction = ARFTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 184
    Top = 48
  end
  object ARFDBASE: TIBDatabase
    DatabaseName = 'C:\_ARFOLYAM\DATABASE\ARFOLYAM.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARFTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 232
    Top = 48
  end
  object ARFTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFDBASE
    AutoStopAction = saNone
    Left = 280
    Top = 48
  end
end
