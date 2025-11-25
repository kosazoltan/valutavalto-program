object MAKEIMPORT: TMAKEIMPORT
  Left = 192
  Top = 114
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'Egy napi import '#225'llom'#225'ny '#246'ssze'#225'llit'#225'sa ....'
  ClientHeight = 531
  ClientWidth = 749
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormCreate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 1
    Top = 0
    Width = 750
    Height = 538
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 0
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 750
      Height = 530
      Brush.Color = 170
      Pen.Color = 11579647
      Pen.Width = 8
    end
    object Shape1: TShape
      Left = 88
      Top = 96
      Width = 577
      Height = 385
      Brush.Color = 11579647
      Pen.Width = 3
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 184
      Top = 112
      Width = 404
      Height = 31
      Caption = 'IMPORT FILE '#214'SSZE'#193'LLIT'#193'SA '
      Color = 12040119
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
      Transparent = True
    end
    object Shape2: TShape
      Left = 130
      Top = 196
      Width = 470
      Height = 33
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label2: TLabel
      Left = 256
      Top = 16
      Width = 234
      Height = 73
      Caption = 'IMPORT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -64
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape5: TShape
      Left = 120
      Top = 272
      Width = 65
      Height = 65
    end
    object EVKOMBO: TComboBox
      Left = 136
      Top = 160
      Width = 65
      Height = 29
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 0
      Text = '2007'
      OnChange = EVKOMBOChange
    end
    object HOKOMBO: TComboBox
      Left = 200
      Top = 160
      Width = 161
      Height = 29
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = HOKOMBOChange
    end
    object NAPKOMBO: TComboBox
      Left = 358
      Top = 160
      Width = 52
      Height = 29
      Cursor = crHandPoint
      DropDownCount = 16
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 21
      ParentFont = False
      TabOrder = 2
      Text = '31'
      OnChange = NAPKOMBOChange
    end
    object IMPORTGO: TBitBtn
      Left = 136
      Top = 200
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'IMPORT FILE '#214'SSZE'#193'LL'#205'T'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = IMPORTGOClick
    end
    object IMPORTCANCEL: TBitBtn
      Left = 368
      Top = 200
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S AZ IMPORT K'#201'SZIT'#201'SB'#336'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = IMPORTCANCELClick
    end
    object uzeno: TMemo
      Left = 112
      Top = 240
      Width = 545
      Height = 217
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = 11579647
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Lines.Strings = (
        '')
      ParentFont = False
      TabOrder = 5
    end
    object NAPNEVPANEL: TPanel
      Left = 416
      Top = 162
      Width = 185
      Height = 25
      Caption = 'CS'#220'T'#214'RT'#214'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 6
    end
    object EXCELPRINTGOMB: TBitBtn
      Left = 136
      Top = 304
      Width = 227
      Height = 25
      Cursor = crHandPoint
      Caption = 'EXCELT'#193'BL'#193'K KINYOMTAT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clTeal
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = EXCELPRINTGOMBClick
    end
    object BACKTOMENUGOMB: TBitBtn
      Left = 376
      Top = 304
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
      OnClick = BACKTOMENUGOMBClick
    end
  end
  object PRINTMENUPANEL: TPanel
    Left = 136
    Top = 296
    Width = 233
    Height = 121
    BevelOuter = bvNone
    Color = 11579647
    TabOrder = 1
    object Shape4: TShape
      Left = 8
      Top = 8
      Width = 209
      Height = 105
      Pen.Width = 2
      Shape = stRoundRect
    end
    object BitBtn1: TBitBtn
      Left = 16
      Top = 16
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEST CHANGE'
      TabOrder = 0
      OnClick = BitBtn1Click
    end
    object BitBtn2: TBitBtn
      Tag = 1
      Left = 16
      Top = 48
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'PANNON CHANGE'
      TabOrder = 1
      OnClick = BitBtn1Click
    end
    object BitBtn3: TBitBtn
      Tag = 2
      Left = 16
      Top = 80
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'EAST CHANGE'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
  end
  object SALLOMANYTABLA: TIBTable
    Database = SALLOMANYDBASE
    Transaction = SALLOMANYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'SUMALLOMANY'
    Left = 40
    Top = 288
  end
  object SALLOMANYDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = SALLOMANYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 320
  end
  object SALLOMANYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SALLOMANYDBASE
    AutoStopAction = saNone
    Left = 40
    Top = 352
  end
  object SBANKFORGTABLA: TIBTable
    Database = SBANKFORGDBASE
    Transaction = SBANKFORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'SUMBANKFORGALOM'
    Left = 40
    Top = 128
  end
  object SBANKFORGDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = SBANKFORGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 160
  end
  object SBANKFORGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SBANKFORGDBASE
    AutoStopAction = saNone
    Left = 40
    Top = 192
  end
  object BLOKKFEJTABLA: TIBTable
    Database = BLOKKFEJDBASE
    Transaction = BLOKKFEJTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 280
  end
  object BLOKKFEJDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKFEJTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 280
  end
  object BLOKKFEJTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKFEJDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 280
  end
  object BLOKKTETELTABLA: TIBTable
    Database = BLOKKTETELDBASE
    Transaction = BLOKKTETELTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 312
  end
  object BLOKKTETELDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTETELTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 312
  end
  object BLOKKTETELTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKTETELDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 312
  end
  object CIMTARTABLA: TIBTable
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 344
  end
  object CIMTARDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = CIMTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 344
  end
  object CIMTARTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = CIMTARDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 344
  end
  object DAYBOOKTABLA: TIBTable
    Database = DAYBOOKDBASE
    Transaction = DAYBOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 248
  end
  object DAYBOOKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\DAYBOOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = DAYBOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 248
  end
  object DAYBOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DAYBOOKDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 248
  end
  object SUGYFELFORGTABLA: TIBTable
    Database = SUGYFELFORGDBASE
    Transaction = SUGYFELFORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'SUMUGYFELFORGALOM'
    Left = 680
    Top = 176
  end
  object SUGYFELFORGDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = SUGYFELFORGTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 680
    Top = 240
  end
  object SUGYFELFORGTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SUGYFELFORGDBASE
    AutoStopAction = saNone
    Left = 680
    Top = 272
  end
  object CimtarQuery: TIBQuery
    Database = CIMTARDBASE
    Transaction = CIMTARTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 272
    Top = 344
  end
  object SUGYFELFORGQUERY: TIBQuery
    Database = SUGYFELFORGDBASE
    Transaction = SUGYFELFORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
    Top = 208
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 352
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 504
    Top = 352
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 536
    Top = 352
  end
  object BLOKKTABLA: TIBTable
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
    Top = 320
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 680
    Top = 384
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 680
    Top = 352
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 680
    Top = 416
  end
  object SBANKFORGQUERY: TIBQuery
    Database = SBANKFORGDBASE
    Transaction = SBANKFORGTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 96
  end
  object PrintDialog1: TPrintDialog
    Left = 672
    Top = 32
  end
end
