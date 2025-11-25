object Form1: TForm1
  Left = 192
  Top = 125
  Width = 813
  Height = 370
  Caption = 'Form1'
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
    Left = 32
    Top = 32
    Width = 161
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 592
    Top = 32
    Width = 163
    Height = 25
    Caption = 'KIL'#201'P'#201'S'
    TabOrder = 1
    OnClick = BitBtn2Click
  end
  object Memo2: TMemo
    Left = 272
    Top = 64
    Width = 489
    Height = 241
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 2
  end
  object Memo1: TMemo
    Left = 32
    Top = 64
    Width = 225
    Height = 241
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 3
  end
  object WUTABLA: TIBTable
    Database = WUDBASE
    Transaction = WUTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 56
  end
  object WUQUERY: TIBQuery
    Database = WUDBASE
    Transaction = WUTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 56
  end
  object WUDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySoft'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WUTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 56
  end
  object WUTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 56
  end
  object WZTABLA: TIBTable
    Database = WZDBASE
    Transaction = WZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 96
  end
  object WZQUERY: TIBQuery
    Database = WZDBASE
    Transaction = WZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 216
    Top = 96
  end
  object WZDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = WZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 256
    Top = 96
  end
  object WZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WZDBASE
    AutoStopAction = saNone
    Left = 296
    Top = 96
  end
end
