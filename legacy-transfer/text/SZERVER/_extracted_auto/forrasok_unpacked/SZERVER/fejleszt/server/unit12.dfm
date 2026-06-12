object USERFORM: TUSERFORM
  Left = 260
  Top = 310
  BorderStyle = bsNone
  Caption = 'USERFORM'
  ClientHeight = 281
  ClientWidth = 483
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
  object Shape3: TShape
    Left = 56
    Top = 72
    Width = 65
    Height = 65
  end
  object USERVALPANEL: TPanel
    Left = 0
    Top = 0
    Width = 513
    Height = 321
    BevelOuter = bvNone
    Color = 170
    TabOrder = 0
    object Shape1: TShape
      Left = 16
      Top = 32
      Width = 449
      Height = 241
      Brush.Color = 11599871
      Pen.Width = 2
      Shape = stRoundRect
    end
    object USERRACS: TDBGrid
      Left = 26
      Top = 56
      Width = 425
      Height = 185
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 11599871
      DataSource = USERSOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = Kivalasztas
      OnKeyDown = USERRACSKeyDown
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'USERS'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ReadOnly = True
          Title.Alignment = taCenter
          Title.Caption = 'FELHASZN'#193'L'#211'K'
          Title.Color = 170
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -19
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 450
          Visible = True
        end>
    end
    object PWBEKEROPANEL: TPanel
      Left = 120
      Top = 0
      Width = 481
      Height = 273
      BevelOuter = bvNone
      Color = 170
      TabOrder = 2
      object Shape5: TShape
        Left = 32
        Top = 24
        Width = 417
        Height = 209
        Brush.Color = 16724991
        Pen.Width = 2
        Shape = stRoundRect
      end
      object Shape2: TShape
        Left = 128
        Top = 122
        Width = 241
        Height = 57
        Brush.Color = clBtnFace
        Pen.Width = 2
        Shape = stRoundRect
      end
      object Shape6: TShape
        Left = 68
        Top = 48
        Width = 365
        Height = 49
        Brush.Color = clTeal
        Pen.Width = 2
        Shape = stRoundRect
      end
      object USERNEVPANEL: TPanel
        Left = 72
        Top = 56
        Width = 353
        Height = 33
        BevelOuter = bvNone
        Caption = 'FABULYA ZSUZSA'
        Color = clTeal
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object JELSZOPANEL: TPanel
        Left = 136
        Top = 130
        Width = 225
        Height = 41
        BevelOuter = bvNone
        TabOrder = 1
        object Label1: TLabel
          Left = 16
          Top = 8
          Width = 76
          Height = 24
          Caption = 'JELSZ'#211':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object JELSZOEDIT: TEdit
          Left = 96
          Top = 4
          Width = 121
          Height = 32
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          CharCase = ecUpperCase
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          MaxLength = 5
          ParentFont = False
          PasswordChar = '#'
          TabOrder = 0
          OnKeyDown = JELSZOEDITKeyDown
        end
      end
      object kismenupanel: TPanel
        Left = 72
        Top = 8
        Width = 449
        Height = 225
        BevelOuter = bvNone
        Color = 170
        TabOrder = 2
        object Shape4: TShape
          Left = 32
          Top = 32
          Width = 385
          Height = 137
          Pen.Width = 2
          Shape = stRoundRect
        end
        object mg1: TBitBtn
          Left = 40
          Top = 40
          Width = 369
          Height = 25
          Cursor = crHandPoint
          Caption = 'BEL'#201'P A RENDSZERBE'
          TabOrder = 0
          OnClick = mg1Click
          OnEnter = mg1Enter
          OnExit = mg1Exit
        end
        object MG2: TBitBtn
          Left = 40
          Top = 72
          Width = 369
          Height = 25
          Cursor = crHandPoint
          Caption = #218'J FELHASZN'#193'L'#211'T VESZ FEL'
          TabOrder = 1
          OnClick = MG2Click
          OnEnter = mg1Enter
          OnExit = mg1Exit
        end
        object MG3: TBitBtn
          Left = 40
          Top = 104
          Width = 369
          Height = 25
          Cursor = crHandPoint
          Caption = 'T'#214'R'#214'L EGY FELHASZN'#193'L'#211'T  A NYILV'#193'NTART'#193'SB'#211'L'
          TabOrder = 2
          OnClick = MG3Click
          OnEnter = mg1Enter
          OnExit = mg1Exit
        end
        object MG4: TBitBtn
          Left = 40
          Top = 136
          Width = 369
          Height = 25
          Cursor = crHandPoint
          Caption = 'M'#211'DOSITJA A JELSZAV'#193'T'
          TabOrder = 3
          OnClick = MG4Click
          OnEnter = mg1Enter
          OnExit = mg1Exit
        end
      end
      object USERPANEL: TPanel
        Left = 336
        Top = 240
        Width = 449
        Height = 257
        Color = 170
        TabOrder = 3
        object Label2: TLabel
          Left = 144
          Top = 48
          Width = 170
          Height = 20
          Caption = 'FELHASZN'#193'L'#211' NEVE'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object Label3: TLabel
          Left = 112
          Top = 120
          Width = 88
          Height = 20
          Caption = 'JELSZAVA:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object Label4: TLabel
          Left = 256
          Top = 120
          Width = 98
          Height = 20
          Caption = 'ISM'#201'TELVE:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -16
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object NEVEDIT: TEdit
          Left = 56
          Top = 80
          Width = 337
          Height = 21
          CharCase = ecUpperCase
          TabOrder = 0
          Text = 'KECSKEM'#201'TI BOLDIZS'#193'R'
          OnKeyDown = NEVEDITKeyDown
        end
        object JELSZO1EDIT: TEdit
          Left = 96
          Top = 144
          Width = 113
          Height = 24
          CharCase = ecUpperCase
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          MaxLength = 5
          ParentFont = False
          PasswordChar = '@'
          TabOrder = 1
          Text = 'ABCDEFGHJK'
          OnKeyDown = JELSZO1EDITKeyDown
        end
        object JELSZO2EDIT: TEdit
          Left = 248
          Top = 144
          Width = 113
          Height = 24
          CharCase = ecUpperCase
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          MaxLength = 5
          ParentFont = False
          PasswordChar = '@'
          TabOrder = 2
          Text = 'JELSZO2EDIT'
          OnKeyDown = JELSZO2EDITKeyDown
        end
        object KONFIRMGOMB: TBitBtn
          Left = 128
          Top = 200
          Width = 209
          Height = 25
          Cursor = crHandPoint
          Caption = 'ADATOK R'#214'GZITHET'#336'K'
          TabOrder = 3
          OnClick = KONFIRMGOMBClick
        end
      end
    end
    object MEGSEMGOMB: TBitBtn
      Left = 208
      Top = 248
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      TabOrder = 1
      OnClick = MEGSEMGOMBClick
    end
  end
  object USERSOURCE: TDataSource
    DataSet = USERTABLA
    Left = 48
    Top = 248
  end
  object USERTABLA: TIBTable
    Database = USERDBASE
    Transaction = USERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'USERS'
    TableName = 'USERS'
    Left = 32
    Top = 24
  end
  object USERDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = USERTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 24
  end
  object USERTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = USERDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 24
  end
  object USERQUERY: TIBQuery
    Database = USERDBASE
    Transaction = USERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 64
  end
end
