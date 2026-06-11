object Form1: TForm1
  Left = 327
  Top = 277
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 397
  ClientWidth = 674
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 32
    Top = 24
    Width = 624
    Height = 35
    Caption = 'AZ '#220'GYF'#201'LADATOK REGENER'#193'L'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object TASKMEMO: TMemo
    Left = 32
    Top = 112
    Width = 297
    Height = 257
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      'DUPLA BIZONYLATOK KIT'#214'RL'#201'SE')
    ParentFont = False
    TabOrder = 0
  end
  object partmemo: TMemo
    Left = 352
    Top = 112
    Width = 289
    Height = 257
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    Lines.Strings = (
      '')
    ParentFont = False
    TabOrder = 1
  end
  object Panel1: TPanel
    Left = 352
    Top = 72
    Width = 289
    Height = 33
    BevelOuter = bvNone
    Caption = 'R'#201'SZLETEK'
    Color = clNavy
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object Panel2: TPanel
    Left = 32
    Top = 72
    Width = 297
    Height = 33
    BevelOuter = bvNone
    Caption = 'FELADATOK'
    Color = clNavy
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
  end
  object BIZTABLA: TIBTable
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 8
  end
  object BIZQUERY: TIBQuery
    Database = BIZDBASE
    Transaction = BIZTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 8
  end
  object BIZDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 8
  end
  object BIZTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 8
  end
  object NEVQUERY: TIBQuery
    Database = NEVDBASE
    Transaction = NEVTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 40
  end
  object NEVDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NEVTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 40
  end
  object NEVTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NEVDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 40
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = KILEPOTimer
    Left = 104
    Top = 40
  end
end
