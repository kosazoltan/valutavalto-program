object Form1: TForm1
  Left = 192
  Top = 125
  Width = 870
  Height = 640
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
    Top = 24
    Width = 75
    Height = 25
    Caption = 'START'
    TabOrder = 0
    OnClick = BitBtn1Click
  end
  object kilepgomb: TBitBtn
    Left = 32
    Top = 56
    Width = 75
    Height = 25
    Cursor = crHandPoint
    Caption = 'KILEP'
    TabOrder = 1
    OnClick = kilepgombClick
  end
  object racs: TDBGrid
    Left = 144
    Top = 96
    Width = 649
    Height = 473
    DataSource = DSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Expanded = False
        FieldName = 'UGYFELNEV'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATUM'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BIZONYLATSZAM'
        Visible = True
      end>
  end
  object FDBLIST: TListBox
    Left = 16
    Top = 96
    Width = 121
    Height = 473
    Cursor = crHandPoint
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ItemHeight = 18
    ParentFont = False
    TabOrder = 3
    OnDblClick = FDBLISTDblClick
  end
  object EVCOMBO: TComboBox
    Left = 336
    Top = 16
    Width = 113
    Height = 21
    ItemHeight = 13
    TabOrder = 4
    Text = 'EVCOMBO'
    OnChange = EVCOMBOChange
    Items.Strings = (
      '2017'
      '2018'
      '')
  end
  object HOCOMBO: TComboBox
    Left = 456
    Top = 16
    Width = 145
    Height = 21
    ItemHeight = 13
    TabOrder = 5
    Text = 'HOCOMBO'
    OnChange = HOCOMBOChange
    Items.Strings = (
      '01'
      '02'
      '03'
      '04'
      '05'
      '06'
      '07'
      '08'
      '09'
      '10'
      '11'
      '12')
  end
  object fdbpanel: TPanel
    Left = 152
    Top = 56
    Width = 169
    Height = 25
    Color = clAqua
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
  end
  object DISPLAYGOMB: TBitBtn
    Left = 608
    Top = 16
    Width = 129
    Height = 25
    Cursor = crHandPoint
    Caption = 'DISPLAY'
    TabOrder = 7
    OnClick = DISPLAYGOMBClick
  end
  object nextpanel: TPanel
    Left = 144
    Top = 8
    Width = 185
    Height = 28
    Cursor = crHandPoint
    Caption = 'K'#214'VETKEZ'#336
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 8
    OnClick = NEXTGOMBClick
  end
  object datumpanel: TPanel
    Left = 336
    Top = 56
    Width = 249
    Height = 25
    Color = clYellow
    TabOrder = 9
  end
  object nevedit: TEdit
    Left = 608
    Top = 56
    Width = 145
    Height = 26
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
  end
  object SQUERY: TIBQuery
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 800
    Top = 88
  end
  object SDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\_work\V143.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = STRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 800
    Top = 48
  end
  object STRANZ: TIBTransaction
    Active = True
    DefaultDatabase = SDBASE
    AutoStopAction = saNone
    Left = 808
    Top = 120
  end
  object DSOURCE: TDataSource
    DataSet = SQUERY
    Left = 800
    Top = 16
  end
  object STABLA: TIBTable
    Database = SDBASE
    Transaction = STRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 808
    Top = 168
  end
end
