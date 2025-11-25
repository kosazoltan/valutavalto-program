object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 411
  ClientWidth = 908
  Color = clActiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object LETILTOPANEL: TPanel
    Left = -1897
    Top = 0
    Width = 905
    Height = 409
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    Visible = False
    object Label1: TLabel
      Left = 336
      Top = 24
      Width = 331
      Height = 27
      Caption = 'EGY '#220'GYF'#201'L LETILT'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 360
      Top = 56
      Width = 170
      Height = 19
      Caption = 'K'#233'rem a n'#233'v kezdet'#233't:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label19: TLabel
      Left = 80
      Top = 376
      Width = 455
      Height = 21
      Caption = #220'GYF'#201'L V'#193'LASZT'#193'SA -> DUPLA KLIKK VAGY ENTER'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object TNEVEDIT: TEdit
      Left = 312
      Top = 80
      Width = 241
      Height = 28
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnEnter = TNEVEDITEnter
      OnExit = TNEVEDITExit
      OnKeyDown = TNEVEDITKeyDown
    end
    object TILTORACS: TDBGrid
      Left = 24
      Top = 128
      Width = 857
      Height = 241
      Cursor = crHandPoint
      DataSource = TILTOSOURCE
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = TILTORACSDblClick
      OnKeyDown = TiltoRacsKeyDown
      Columns = <
        item
          Expanded = False
          FieldName = 'NEV'
          Title.Alignment = taCenter
          Title.Caption = #220'GYF'#201'L NEVE'
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 208
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ANYJANEVE'
          Title.Alignment = taCenter
          Title.Caption = 'ANYJA NEVE'
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 151
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SZULETESIIDO'
          Title.Alignment = taCenter
          Title.Caption = 'SZ'#220'LET'#201'SI ID'#336
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 100
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SZULETESIHELY'
          Title.Alignment = taCenter
          Title.Caption = 'SZULET'#201'SI HELY'
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 160
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'LAKCIM'
          Title.Alignment = taCenter
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 219
          Visible = True
        end>
    end
    object KEZIGOMB: TBitBtn
      Left = 576
      Top = 376
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK K'#201'ZI BEVITELE'
      TabOrder = 2
      OnClick = KeziGombClick
    end
    object TMEGSEMGOMB: TBitBtn
      Left = 728
      Top = 376
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = TMEGSEMGOMBClick
    end
  end
  object KEZIADATPANEL: TPanel
    Left = -1987
    Top = 40
    Width = 577
    Height = 273
    BevelOuter = bvNone
    Color = clSkyBlue
    TabOrder = 1
    Visible = False
    object Label4: TLabel
      Left = 168
      Top = 16
      Width = 264
      Height = 21
      Caption = 'ADATOK K'#201'ZI BEVITELE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 184
      Top = 48
      Width = 228
      Height = 24
      Caption = 'A letiltand'#243' '#252'gyf'#233'l adatai:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 112
      Top = 88
      Width = 44
      Height = 18
      Caption = 'NEVE:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 64
      Top = 112
      Width = 94
      Height = 18
      Caption = 'ANYJA NEVE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 24
      Top = 136
      Width = 133
      Height = 18
      Caption = 'SZ'#220'LET'#201'SI IDEJE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label9: TLabel
      Left = 16
      Top = 160
      Width = 139
      Height = 18
      Caption = 'SZ'#220'LET'#201'SI HELYE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object TILTNEVEDIT: TEdit
      Tag = 1
      Left = 160
      Top = 88
      Width = 345
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 0
      Text = 'TILTNEVEDIT'
      OnEnter = TNEVEDITEnter
      OnExit = TNEVEDITExit
      OnKeyDown = TiltNevEditKeyDown
    end
    object TANYJAEDIT: TEdit
      Tag = 2
      Left = 160
      Top = 112
      Width = 345
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 1
      Text = 'TANYJAEDIT'
      OnEnter = TNEVEDITEnter
      OnExit = TNEVEDITExit
      OnKeyDown = TiltNevEditKeyDown
    end
    object TSZULIDOEDIT: TEdit
      Tag = 3
      Left = 160
      Top = 136
      Width = 345
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 2
      Text = 'TSZULIDOEDIT'
      OnEnter = TNEVEDITEnter
      OnExit = TNEVEDITExit
      OnKeyDown = TiltNevEditKeyDown
    end
    object TSZULHELYEDIT: TEdit
      Tag = 4
      Left = 160
      Top = 160
      Width = 345
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 3
      Text = 'TSZULHELYEDIT'
      OnEnter = TNEVEDITEnter
      OnExit = TNEVEDITExit
      OnKeyDown = TiltNevEditKeyDown
    end
    object TGOMB: TBitBtn
      Left = 72
      Top = 216
      Width = 217
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYF'#201'L LETILT'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = TGombClick
    end
    object MEGEMGOMB: TBitBtn
      Left = 304
      Top = 216
      Width = 217
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM TILTOM LE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = MEGEMGOMBClick
    end
  end
  object FIGYELEMPANEL: TPanel
    Left = -1899
    Top = 40
    Width = 473
    Height = 185
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 2
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 473
      Height = 185
      Align = alClient
      Brush.Color = clRed
      Pen.Color = clMaroon
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 152
      Top = 24
      Width = 160
      Height = 27
      Caption = 'FIGYELEM !'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label10: TLabel
      Left = 80
      Top = 72
      Width = 286
      Height = 24
      Caption = 'A V'#193'LASZTOTT SZEM'#201'LY'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label11: TLabel
      Left = 112
      Top = 104
      Width = 243
      Height = 24
      Caption = 'M'#193'R LE VAN TILTVA !'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label12: TLabel
      Left = 8
      Top = 152
      Width = 282
      Height = 24
      Caption = 'OLDJAM FEL A TILT'#193'ST ?'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object IGENGOMB: TBitBtn
      Left = 296
      Top = 152
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IgenGombClick
    end
    object NEMGOMB: TBitBtn
      Left = 376
      Top = 152
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NEMGOMBClick
    end
  end
  object TTPANEL: TPanel
    Left = -1987
    Top = 80
    Width = 441
    Height = 273
    Color = clYellow
    TabOrder = 3
    Visible = False
    object Label13: TLabel
      Left = 48
      Top = 24
      Width = 381
      Height = 25
      Caption = 'V'#193'LASZTOTT SZEM'#201'LY ADATAI'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label14: TLabel
      Left = 68
      Top = 82
      Width = 33
      Height = 16
      Caption = 'Neve:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label15: TLabel
      Left = 34
      Top = 106
      Width = 67
      Height = 16
      Caption = 'Anyja neve:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label16: TLabel
      Left = 12
      Top = 154
      Width = 92
      Height = 16
      Caption = 'Sz'#252'let'#233'si helye:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label17: TLabel
      Left = 20
      Top = 130
      Width = 79
      Height = 16
      Caption = 'Sz'#252'let'#233'si id'#337':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label18: TLabel
      Left = 44
      Top = 178
      Width = 54
      Height = 16
      Caption = 'Lakc'#237'me:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object tnedit: TEdit
      Left = 104
      Top = 80
      Width = 305
      Height = 21
      TabOrder = 0
      Text = 'tnedit'
    end
    object TAEDIT: TEdit
      Left = 104
      Top = 104
      Width = 305
      Height = 21
      TabOrder = 1
      Text = 'TAEDIT'
    end
    object TIEDIT: TEdit
      Left = 104
      Top = 128
      Width = 305
      Height = 21
      TabOrder = 2
      Text = 'TIEDIT'
    end
    object THEDIT: TEdit
      Left = 104
      Top = 152
      Width = 305
      Height = 21
      TabOrder = 3
      Text = 'THEDIT'
    end
    object TLEDIT: TEdit
      Left = 104
      Top = 176
      Width = 305
      Height = 21
      TabOrder = 4
      Text = 'TLEDIT'
    end
    object LETILTOGOMB: TBitBtn
      Left = 56
      Top = 224
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYF'#201'L TILT'#193'SA'
      TabOrder = 5
      OnClick = TTMBClick
    end
    object TVISSZAGOMB: TBitBtn
      Left = 224
      Top = 224
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      TabOrder = 6
      OnClick = TVISSZAGOMBClick
    end
  end
  object JOGITILTOPANEL: TPanel
    Left = 100
    Top = 56
    Width = 569
    Height = 329
    BevelOuter = bvNone
    Color = clActiveCaption
    TabOrder = 4
    Visible = False
    object Label20: TLabel
      Left = 144
      Top = 8
      Width = 270
      Height = 21
      Caption = 'JOGI SZEM'#201'LY LET'#205'LT'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object Label24: TLabel
      Left = 48
      Top = 240
      Width = 182
      Height = 18
      Caption = 'V'#193'LASZTOTT '#220'GYF'#201'L:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object JOGITILTRACS: TDBGrid
      Left = 24
      Top = 40
      Width = 521
      Height = 161
      Cursor = crHandPoint
      DataSource = JOGITILTSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = JOGITILTRACSDblClick
      OnKeyDown = JOGITILTRACSKeyDown
      Columns = <
        item
          Expanded = False
          FieldName = 'JOGISZEMELYNEV'
          Title.Alignment = taCenter
          Title.Caption = 'JOGI SZEM'#201'LY'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 245
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TELEPHELYCIM'
          Title.Alignment = taCenter
          Title.Caption = 'TELEPHGELY'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 231
          Visible = True
        end>
    end
    object JOGITILTOGOMB: TBitBtn
      Left = 112
      Top = 280
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'LETILT'#193'S'
      TabOrder = 1
      OnClick = JogiTiltoGombClick
    end
    object JOGITILTMEGSEMGOMB: TBitBtn
      Left = 288
      Top = 280
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM,'
      TabOrder = 2
      OnClick = JOGITILTMEGSEMGOMBClick
    end
    object JMEGSEMGOMB: TBitBtn
      Left = 480
      Top = 256
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 4
      OnClick = JMEGSEMGOMBClick
    end
    object VALUGYFEDIT: TEdit
      Left = 240
      Top = 238
      Width = 209
      Height = 28
      BorderStyle = bsNone
      Color = clActiveCaption
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      Text = ' '
    end
    object TAKAROPANEL: TPanel
      Left = 40
      Top = 208
      Width = 441
      Height = 113
      BevelOuter = bvNone
      Color = clActiveCaption
      TabOrder = 3
      object Label21: TLabel
        Left = 32
        Top = 64
        Width = 99
        Height = 22
        Caption = 'KERESEM:'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWhite
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label23: TLabel
        Left = 56
        Top = 16
        Width = 362
        Height = 19
        Caption = 'V'#193'LASZT'#193'S -> DUPLA KLIKK VAGY ENTER'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object KERESOPANEL: TPanel
        Tag = 62
        Left = 144
        Top = 62
        Width = 113
        Height = 25
        BevelOuter = bvNone
        Color = clActiveCaption
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
  end
  object TILTOSOURCE: TDataSource
    DataSet = REMOTEQUERY
    Left = 176
    Top = 80
  end
  object BIZLATOKQUERY: TIBQuery
    Database = BIZLATOKDBASE
    Transaction = BIZLATOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 24
  end
  object BIZLATOKDBASE: TIBDatabase
    DatabaseName = 'C:\UCTRL\DATABASE\BIZLATOK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BIZLATOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 24
  end
  object BIZLATOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BIZLATOKDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 24
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 40
    Top = 72
  end
  object REMOTEDBASE: TIBDatabase
    Connected = True
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\UGYFEL22.FDB'
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
    Top = 72
  end
  object REMOTETRANZ: TIBTransaction
    Active = True
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 72
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 152
    Top = 32
  end
  object REMOTETABLA: TIBTable
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    MasterSource = TILTOSOURCE
    Left = 8
    Top = 72
  end
  object JOGITILTSOURCE: TDataSource
    DataSet = JOGIQUERY
    Left = 296
    Top = 192
  end
  object JOGIDBASE: TIBDatabase
    Connected = True
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\UGYFEL22.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = JOGITRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 128
  end
  object JOGITRANZ: TIBTransaction
    Active = True
    DefaultDatabase = JOGIDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 128
  end
  object JOGIQUERY: TIBQuery
    Database = JOGIDBASE
    Transaction = JOGITRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 128
  end
end
