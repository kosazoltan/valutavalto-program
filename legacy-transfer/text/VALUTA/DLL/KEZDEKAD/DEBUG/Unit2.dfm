object KEZDDEKAD: TKEZDDEKAD
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KEZDDEKAD'
  ClientHeight = 366
  ClientWidth = 692
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
    Width = 692
    Height = 366
    Align = alClient
    Brush.Color = 13684944
    Pen.Color = clRed
    Pen.Width = 4
  end
  object Shape1: TShape
    Left = 152
    Top = 96
    Width = 393
    Height = 105
  end
  object Label5: TLabel
    Left = 48
    Top = 16
    Width = 599
    Height = 33
    Caption = 'KEZEL'#201'SI K'#214'LTS'#201'GEK DEK'#193'D JELENT'#201'SE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label6: TLabel
    Left = 144
    Top = 56
    Width = 411
    Height = 31
    Caption = 'V'#225'lassza ki a nyomtatand'#243' dek'#225'dot !'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label7: TLabel
    Left = 200
    Top = 112
    Width = 33
    Height = 32
    Caption = #201'v'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label8: TLabel
    Left = 288
    Top = 112
    Width = 86
    Height = 32
    Caption = 'H'#243'nap'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label9: TLabel
    Left = 416
    Top = 112
    Width = 84
    Height = 32
    Caption = 'Dek'#225'd'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object DEKADCOMBO: TComboBox
    Left = 408
    Top = 152
    Width = 121
    Height = 27
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 0
    OnChange = EVCOMBOChange
  end
  object HOCOMBO: TComboBox
    Left = 256
    Top = 152
    Width = 153
    Height = 27
    Cursor = crHandPoint
    DropDownCount = 12
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 1
    OnChange = EVCOMBOChange
  end
  object EVCOMBO: TComboBox
    Left = 184
    Top = 152
    Width = 73
    Height = 27
    Cursor = crHandPoint
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ItemHeight = 19
    ParentFont = False
    TabOrder = 2
    OnChange = EVCOMBOChange
  end
  object VISSZAGOMB: TBitBtn
    Left = 368
    Top = 288
    Width = 225
    Height = 25
    Cursor = crHandPoint
    Caption = 'Vissza a f'#337'men'#369're'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = VISSZAGOMBClick
  end
  object DEKADPRINTGOMB: TBitBtn
    Left = 96
    Top = 288
    Width = 227
    Height = 25
    Cursor = crHandPoint
    Caption = 'Dek'#225'd kinyomtat'#225'sa'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = DEKADPRINTGOMBClick
  end
  object takaropanel: TPanel
    Left = 16
    Top = 280
    Width = 649
    Height = 49
    BevelOuter = bvNone
    Caption = 'Dek'#225'd nyomtat'#225'sa folyamatban ...'
    Color = 13684944
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -29
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object KILEPOTIMER: TTimer
    Enabled = False
    Interval = 200
    OnTimer = KILEPOTIMERTimer
    Left = 632
    Top = 88
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 656
    Top = 248
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 624
    Top = 248
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 592
    Top = 248
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 560
    Top = 216
  end
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 592
    Top = 216
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 624
    Top = 216
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 656
    Top = 216
  end
  object NAPLOQUERY: TIBQuery
    Database = NAPLODBASE
    Transaction = NAPLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 592
    Top = 184
  end
  object NAPLODBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\UJNAPLO.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = NAPLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 624
    Top = 184
  end
  object NAPLOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPLODBASE
    AutoStopAction = saNone
    Left = 656
    Top = 180
  end
end
