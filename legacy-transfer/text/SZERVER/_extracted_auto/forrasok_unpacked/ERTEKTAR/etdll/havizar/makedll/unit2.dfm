object HAVIZARAS: THAVIZARAS
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = '0'
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
      Top = 120
      Width = 497
      Height = 129
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 5
      object FASTCSIK: TProgressBar
        Left = 16
        Top = 80
        Width = 449
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 0
      end
      object SLOWCSIK: TProgressBar
        Left = 16
        Top = 8
        Width = 449
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 1
      end
      object MESSPANEL: TPanel
        Left = 0
        Top = 24
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
  object VALDATAQUERY: TIBQuery
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 40
    Top = 152
  end
  object VALDATADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALDATA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALDATATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 152
  end
  object VALDATATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDATADBASE
    AutoStopAction = saNone
    Left = 104
    Top = 152
  end
  object VALDATATABLA: TIBTable
    Database = VALDATADBASE
    Transaction = VALDATATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 152
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 216
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 216
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 72
    Top = 216
  end
end
