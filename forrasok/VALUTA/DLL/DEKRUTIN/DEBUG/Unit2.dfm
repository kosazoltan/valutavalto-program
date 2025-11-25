object DEKADRUTIN: TDEKADRUTIN
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'DEKADRUTIN'
  ClientHeight = 169
  ClientWidth = 606
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
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 606
    Height = 169
    Align = alClient
    Brush.Color = clMoneyGreen
    Brush.Style = bsDiagCross
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Label3: TLabel
    Left = 184
    Top = 24
    Width = 222
    Height = 37
    Caption = 'DEK'#193'DZ'#193'R'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object MEGSEMGOMB: TButton
    Left = 296
    Top = 120
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#201'GSEM'
    TabOrder = 0
    OnClick = MEGSEMGOMBClick
  end
  object EVCOMBO: TComboBox
    Left = 120
    Top = 72
    Width = 73
    Height = 32
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 24
    ParentFont = False
    TabOrder = 1
    Text = '2016'
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 192
    Top = 72
    Width = 161
    Height = 28
    DropDownCount = 12
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 2
    Text = 'SZEPTEMBER'
    OnChange = EVCOMBOChange
  end
  object DEKADCOMBO: TComboBox
    Left = 352
    Top = 72
    Width = 113
    Height = 28
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ItemHeight = 20
    ParentFont = False
    TabOrder = 3
    Text = '1. DEK'#193'D'
    OnChange = EVCOMBOChange
  end
  object DEKADOKEGOMB: TBitBtn
    Left = 128
    Top = 120
    Width = 161
    Height = 25
    Cursor = crHandPoint
    Caption = 'NYOMTAT'#193'S'
    TabOrder = 4
    OnClick = DEKADOKEGOMBClick
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 40
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 40
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 560
    Top = 40
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 72
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 72
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 560
    Top = 72
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 464
    Top = 72
  end
  object NAPLOQUERY: TIBQuery
    Database = NAPLODBASE
    Transaction = NAPLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 496
    Top = 8
  end
  object NAPLODBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\ujnaplo.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NAPLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 528
    Top = 8
  end
  object NAPLOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPLODBASE
    AutoStopAction = saNone
    Left = 560
    Top = 8
  end
end
