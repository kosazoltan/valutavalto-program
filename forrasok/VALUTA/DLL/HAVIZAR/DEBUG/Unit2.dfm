object HAVIZARAS: THAVIZARAS
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'HAVIZARAS'
  ClientHeight = 263
  ClientWidth = 516
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
  object menupanel: TPanel
    Left = 0
    Top = 0
    Width = 513
    Height = 257
    BevelOuter = bvNone
    TabOrder = 0
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 513
      Height = 257
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label1: TLabel
      Left = 32
      Top = 24
      Width = 456
      Height = 36
      Caption = 'HAVI Z'#193'R'#193'S LEBONYOL'#205'T'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 170
      Top = 68
      Width = 6
      Height = 21
      Caption = '('
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object EVCOMBO: TComboBox
      Left = 112
      Top = 112
      Width = 105
      Height = 40
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 32
      ParentFont = False
      TabOrder = 0
      Text = '2016'
      OnChange = EVCOMBOChange
    end
    object HOCOMBO: TComboBox
      Left = 216
      Top = 112
      Width = 225
      Height = 40
      DropDownCount = 12
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = []
      ItemHeight = 32
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
      OnChange = EVCOMBOChange
    end
    object HOOKEGOMB: TBitBtn
      Left = 96
      Top = 192
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'HAVIZ'#193'R'#193'S INDUL'
      TabOrder = 2
      OnClick = HOOKEGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 264
      Top = 192
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = MEGSEMGOMBClick
    end
    object NOPRINTBOX: TCheckBox
      Left = 184
      Top = 72
      Width = 161
      Height = 17
      Caption = 'Nyomtat'#225's n'#233'lk'#252'l)'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
      TabOrder = 4
    end
    object takaro: TPanel
      Left = -1500
      Top = 104
      Width = 497
      Height = 129
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 5
      object FASTCSIK: TProgressBar
        Left = 32
        Top = 64
        Width = 449
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 0
      end
      object SLOWCSIK: TProgressBar
        Left = 32
        Top = 96
        Width = 449
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 1
      end
      object MESSPANEL: TPanel
        Left = 8
        Top = 8
        Width = 481
        Height = 41
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
      end
    end
  end
  object DATAQUERY: TIBQuery
    Database = DATADBASE
    Transaction = DATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 216
  end
  object DATADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = DATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 440
    Top = 216
  end
  object DATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DATADBASE
    AutoStopAction = saNone
    Left = 472
    Top = 216
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 216
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
    Left = 40
    Top = 216
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 216
  end
  object DATATABLA: TIBTable
    Database = DATADBASE
    Transaction = DATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 472
    Top = 184
  end
  object TRADETABLA: TIBTable
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 72
  end
  object TRADEQUERY: TIBQuery
    Database = TRADEDBASE
    Transaction = TRADETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 72
  end
  object TRADEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TRADETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 80
    Top = 72
  end
  object TRADETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TRADEDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 72
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 168
    Top = 224
  end
  object HRKDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\HAZIHRK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 200
    Top = 224
  end
  object HRKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HRKDBASE
    AutoStopAction = saNone
    Left = 232
    Top = 224
  end
end
