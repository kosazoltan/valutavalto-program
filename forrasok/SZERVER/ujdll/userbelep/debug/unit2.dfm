object USERFORM: TUSERFORM
  Left = 244
  Top = 199
  AlphaBlend = True
  AlphaBlendValue = 205
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'FELHASZN'#193'L'#211' BEL'#201'PTET'#201'SE '
  ClientHeight = 195
  ClientWidth = 980
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object USERVALPANEL: TPanel
    Left = 0
    Top = 0
    Width = 406
    Height = 191
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 3
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 406
      Height = 191
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object USERRACS: TDBGrid
      Left = 8
      Top = 11
      Width = 393
      Height = 174
      Cursor = crHandPoint
      Color = clWhite
      DataSource = USERSOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
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
          Expanded = False
          FieldName = 'USERS'
          Title.Alignment = taCenter
          Title.Caption = 'FELHASZN'#193'L'#211'K  NEVEI'
          Title.Color = clRed
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clYellow
          Title.Font.Height = -19
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 386
          Visible = True
        end>
    end
  end
  object PWBEKEROPANEL: TPanel
    Left = 100
    Top = 3
    Width = 400
    Height = 185
    BevelOuter = bvNone
    Color = clActiveBorder
    TabOrder = 1
    object Shape4: TShape
      Left = 0
      Top = 0
      Width = 400
      Height = 185
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Shape9: TShape
      Left = 20
      Top = 24
      Width = 365
      Height = 49
      Brush.Color = clRed
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape10: TShape
      Left = 88
      Top = 96
      Width = 241
      Height = 57
      Brush.Color = clBtnFace
      Pen.Width = 2
      Shape = stRoundRect
    end
    object USERNEVPANEL: TPanel
      Left = 26
      Top = 32
      Width = 353
      Height = 33
      BevelOuter = bvNone
      Caption = 'FABULYA ZSUZSA'
      Color = clRed
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object JELSZOPANEL: TPanel
      Left = 96
      Top = 104
      Width = 225
      Height = 41
      BevelOuter = bvNone
      TabOrder = 1
      object Label3: TLabel
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
        Left = 104
        Top = 8
        Width = 113
        Height = 21
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        PasswordChar = '*'
        TabOrder = 0
        OnKeyDown = JELSZOEDITKeyDown
      end
    end
  end
  object PWMODOSITOPANEL: TPanel
    Left = 550
    Top = 3
    Width = 400
    Height = 185
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 4
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 400
      Height = 185
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label1: TLabel
      Left = 96
      Top = 8
      Width = 203
      Height = 24
      Caption = 'JELSZ'#211' M'#211'DOSIT'#193'S'
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
    end
    object Label2: TLabel
      Left = 24
      Top = 64
      Width = 138
      Height = 21
      Caption = 'Jelenlegi jelszava:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 24
      Top = 32
      Width = 99
      Height = 21
      Caption = 'Felhaszn'#225'l'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label9: TLabel
      Left = 32
      Top = 96
      Width = 132
      Height = 21
      Caption = 'M'#243'dositott jelsz'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label11: TLabel
      Left = 24
      Top = 120
      Width = 143
      Height = 21
      Caption = 'Megism'#233'telt jelsz'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object FHNEVPANEL: TPanel
      Left = 128
      Top = 32
      Width = 257
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object FHJELSZOPANEL: TPanel
      Left = 168
      Top = 64
      Width = 225
      Height = 25
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object MODJELSZOOKEGOMB: TBitBtn
      Left = 32
      Top = 152
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'JELSZ'#211' RENDBEN'
      TabOrder = 2
      OnClick = MODJELSZOOKEGOMBClick
    end
    object MODJELSZOMEGSEMGOMB: TBitBtn
      Left = 200
      Top = 152
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = MegsemGombClick
    end
    object MODISMETELTEDIT: TEdit
      Left = 168
      Top = 120
      Width = 217
      Height = 21
      CharCase = ecUpperCase
      MaxLength = 10
      TabOrder = 4
      OnEnter = JELSZO1EDITEnter
      OnExit = JELSZO1EDITExit
      OnKeyDown = MODISMETELTEDITKeyDown
    end
    object MODJELSZOEDIT: TEdit
      Left = 168
      Top = 96
      Width = 217
      Height = 21
      CharCase = ecUpperCase
      MaxLength = 10
      TabOrder = 5
      OnEnter = JELSZO1EDITEnter
      OnExit = JELSZO1EDITExit
      OnKeyDown = MODJELSZOEDITKeyDown
    end
  end
  object KISMENUPANEL: TPanel
    Left = 282
    Top = 3
    Width = 400
    Height = 185
    BevelOuter = bvNone
    Caption = ' '
    Color = clSkyBlue
    TabOrder = 0
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 400
      Height = 185
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object MG1: TBitBtn
      Left = 16
      Top = 16
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEL'#201'P A RENDSZERBE'
      TabOrder = 0
      OnClick = m1Click
      OnEnter = m1Enter
      OnExit = m1Exit
    end
    object MG2: TBitBtn
      Left = 16
      Top = 48
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J FELHASZN'#193'L'#211'T VESZ FEL'
      TabOrder = 1
      OnClick = M2Click
      OnEnter = m1Enter
      OnExit = m1Exit
    end
    object MG3: TBitBtn
      Left = 16
      Top = 80
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'R'#214'L EGY FELHASZN'#193'L'#211'T'
      TabOrder = 2
      OnClick = M3Click
      OnEnter = m1Enter
      OnExit = m1Exit
    end
    object MG4: TBitBtn
      Left = 16
      Top = 112
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#211'DOS'#205'JA A JELSZAV'#193'T'
      TabOrder = 3
      OnClick = M4Click
      OnEnter = m1Enter
      OnExit = m1Exit
    end
    object MEGSEMGOMB: TBitBtn
      Left = 16
      Top = 144
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P  A PROGRAMB'#211'L'
      TabOrder = 4
      OnClick = MegsemGombClick
      OnEnter = m1Enter
      OnExit = m1Exit
    end
  end
  object TORLOPANEL: TPanel
    Left = 300
    Top = 3
    Width = 400
    Height = 185
    Color = clActiveCaption
    TabOrder = 5
    Visible = False
    object Shape3: TShape
      Left = 1
      Top = 1
      Width = 398
      Height = 183
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label10: TLabel
      Left = 32
      Top = 8
      Width = 331
      Height = 19
      Caption = 'EGY FELHASZN'#193'L'#211' T'#214'RL'#201'SE A LIST'#193'R'#211'L'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object TORLORACS: TDBGrid
      Left = 8
      Top = 32
      Width = 385
      Height = 113
      DataSource = TORLOSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = TORLORACSDblClick
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'USERS'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Title.Alignment = taCenter
          Title.Caption = 'V'#225'lassza ki a t'#246'rlend'#337' szem'#233'lyt '
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 364
          Visible = True
        end>
    end
    object TOROLOKEGOMB: TBitBtn
      Left = 32
      Top = 152
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'R'#214'LNI A LIST'#193'R'#211'L'
      TabOrder = 1
      OnClick = TOROLOKEGOMBClick
    end
    object MEGSEMTOROLGOMB: TBitBtn
      Left = 208
      Top = 152
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM T'#214'RL'#214'K'
      TabOrder = 2
      OnClick = MEGSEMTOROLGOMBClick
    end
  end
  object UJUSERPANEL: TPanel
    Left = 150
    Top = 3
    Width = 400
    Height = 185
    BevelOuter = bvNone
    Color = clTeal
    TabOrder = 2
    object Shape8: TShape
      Left = 0
      Top = 0
      Width = 400
      Height = 185
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 2
    end
    object Label5: TLabel
      Left = 32
      Top = 8
      Width = 333
      Height = 24
      Caption = 'EGY '#218'J FELHASZN'#193'L'#211' FELV'#201'TELE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Lemon'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 72
      Top = 40
      Width = 243
      Height = 21
      Caption = 'AZ '#218'J FELHASZN'#193'L'#211' NEVE/'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label7: TLabel
      Left = 96
      Top = 88
      Width = 90
      Height = 21
      Caption = 'JELSZAVA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label8: TLabel
      Left = 80
      Top = 112
      Width = 107
      Height = 21
      Caption = 'ISM'#201'TELVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      Transparent = True
    end
    object NEVEDIT: TEdit
      Left = 48
      Top = 64
      Width = 305
      Height = 24
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = ' '
      OnEnter = JELSZO1EDITEnter
      OnExit = JELSZO1EDITExit
      OnKeyDown = NEVEDITKeyDown
    end
    object JELSZO1EDIT: TEdit
      Left = 192
      Top = 88
      Width = 121
      Height = 23
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 10
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 1
      Text = ' '
      OnEnter = JELSZO1EDITEnter
      OnExit = JELSZO1EDITExit
      OnKeyDown = JELSZO1EDITKeyDown
    end
    object JELSZO2EDIT: TEdit
      Left = 192
      Top = 112
      Width = 121
      Height = 23
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 10
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 2
      Text = ' '
      OnEnter = JELSZO1EDITEnter
      OnExit = JELSZO1EDITExit
      OnKeyDown = JELSZO2EDITKeyDown
    end
    object KONFIRMGOMB: TBitBtn
      Left = 40
      Top = 144
      Width = 161
      Height = 25
      Caption = 'ADATOK R'#214'GZITHET'#336'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = KONFIRMGOMBClick
    end
    object SEMGOMB: TBitBtn
      Left = 208
      Top = 144
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
  end
  object USERSOURCE: TDataSource
    DataSet = USERTABLA
    Left = 8
    Top = 8
  end
  object USERTABLA: TIBTable
    Database = USERDBASE
    Transaction = USERTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'USERS'
        Attributes = [faFixed]
        DataType = ftString
        Size = 20
      end
      item
        Name = 'HEXAPASSWORD'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'SORSZAM'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'IDX_USERS'
        Fields = 'USERS'
      end>
    IndexFieldNames = 'USERS'
    StoreDefs = True
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
    SQL.Strings = (
      'SELECT * FROM USERS')
    Left = 32
    Top = 64
  end
  object TORLOSOURCE: TDataSource
    DataSet = TORLOQUERY
    Left = 576
    Top = 80
  end
  object TORLOQUERY: TIBQuery
    Database = TORLODBASE
    Transaction = TORLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 576
    Top = 112
    object TORLOQUERYUSERS: TIBStringField
      FieldName = 'USERS'
      Origin = 'USERS.USERS'
      FixedChar = True
    end
    object TORLOQUERYHEXAPASSWORD: TIBStringField
      FieldName = 'HEXAPASSWORD'
      Origin = 'USERS.HEXAPASSWORD'
      FixedChar = True
      Size = 10
    end
    object TORLOQUERYSORSZAM: TSmallintField
      FieldName = 'SORSZAM'
      Origin = 'USERS.SORSZAM'
    end
  end
  object TORLODBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = TORLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 608
    Top = 112
  end
  object TORLOTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = TORLODBASE
    AutoStopAction = saNone
    Left = 640
    Top = 112
  end
end
