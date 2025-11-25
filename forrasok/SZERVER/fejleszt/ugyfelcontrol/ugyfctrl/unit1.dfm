object Form1: TForm1
  Left = 198
  Top = 157
  BorderStyle = bsSingle
  Caption = '0'
  ClientHeight = 589
  ClientWidth = 1017
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
  object Label2: TLabel
    Left = 240
    Top = 128
    Width = 241
    Height = 21
    Caption = 'A KERESETT '#220'GYF'#201'L NEVE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 1017
    Height = 589
    Align = alClient
    Pen.Color = clRed
    Pen.Width = 5
  end
  object Panel1: TPanel
    Left = 5
    Top = 5
    Width = 1008
    Height = 41
    BevelOuter = bvNone
    Caption = 
      'Az Exclusive Change kft '#233's Expressz '#201'kszerh'#225'z '#233's Minibank kft '#252'g' +
      'yfelei'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 5
    Top = 44
    Width = 1014
    Height = 5
    BevelOuter = bvNone
    Caption = ' '
    Color = clRed
    TabOrder = 1
  end
  object FOMENUPANEL: TPanel
    Left = 288
    Top = 168
    Width = 441
    Height = 297
    TabOrder = 2
    Visible = False
    object Shape8: TShape
      Left = 1
      Top = 1
      Width = 439
      Height = 295
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label71: TLabel
      Left = 64
      Top = 24
      Width = 327
      Height = 23
      Caption = 'AZ '#220'GYF'#201'L-KONTROL F'#336'MEN'#368'JE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object IDOSZAKKERESOGOMB: TBitBtn
      Left = 40
      Top = 72
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'ID'#336'SZAK SZERINTI '#220'GYFELEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IDOSZAKKERESOGOMBClick
    end
    object UGYFELKERESOGOMB: TBitBtn
      Left = 40
      Top = 104
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYFELEK KERES'#201'SE N'#201'V SZERINT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = UGYFELKERESOGOMBClick
    end
    object EXITGOMB: TBitBtn
      Left = 40
      Top = 232
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = EXITGOMBClick
    end
    object EVIMAXGOMB: TBitBtn
      Left = 40
      Top = 136
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = #201'VES '#201'RT'#201'KHAT'#193'R FELETTI TRANZAKCIOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = EVIMAXGOMBClick
    end
    object TERRORNAPLOGOMB: TBitBtn
      Left = 40
      Top = 200
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'TERROR GYANUS ESETEK NAPL'#211'Z'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = TERRORNAPLOGOMBClick
    end
    object UJIMPORTGOMB: TBitBtn
      Left = 40
      Top = 168
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J IMPORTFILE K'#201'SZ'#205'T'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = UJIMPORTGOMBClick
    end
  end
  object NTABLA: TIBTable
    Database = NDBASE
    Transaction = NTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 904
    Top = 8
  end
  object NQUERY: TIBQuery
    Database = NDBASE
    Transaction = NTRANZ
    AutoCalcFields = False
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 936
    Top = 8
  end
  object NDBASE: TIBDatabase
    DatabaseName = ':'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 968
    Top = 8
  end
  object NTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 872
    Top = 8
  end
  object NATURSOURCE: TDataSource
    DataSet = NQUERY
    Enabled = False
    Left = 8
    Top = 696
  end
  object JOGISOURCE: TDataSource
    Enabled = False
    Left = 8
    Top = 728
  end
  object BIZSOURCE: TDataSource
    Left = 8
    Top = 664
  end
end
