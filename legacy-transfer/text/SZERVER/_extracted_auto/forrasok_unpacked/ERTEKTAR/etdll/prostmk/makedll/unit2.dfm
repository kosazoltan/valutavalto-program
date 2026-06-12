object PROSFORM: TPROSFORM
  Left = 192
  Top = 114
  AlphaBlendValue = 220
  BorderStyle = bsNone
  Caption = 'PROSFORM'
  ClientHeight = 375
  ClientWidth = 537
  Color = 6710886
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlue
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object PENZTAROSOKPANEL: TPanel
    Left = 0
    Top = 0
    Width = 536
    Height = 376
    BevelOuter = bvNone
    Color = 6710886
    TabOrder = 2
    object Shape4: TShape
      Left = 8
      Top = 8
      Width = 520
      Height = 360
      Brush.Color = clScrollBar
    end
    object Label7: TLabel
      Left = 40
      Top = 32
      Width = 458
      Height = 33
      Caption = 'P'#201'NZT'#193'ROSOK KARBANTART'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape5: TShape
      Left = 32
      Top = 315
      Width = 473
      Height = 41
      Shape = stRoundRect
    end
    object PENZTAROSOKRACS: TDBGrid
      Left = 32
      Top = 88
      Width = 473
      Height = 217
      Color = 16311512
      DataSource = PENZTAROSOKSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clBlue
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IDKOD'
          Title.Alignment = taCenter
          Title.Caption = 'ID-k'#243'dok'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 107
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTAROSNEV'
          Title.Alignment = taCenter
          Title.Caption = 'P'#233'nzt'#225'ros nevek'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -19
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsItalic]
          Width = 335
          Visible = True
        end>
    end
    object UJPENZTAROSGOMB: TBitBtn
      Left = 48
      Top = 323
      Width = 105
      Height = 25
      Cursor = crHandPoint
      Caption = #218'J P'#201'NZT'#193'ROS'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = UjPenztaros
    end
    object MODOSITASGOMB: TBitBtn
      Left = 155
      Top = 323
      Width = 107
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#211'DOSIT'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = MODOSITASGOMBClick
    end
    object PENZTAROSTORLOGOMB: TBitBtn
      Left = 264
      Top = 323
      Width = 142
      Height = 25
      Cursor = crHandPoint
      Caption = 'P'#201'NZT'#193'ROS T'#214'RL'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = PENZTAROSTORLOGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 408
      Top = 323
      Width = 81
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = VISSZAGOMBClick
    end
    object PENZTAROSKARTON: TPanel
      Left = 8
      Top = 8
      Width = 520
      Height = 360
      Color = clGradientInactiveCaption
      TabOrder = 5
      object Shape1: TShape
        Left = 24
        Top = 96
        Width = 473
        Height = 185
        Brush.Color = clGradientInactiveCaption
        Pen.Color = clNavy
        Pen.Width = 3
        Shape = stRoundRect
      end
      object Label1: TLabel
        Left = 48
        Top = 128
        Width = 167
        Height = 19
        Caption = 'P'#201'NZT'#193'ROS ID-K'#211'DJA:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label8: TLabel
        Left = 72
        Top = 168
        Width = 137
        Height = 19
        Caption = 'P'#201'NZT'#193'ROS NEVE:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label9: TLabel
        Left = 152
        Top = 200
        Width = 59
        Height = 19
        Caption = 'JELSZ'#211':'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label10: TLabel
        Left = 40
        Top = 232
        Width = 171
        Height = 19
        Caption = 'MEGISM'#201'TELT JELSZ'#211':'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Shape2: TShape
        Left = 112
        Top = 304
        Width = 329
        Height = 39
        Pen.Color = clNavy
        Pen.Width = 2
        Shape = stRoundRect
      end
      object KARTONFOCIMPANEL: TPanel
        Left = 40
        Top = 32
        Width = 481
        Height = 41
        BevelOuter = bvNone
        Caption = #218'J P'#201'NZT'#193'ROS FELV'#201'TELE'
        Color = clGradientInactiveCaption
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -29
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 0
      end
      object PROSIDEDIT: TEdit
        Left = 216
        Top = 120
        Width = 89
        Height = 37
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -23
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        MaxLength = 5
        ParentFont = False
        TabOrder = 1
        Text = '05532'
      end
      object PROSNEVEDIT: TEdit
        Left = 216
        Top = 160
        Width = 265
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        Text = 'PROSNEVEDIT'
        OnEnter = prosneveditEnter
        OnExit = prosneveditExit
      end
      object PASSWORDEDIT: TEdit
        Left = 216
        Top = 192
        Width = 121
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
        Text = 'PASSWORDEDIT'
        OnEnter = prosneveditEnter
        OnExit = prosneveditExit
        OnKeyDown = PASSWORDEDITKeyDown
      end
      object PASSWORD2EDIT: TEdit
        Left = 216
        Top = 224
        Width = 121
        Height = 27
        CharCase = ecUpperCase
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
        Text = 'PASSWORD2EDIT'
        OnEnter = prosneveditEnter
        OnExit = prosneveditExit
        OnKeyDown = PASSWORD2EDITKeyDown
      end
      object KARTONOKEGOMB: TBitBtn
        Left = 120
        Top = 312
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'ADATOK RENDBEN'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -15
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 5
        OnClick = KARTONOKEGOMBClick
      end
      object KARTONCANCELGOMB: TBitBtn
        Left = 280
        Top = 312
        Width = 153
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clNavy
        Font.Height = -15
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 6
        OnClick = KARTONCANCELGOMBClick
      end
    end
  end
  object modositopanel: TPanel
    Left = 8
    Top = 0
    Width = 520
    Height = 360
    TabOrder = 3
    object Label2: TLabel
      Left = 96
      Top = 40
      Width = 316
      Height = 43
      Caption = 'ADATM'#211'DOS'#205'T'#193'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 160
      Top = 144
      Width = 202
      Height = 22
      Caption = 'Mit szeretne m'#243'dos'#237'tani ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape3: TShape
      Left = 96
      Top = 192
      Width = 321
      Height = 105
      Pen.Width = 2
      Shape = stRoundRect
    end
    object nevpanel: TPanel
      Left = 24
      Top = 104
      Width = 473
      Height = 25
      BevelOuter = bvNone
      Caption = 'HERGER'#336'DERN'#201' KOV'#193'CS ESZMERALDA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object BitBtn2: TBitBtn
      Left = 104
      Top = 200
      Width = 305
      Height = 25
      Cursor = crHandPoint
      Caption = 'Nev'#233't vagy ID-K'#243'dj'#225't'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn2Click
    end
    object BitBtn3: TBitBtn
      Left = 104
      Top = 232
      Width = 305
      Height = 25
      Cursor = crHandPoint
      Caption = 'Jelszav'#225't'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = BitBtn3Click
    end
    object BitBtn4: TBitBtn
      Left = 104
      Top = 264
      Width = 305
      Height = 25
      Cursor = crHandPoint
      Caption = 'Semmit'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = BitBtn4Click
    end
  end
  object IDKODLISTAPANEL: TPanel
    Left = 8
    Top = 0
    Width = 521
    Height = 361
    Color = 12303291
    TabOrder = 1
    object IDKODLISTA: TListBox
      Left = 32
      Top = 64
      Width = 457
      Height = 249
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 0
      OnDblClick = IDKODLISTADblClick
      OnKeyUp = IDKODLISTAKeyUp
    end
    object BitBtn1: TBitBtn
      Left = 32
      Top = 325
      Width = 457
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#233'gsem v'#225'lasztok'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = BitBtn1Click
    end
    object LISTAFOCIM: TPanel
      Left = 24
      Top = 16
      Width = 473
      Height = 41
      BevelOuter = bvNone
      Caption = 'V'#225'lassza ki az '#250'j dolgoz'#243't'
      Color = 12303291
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
    end
  end
  object TORLESPANEL: TPanel
    Left = 48
    Top = 124
    Width = 433
    Height = 169
    BevelInner = bvRaised
    BevelWidth = 2
    Color = clRed
    TabOrder = 0
    object Label6: TLabel
      Left = 24
      Top = 16
      Width = 388
      Height = 20
      Caption = 'BIZTOS, HOGY T'#214'RLI  AZ AL'#193'BBI P'#201'NZT'#193'ROST ?'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object TORLESNEVPANEL: TPanel
      Left = 32
      Top = 56
      Width = 369
      Height = 33
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object TORLESIGENGOMB: TBitBtn
      Left = 80
      Top = 120
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN T'#214'RL'#214'M'
      TabOrder = 1
      OnClick = TORLESIGENGOMBClick
    end
    object TORLESNEMGOMB: TBitBtn
      Left = 248
      Top = 120
      Width = 139
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM T'#214'RL'#214'M'
      TabOrder = 2
      OnClick = TORLESNEMGOMBClick
    end
  end
  object PENZTAROSOKSOURCE: TDataSource
    DataSet = PENZTAROSOKQUERY
    Left = 472
    Top = 16
  end
  object PENZTAROSOKDBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PENZTAROSOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 384
    Top = 16
  end
  object PENZTAROSOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PENZTAROSOKDBASE
    AutoStopAction = saNone
    Left = 408
    Top = 16
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\ERTEKTAR\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 88
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 72
    Top = 48
  end
  object PENZTAROSOKQUERY: TIBQuery
    Database = PENZTAROSOKDBASE
    Transaction = PENZTAROSOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 440
    Top = 16
  end
end
