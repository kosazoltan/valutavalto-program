object KORLEVEL: TKORLEVEL
  Left = 252
  Top = 210
  BorderStyle = bsNone
  Caption = 'KORLEVEL'
  ClientHeight = 443
  ClientWidth = 608
  Color = clSilver
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel2: TPanel
    Left = 4
    Top = 53
    Width = 394
    Height = 20
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 3
    object NYELV: TPanel
      Left = -80
      Top = 0
      Width = 97
      Height = 20
      Color = clRed
      TabOrder = 0
    end
  end
  object CIMPANEL: TPanel
    Left = 5
    Top = 0
    Width = 393
    Height = 25
    Caption = 'K'#214'RLEVELEK ELLEN'#214'RZ'#201'SE'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object MESSPANEL: TPanel
    Left = 5
    Top = 24
    Width = 394
    Height = 25
    Hint = '4'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
  end
  object LEVELRACSPANEL: TPanel
    Left = 0
    Top = 0
    Width = 729
    Height = 449
    BevelWidth = 3
    Caption = '0'
    Color = clRed
    TabOrder = 0
    object Label1: TLabel
      Left = 184
      Top = 8
      Width = 388
      Height = 33
      Caption = 'A LET'#214'LT'#214'TT K'#214'RLEVELEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object ARCHIVEGOMB: TBitBtn
      Left = 368
      Top = 416
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'R'#201'GEBBI LEVELEK'
      TabOrder = 5
      OnClick = ARCHIVEGOMBClick
    end
    object LEVELRACS: TDBGrid
      Left = 24
      Top = 40
      Width = 673
      Height = 369
      Cursor = crHandPoint
      DataSource = LEVELSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = LEVELRACSDblClick
      OnKeyDown = LEVELRACSKeyDown
      Columns = <
        item
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
          Expanded = False
          FieldName = 'TARTALOM'
          Title.Alignment = taCenter
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
          FieldName = 'IKTATOSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'IKTAT'#211'SZ'#193'M'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 99
          Visible = True
        end>
    end
    object OLVASOGOMB: TBitBtn
      Left = 16
      Top = 416
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'LEV'#201'L OLVAS'#193'SA'
      TabOrder = 1
      OnClick = OLVASOGOMBClick
    end
    object QUITGOMB: TBitBtn
      Left = 544
      Top = 416
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A PROGRAMB'#211'L'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
    object LASTYEARGOMB: TBitBtn
      Left = 192
      Top = 416
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#218'LT '#201'VI LEVELEK'
      TabOrder = 4
      OnClick = LASTYEARGOMBClick
    end
    object RACSFUGGONY: TPanel
      Left = -648
      Top = -64
      Width = 713
      Height = 401
      TabOrder = 3
      object Label2: TLabel
        Left = 312
        Top = 168
        Width = 85
        Height = 21
        Caption = 'bet'#246'lt'#233'se ...'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object tartpanel: TPanel
        Left = 8
        Top = 112
        Width = 689
        Height = 41
        BevelOuter = bvNone
        Caption = 'A sdertghztrefrdgvbg sedrfgthzujikzjuhzgx'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object SERVERQUERY: TIBQuery
    Database = SERVERDBASE
    Transaction = SERVERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 136
  end
  object SERVERDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = SERVERTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 40
    Top = 136
  end
  object SERVERTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = SERVERDBASE
    AutoStopAction = saNone
    Left = 72
    Top = 136
  end
  object KORQUERY: TIBQuery
    Database = KORDBASE
    Transaction = KORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM IKTATO')
  end
  object KORDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\KORLEVEL.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 32
  end
  object KORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KORDBASE
    AutoStopAction = saNone
    Left = 64
  end
  object LEVELSOURCE: TDataSource
    DataSet = KORQUERY
    Left = 104
    Top = 8
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 8
    Top = 80
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
    Left = 40
    Top = 80
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 72
    Top = 80
  end
  object PATHKERESO: TOpenDialog
    DefaultExt = 'EXE'
    Left = 232
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 1600
    OnTimer = KILEPOTimer
    Left = 360
    Top = 16
  end
end
