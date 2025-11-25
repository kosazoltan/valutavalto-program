object Form1: TForm1
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form1'
  ClientHeight = 466
  ClientWidth = 460
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
  object ALAPPANEL: TPanel
    Left = 0
    Top = 0
    Width = 457
    Height = 465
    Color = clNavy
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object Label1: TLabel
      Left = 64
      Top = 200
      Width = 63
      Height = 21
      Caption = 'Label1'
    end
    object Shape1: TShape
      Left = 1
      Top = 1
      Width = 455
      Height = 463
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label2: TLabel
      Left = 96
      Top = 32
      Width = 266
      Height = 23
      Caption = 'V'#225'lassza ki a k'#237'v'#225'nt h'#243'napot'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
    end
    object E3: TPanel
      Tag = 3
      Left = 72
      Top = 344
      Width = 153
      Height = 92
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '2021'
      Color = clMoneyGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -37
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = E1Click
      OnMouseMove = E1MouseMove
    end
    object E2: TPanel
      Tag = 2
      Left = 72
      Top = 248
      Width = 153
      Height = 89
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '2020'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -37
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = E1Click
      OnMouseMove = E1MouseMove
    end
    object E1: TPanel
      Tag = 1
      Left = 72
      Top = 152
      Width = 153
      Height = 89
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = '2019'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -37
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = E1Click
      OnMouseMove = E1MouseMove
    end
    object H7: TPanel
      Tag = 7
      Left = 232
      Top = 296
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'J'#250'lius'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H1: TPanel
      Tag = 1
      Left = 232
      Top = 152
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Janu'#225'r'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H8: TPanel
      Tag = 8
      Left = 232
      Top = 320
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Augusztus'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H4: TPanel
      Tag = 4
      Left = 232
      Top = 224
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = #193'prilis'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H6: TPanel
      Tag = 6
      Left = 232
      Top = 272
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Junius'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object FEJPANEL: TPanel
      Left = 72
      Top = 64
      Width = 313
      Height = 81
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 8
      object DATUMPANEL: TPanel
        Left = 8
        Top = 16
        Width = 297
        Height = 25
        BevelOuter = bvNone
        Caption = '2021 Szeptember'
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clRed
        Font.Height = -19
        Font.Name = 'Elephant'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object HONAPOKEGOMB: TBitBtn
        Left = 8
        Top = 48
        Width = 145
        Height = 25
        Cursor = crHandPoint
        Caption = 'H'#243'nap rendben'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 1
        OnClick = HONAPOKEGOMBClick
      end
      object EXITGOMB: TBitBtn
        Left = 160
        Top = 48
        Width = 145
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#233'gsem'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 2
        OnClick = EXITGOMBClick
      end
    end
    object H2: TPanel
      Tag = 2
      Left = 232
      Top = 176
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Febru'#225'r'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H3: TPanel
      Tag = 3
      Left = 232
      Top = 200
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'M'#225'rcius'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H5: TPanel
      Tag = 5
      Left = 232
      Top = 248
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'M'#225'jus'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H9: TPanel
      Tag = 9
      Left = 232
      Top = 344
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Szeptember'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 12
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H10: TPanel
      Tag = 10
      Left = 232
      Top = 368
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'Okt'#243'ber'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 13
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object H11: TPanel
      Tag = 11
      Left = 232
      Top = 392
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'November'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 14
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object h12: TPanel
      Tag = 12
      Left = 232
      Top = 416
      Width = 153
      Height = 21
      Cursor = crHandPoint
      BevelOuter = bvNone
      Caption = 'December'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clSilver
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      TabOrder = 15
      OnClick = H1Click
      OnMouseMove = H1MouseMove
    end
    object TAKARO: TPanel
      Left = -1589
      Top = 8
      Width = 441
      Height = 449
      Color = clWhite
      TabOrder = 16
      Visible = False
      object Label3: TLabel
        Left = 128
        Top = 72
        Width = 201
        Height = 24
        Caption = 'ADATLEGY'#220'JT'#201'S'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object AKTDATUMPANEL: TPanel
        Left = 8
        Top = 16
        Width = 425
        Height = 41
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -29
        Font.Name = 'Elephant'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object PROGRESSPANEL: TPanel
        Left = 8
        Top = 136
        Width = 425
        Height = 41
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        TabOrder = 1
      end
      object CSIK: TProgressBar
        Left = 8
        Top = 336
        Width = 425
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 2
      end
      object PROG2PANEL: TPanel
        Left = 8
        Top = 184
        Width = 425
        Height = 41
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 3
      end
      object PROG3PANEL: TPanel
        Left = 8
        Top = 232
        Width = 425
        Height = 41
        BevelOuter = bvNone
        Color = clWhite
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 4
      end
      object CSIK2: TProgressBar
        Left = 8
        Top = 368
        Width = 425
        Height = 17
        Min = 0
        Max = 100
        Smooth = True
        TabOrder = 5
      end
    end
  end
  object EXISTPANEL: TPanel
    Left = 1598
    Top = 112
    Width = 409
    Height = 337
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 1
    Visible = False
    object Label4: TLabel
      Left = 40
      Top = 32
      Width = 345
      Height = 22
      Caption = 'A v'#225'lasztott havi excelt'#225'bl'#225'k m'#225'r l'#233'teznek !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 328
      Top = 312
      Width = 59
      Height = 13
      BiDiMode = bdRightToLeft
      Caption = 'dek@nySoft'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentBiDiMode = False
      ParentFont = False
    end
    object REMAKEGOMB: TBitBtn
      Left = 24
      Top = 72
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = #218'JRA K'#201'SZ'#205'TS'#220'K EL'
      TabOrder = 0
      OnClick = REMAKEGOMBClick
    end
    object OPENGOMB: TBitBtn
      Left = 200
      Top = 72
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'EXCEL MEGNYIT'#193'SA'
      TabOrder = 1
      OnClick = OPENGOMBClick
    end
    object VEGEGOMB: TBitBtn
      Left = 112
      Top = 112
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGYIK SEM'
      TabOrder = 2
      OnClick = EXITGOMBClick
    end
    object OPENPANEL: TPanel
      Left = -1589
      Top = 24
      Width = 393
      Height = 193
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 3
      Visible = False
      object Label6: TLabel
        Left = 72
        Top = 24
        Width = 253
        Height = 19
        Caption = 'EXCEL T'#193'BL'#193'K MEGNYIT'#193'SA'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Cooper Black'
        Font.Style = []
        ParentFont = False
      end
      object Label7: TLabel
        Left = 64
        Top = 72
        Width = 255
        Height = 21
        Caption = 'Melyik excelt'#225'bl'#225't nyissam meg ?'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object FORGTABLAGOMB: TBitBtn
        Left = 32
        Top = 112
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = 'FORGALMI T'#193'BL'#193'T'
        TabOrder = 0
        OnClick = FORGTABLAGOMBClick
      end
      object ATADTABLAGOMB: TBitBtn
        Left = 208
        Top = 112
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Cancel = True
        Caption = #193'TAD-'#193'TV'#201'T R'#201'SZLETEZ'#336'T'
        TabOrder = 1
        OnClick = ATADTABLAGOMBClick
      end
      object EGYIKETSEGOMB: TBitBtn
        Left = 208
        Top = 144
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = 'EGYIKET SE'
        TabOrder = 2
        OnClick = EGYIKETSEGOMBClick
      end
      object NYITOGOMB: TBitBtn
        Left = 32
        Top = 144
        Width = 161
        Height = 25
        Cursor = crHandPoint
        Caption = 'NYIT'#211'  K'#201'SZLETT'#193'BL'#193'T'
        TabOrder = 3
        OnClick = NYITOGOMBClick
      end
    end
  end
  object FINISHPANEL: TPanel
    Left = -1987
    Top = 192
    Width = 425
    Height = 257
    BevelOuter = bvNone
    TabOrder = 2
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 257
      Align = alClient
      Pen.Color = clSilver
      Pen.Width = 5
    end
    object Label8: TLabel
      Left = 48
      Top = 16
      Width = 312
      Height = 24
      Caption = '3 EXCEL-FILE-T K'#201'SZ'#205'TETTEM'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
    end
    object Label9: TLabel
      Left = 80
      Top = 72
      Width = 204
      Height = 21
      Caption = 'C:\BOOKING\EXCEL'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object Label10: TLabel
      Left = 176
      Top = 48
      Width = 55
      Height = 21
      Caption = 'hely'#252'k:'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
    end
    object Label11: TLabel
      Left = 288
      Top = 70
      Width = 76
      Height = 24
      Caption = 'k'#246'nyvt'#225'r'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentColor = False
      ParentFont = False
    end
    object Label12: TLabel
      Left = 176
      Top = 96
      Width = 50
      Height = 21
      Caption = 'nev'#252'k:'
      Color = clWhite
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentColor = False
      ParentFont = False
    end
    object XLS1PANEL: TPanel
      Left = 8
      Top = 120
      Width = 393
      Height = 25
      BevelOuter = bvNone
      Caption = 'FORG2021.XLS'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object XLS2PANEL: TPanel
      Left = 8
      Top = 152
      Width = 393
      Height = 25
      BevelOuter = bvNone
      Caption = 'ADVET2021.XLS'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object FINISHGOMB: TBitBtn
      Left = 120
      Top = 216
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'KIL'#201'P'#201'S'
      Default = True
      TabOrder = 2
      OnClick = FINISHGOMBClick
    end
    object XLS3PANEL: TPanel
      Left = 8
      Top = 184
      Width = 393
      Height = 25
      BevelOuter = bvNone
      Caption = 'XLS3PANEL'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
    end
  end
  object HIBAPANEL: TPanel
    Left = -1897
    Top = 8
    Width = 441
    Height = 449
    TabOrder = 3
    Visible = False
    object Label13: TLabel
      Left = 80
      Top = 16
      Width = 250
      Height = 36
      Caption = 'HIBAJEGYZ'#201'K'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
    end
    object HIBALISTA: TListBox
      Left = 16
      Top = 64
      Width = 409
      Height = 337
      Color = 11599871
      ItemHeight = 13
      TabOrder = 0
    end
    object VISSZAGOMB: TBitBtn
      Left = 16
      Top = 416
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GIS LEGYEN EXCEL'
      TabOrder = 1
      OnClick = VISSZAGOMBClick
    end
    object BitBtn1: TBitBtn
      Left = 224
      Top = 416
      Width = 201
      Height = 25
      Cursor = crHandPoint
      Caption = 'BEFEJEZ'#201'S'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 232
    Top = 368
  end
  object REMOTEDBASE: TIBDatabase
    DatabaseName = '185.43.207.99:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 168
    Top = 368
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 416
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 368
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = ':'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 264
    Top = 376
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 200
    Top = 368
  end
  object BOOKQUERY: TIBQuery
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 48
    Top = 16
  end
  object BOOKDBASE: TIBDatabase
    DatabaseName = 'C:\BOOKING\DATABASE\BOOKING.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = BOOKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 48
  end
  object BOOKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BOOKDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 48
  end
  object REMOTETABLA: TIBTable
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 64
    Top = 408
  end
  object BOOKTABLA: TIBTable
    Database = BOOKDBASE
    Transaction = BOOKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    StoreDefs = True
    Left = 16
    Top = 16
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 128
    Top = 408
  end
  object IBQUERY: TIBQuery
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 56
  end
  object IBDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = IBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 408
    Top = 88
  end
  object IBTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = IBDBASE
    AutoStopAction = saNone
    Left = 408
    Top = 120
  end
  object IBTABLA: TIBTable
    Database = IBDBASE
    Transaction = IBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 408
    Top = 24
  end
end
