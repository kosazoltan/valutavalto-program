object GETWCEG: TGETWCEG
  Left = 379
  Top = 172
  BorderStyle = bsNone
  Caption = 'GETWCEGFORM'
  ClientHeight = 453
  ClientWidth = 496
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 490
    Height = 450
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 0
    object Shape1: TShape
      Left = 16
      Top = 384
      Width = 433
      Height = 41
      Brush.Color = clSkyBlue
      Pen.Color = clNavy
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 32
      Top = 336
      Width = 163
      Height = 24
      Caption = 'KERESETT C'#201'G:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object keresedit: TEdit
      Left = 208
      Top = 336
      Width = 241
      Height = 29
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnEnter = kereseditEnter
    end
    object WCEGRACS: TDBGrid
      Left = 24
      Top = 64
      Width = 425
      Height = 265
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 16311512
      DataSource = WACEGEKSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = WCEGRACSDblClick
      OnKeyDown = WCEGRACSKeyDown
      OnKeyPress = WCEGRACSKeyPress
      OnMouseMove = WCEGRACSMouseMove
      Columns = <
        item
          Alignment = taCenter
          DropDownRows = 15
          Expanded = False
          FieldName = 'CEGNEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clNavy
          Font.Height = -19
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'Western Union '#233's '#193'FA partnerek'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -21
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 396
          Visible = True
        end>
    end
    object RENDBENGOMB: TBitBtn
      Left = 24
      Top = 392
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = RENDBENGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
    end
    object UJCEGGOMB: TBitBtn
      Left = 168
      Top = 392
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'UJ PARTNER'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = UJCEGGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
    end
    object MEGSEMGOMB: TBitBtn
      Left = 312
      Top = 392
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = MEGSEMGOMBClick
      OnEnter = RENDBENGOMBEnter
      OnExit = RENDBENGOMBExit
    end
    object UJCEGPANEL: TPanel
      Left = 24
      Top = 96
      Width = 401
      Height = 233
      BevelOuter = bvNone
      Color = clSkyBlue
      TabOrder = 4
      object Label2: TLabel
        Left = 64
        Top = 96
        Width = 276
        Height = 21
        Caption = 'AZ '#218'J PARTNER MEGNEVEZ'#201'SE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 48
        Top = 16
        Width = 289
        Height = 28
        Caption = #218'J PARTNER FELV'#201'TELE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -24
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object WCEGNEVEDIT: TEdit
        Left = 32
        Top = 128
        Width = 329
        Height = 29
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        MaxLength = 25
        ParentFont = False
        TabOrder = 0
        OnEnter = WCEGNEVEDITEnter
        OnExit = WCEGNEVEDITExit
        OnKeyDown = WCEGNEVEDITKeyDown
      end
    end
    object Panel2: TPanel
      Left = 8
      Top = 8
      Width = 465
      Height = 49
      BevelOuter = bvNone
      Caption = 'V'#193'LASSZON JOGI SZEM'#201'LYT'
      Color = 16311512
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
  end
  object WACEGEKSOURCE: TDataSource
    DataSet = WUCEGEKTABLA
    Left = 56
    Top = 192
  end
  object WUCEGEKTABLA: TIBTable
    Database = WUCEGEKDBASE
    Transaction = WUCEGEKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'CEGSZAM'
        DataType = ftInteger
      end
      item
        Name = 'CEGNEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 25
      end>
    IndexDefs = <
      item
        Name = 'IDX_WUAFACEGEK1'
        Fields = 'CEGNEV'
      end
      item
        Name = 'IDX_WUAFACEGEK'
        Fields = 'CEGSZAM'
      end>
    IndexFieldNames = 'CEGNEV'
    StoreDefs = True
    TableName = 'WUAFACEGEK'
    Left = 8
    Top = 8
  end
  object WUCEGEKDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = WUCEGEKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 8
  end
  object WUCEGEKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = WUCEGEKDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 48
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
    Left = 40
    Top = 48
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 72
    Top = 48
  end
end
