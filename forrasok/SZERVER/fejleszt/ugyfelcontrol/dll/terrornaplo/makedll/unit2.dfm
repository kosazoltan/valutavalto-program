object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 395
  ClientWidth = 854
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
  object FOCIM: TLabel
    Left = 200
    Top = 230
    Width = 564
    Height = 31
    Caption = 'TERROR-GYAN'#218'S ESETEK NAPL'#211'Z'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object VISSZAGOMB: TButton
    Left = 616
    Top = 344
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'RE'
    TabOrder = 0
    Visible = False
    OnClick = VISSZAGOMBClick
  end
  object IDOSZAKPANEL: TPanel
    Left = 216
    Top = 48
    Width = 465
    Height = 41
    BevelOuter = bvNone
    Color = clGreen
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    Visible = False
  end
  object NAPLORACS: TDBGrid
    Left = 64
    Top = 112
    Width = 745
    Height = 225
    DataSource = NAPLOSOURCE
    Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Visible = False
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'PENZTARKOD'
        Title.Alignment = taCenter
        Title.Caption = 'PT.'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTARNEV'
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'R NEVE'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 142
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IDO'
        Title.Alignment = taCenter
        Title.Caption = 'ID'#336
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 47
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'UGYFELNEV'
        Title.Alignment = taCenter
        Title.Caption = #220'GYF'#201'L NEVE'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 178
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ENGEDELYEZVE'
        Title.Alignment = taCenter
        Title.Caption = 'ENGED'#201'LYEZVE'
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 101
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ENGEDELYEZO'
        Title.Alignment = taCenter
        Title.Caption = 'ENGED'#201'LYEZ'#336
        Title.Color = clYellow
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -11
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = [fsBold]
        Width = 155
        Visible = True
      end>
  end
  object EXCELGOMB: TBitBtn
    Left = 64
    Top = 344
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'EXCELT'#193'BLA K'#201'SZ'#205'T'#201'S'
    TabOrder = 3
    Visible = False
    OnClick = EXCELGOMBClick
  end
  object KILEPOGOMB: TPanel
    Left = 288
    Top = 208
    Width = 241
    Height = 33
    Cursor = crHandPoint
    Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
    Visible = False
    OnClick = KILEPOGOMBClick
  end
  object TAKAROPANEL: TPanel
    Left = 256
    Top = 192
    Width = 289
    Height = 65
    TabOrder = 5
    Visible = False
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 287
      Height = 63
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 40
      Top = 8
      Width = 214
      Height = 19
      Caption = 'EXCELT'#193'BLA K'#201'SZ'#205'T'#201'SE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object CSIK: TProgressBar
      Left = 24
      Top = 32
      Width = 249
      Height = 17
      Min = 0
      Max = 4
      Smooth = True
      TabOrder = 0
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 300
    OnTimer = KILEPOTimer
    Left = 24
    Top = 16
  end
  object UQUERY: TIBQuery
    Database = UDBASE
    Transaction = UTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 56
  end
  object UDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = UTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 24
    Top = 96
  end
  object UTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = UDBASE
    AutoStopAction = saNone
    Left = 24
    Top = 136
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 72
    Top = 56
  end
  object REMOTEDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:c:\RECEPTOR\DATABASE\TERRORISTS.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 96
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 136
  end
  object NAPLOSOURCE: TDataSource
    DataSet = REMOTEQUERY
    Left = 112
    Top = 144
  end
end
