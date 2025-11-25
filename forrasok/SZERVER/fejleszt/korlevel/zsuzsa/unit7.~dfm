object LASTYEARFORM: TLASTYEARFORM
  Left = 192
  Top = 124
  BorderStyle = bsNone
  Caption = 'LASTYEARFORM'
  ClientHeight = 357
  ClientWidth = 834
  Color = clMoneyGreen
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ARCRACS: TDBGrid
    Left = 8
    Top = 40
    Width = 817
    Height = 273
    Cursor = crHandPoint
    DataSource = ARCSOURCE
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = ARCRACSDblClick
    OnKeyUp = ARCRACSKeyUp
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'DATUM'
        Title.Alignment = taCenter
        Title.Caption = 'D'#193'TUM'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Width = 157
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'IKTATOSZAM'
        Title.Alignment = taCenter
        Title.Caption = 'IKTAT'#211'SZ'#193'M'
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Width = 192
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TARTALOM'
        Title.Alignment = taCenter
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold]
        Width = 454
        Visible = True
      end>
  end
  object INFOCSIK: TPanel
    Left = 272
    Top = 152
    Width = 337
    Height = 41
    Caption = 'Bet'#246'lt'#246'm a k'#246'rlevelet ...'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -27
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object ARCREADGOMB: TBitBtn
    Left = 24
    Top = 320
    Width = 193
    Height = 25
    Cursor = crHandPoint
    Caption = 'LEV'#201'L OLVAS'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = ARCREADGOMBClick
  end
  object ARCBACKGOMB: TBitBtn
    Left = 648
    Top = 320
    Width = 171
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = ARCBACKGOMBClick
  end
  object FOCIMPANEL: TPanel
    Left = 128
    Top = 2
    Width = 569
    Height = 32
    BevelOuter = bvNone
    Caption = 'M'#250'lt '#233'vi (expressz) k'#246'rlevelek'
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object ARCQUERY: TIBQuery
    Database = ARCDBASE
    Transaction = ARCTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM KORLEVEL')
    Left = 8
    Top = 8
  end
  object ARCDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\KORLEVEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARCTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object ARCTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = ARCDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object ARCSOURCE: TDataSource
    DataSet = ARCQUERY
    Left = 104
    Top = 8
  end
end
