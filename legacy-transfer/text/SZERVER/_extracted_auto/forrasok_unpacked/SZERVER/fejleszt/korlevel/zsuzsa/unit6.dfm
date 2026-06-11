object GETIDKOD: TGETIDKOD
  Left = 483
  Top = 224
  BorderStyle = bsNone
  Caption = 'GETIDKOD'
  ClientHeight = 290
  ClientWidth = 364
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
    Width = 361
    Height = 289
    TabOrder = 0
    object Label1: TLabel
      Left = 96
      Top = 8
      Width = 191
      Height = 24
      Caption = 'USER AZONOS'#205'T'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object PROSRACS: TDBGrid
      Left = 16
      Top = 40
      Width = 329
      Height = 201
      Cursor = crHandPoint
      DataSource = PROSSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = EZVAGYOKGOMBClick
      OnKeyDown = ProsRacsKeyDown
      Columns = <
        item
          Expanded = False
          FieldName = 'PENZTAROSNEV'
          Title.Alignment = taCenter
          Title.Caption = 'KI VAGY TE ?'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 300
          Visible = True
        end>
    end
    object EZVAGYOKGOMB: TBitBtn
      Left = 16
      Top = 248
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'EZ VAGYOK '#201'N'
      TabOrder = 1
      OnClick = EZVAGYOKGOMBClick
    end
    object NEMTALALOMGOMB: TBitBtn
      Left = 184
      Top = 248
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM TAL'#193'LOM MAGAMAT'
      TabOrder = 2
      OnClick = NemTalalomGombClick
    end
  end
  object PROSQUERY: TIBQuery
    Database = PROSDBASE
    Transaction = PROSTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 56
    Top = 24
  end
  object PROSDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PROSTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 24
  end
  object PROSTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PROSDBASE
    AutoStopAction = saNone
    Left = 120
    Top = 24
  end
  object PROSSOURCE: TDataSource
    DataSet = PROSQUERY
    Left = 160
    Top = 24
  end
end
