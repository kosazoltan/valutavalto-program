object PENZTARTMKFORM: TPENZTARTMKFORM
  Left = 219
  Top = 116
  AlphaBlend = True
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'PENZTARTMKFORM'
  ClientHeight = 417
  ClientWidth = 791
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 793
    Height = 417
    Brush.Color = clScrollBar
  end
  object Label1: TLabel
    Left = 160
    Top = 8
    Width = 464
    Height = 36
    Caption = 'P'#201'NZT'#193'RAK KARBANTART'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object ESCAPEGOMB: TBitBtn
    Left = 584
    Top = 376
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = ' VISSZA A F'#336'MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    OnClick = ESCAPEGOMBClick
  end
  object PENZTARRACS: TDBGrid
    Left = 8
    Top = 56
    Width = 769
    Height = 313
    BorderStyle = bsNone
    DataSource = PENZTARSOURCE
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    OnDblClick = PENZTARRACSDblClick
    OnKeyDown = PENZTARRACSKeyDown
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'PENZTARKOD'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'R'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 86
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'PENZTARNEV'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'R MEGNEVEZ'#201'SE'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 249
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'PENZTARCIM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'P'#201'NZT'#193'R CIME'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 257
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'TELEFONSZAM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'TELEFONSZ'#193'M'
        Title.Color = clGray
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clWhite
        Title.Font.Height = -16
        Title.Font.Name = 'Arial'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 148
        Visible = True
      end>
  end
  object TMKPANEL: TPanel
    Left = -1870
    Top = 100
    Width = 673
    Height = 249
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clScrollBar
    TabOrder = 2
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 673
      Height = 249
      Align = alClient
      Brush.Color = clSilver
      Pen.Width = 2
    end
    object Label2: TLabel
      Left = 200
      Top = 56
      Width = 166
      Height = 22
      Caption = 'P'#201'NZT'#193'R SZ'#193'MA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label3: TLabel
      Left = 16
      Top = 96
      Width = 246
      Height = 22
      Caption = 'P'#201'NZT'#193'R MEGNEVEZ'#201'SE:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label4: TLabel
      Left = 112
      Top = 128
      Width = 148
      Height = 22
      Caption = 'P'#201'NZT'#193'R C'#205'ME:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label5: TLabel
      Left = 264
      Top = 162
      Width = 160
      Height = 22
      Caption = 'TELEFONSZ'#193'MA:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object Label6: TLabel
      Left = 176
      Top = 16
      Width = 335
      Height = 31
      Caption = 'EGY P'#201'NZT'#193'R KARTONJA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PENZTARNEVEDIT: TEdit
      Tag = 2
      Left = 264
      Top = 96
      Width = 369
      Height = 26
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = []
      MaxLength = 25
      ParentFont = False
      TabOrder = 0
      OnEnter = PENZTARSZAMEDITEnter
      OnExit = PENZTARSZAMEDITExit
      OnKeyDown = PENZTARNEVEDITKeyDown
    end
    object PENZTARCIMEDIT: TEdit
      Tag = 3
      Left = 264
      Top = 128
      Width = 369
      Height = 24
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 40
      ParentFont = False
      TabOrder = 1
      OnEnter = PENZTARSZAMEDITEnter
      OnExit = PENZTARSZAMEDITExit
      OnKeyDown = PENZTARCIMEDITKeyDown
    end
    object TELEFONEDIT: TEdit
      Tag = 4
      Left = 432
      Top = 160
      Width = 201
      Height = 28
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 20
      ParentFont = False
      TabOrder = 2
      OnEnter = PENZTARSZAMEDITEnter
      OnExit = PENZTARSZAMEDITExit
      OnKeyDown = TELEFONEDITKeyDown
    end
    object RENDBENGOMB: TBitBtn
      Left = 232
      Top = 200
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = RENDBENGOMBClick
    end
    object megsemgomb: TBitBtn
      Left = 368
      Top = 200
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = megsemgombClick
    end
    object PENZTARSZAMEDIT: TEdit
      Tag = 1
      Left = 368
      Top = 56
      Width = 81
      Height = 30
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      MaxLength = 4
      ParentFont = False
      TabOrder = 5
      Text = 'ABCD'
      OnEnter = PENZTARSZAMEDITEnter
      OnExit = PENZTARSZAMEDITExit
      OnKeyDown = PenztarszamEditKeyDow
    end
  end
  object UJPENZTARGOMB: TBitBtn
    Left = 200
    Top = 376
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = #218'J P'#201'NZT'#193'R FELV'#201'TELE '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = UJPENZTARGOMBClick
  end
  object MODOSITOGOMB: TBitBtn
    Left = 8
    Top = 376
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'ADATOK M'#211'DOSIT'#193'SA '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 4
    OnClick = PenztarModositas
  end
  object PENZTARTORLESGOMB: TBitBtn
    Left = 392
    Top = 376
    Width = 185
    Height = 25
    Cursor = crHandPoint
    Caption = 'P'#201'NZT'#193'R T'#214'RL'#201'SE '
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -12
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 5
    OnClick = PENZTARTORLESGOMBClick
  end
  object SURETORLESPANEL: TPanel
    Left = -2200
    Top = 208
    Width = 473
    Height = 121
    BevelOuter = bvNone
    Color = clYellow
    TabOrder = 6
    object Shape3: TShape
      Left = 0
      Top = 0
      Width = 473
      Height = 121
      Align = alClient
      Brush.Color = clYellow
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label8: TLabel
      Left = 24
      Top = 16
      Width = 438
      Height = 22
      Caption = 'BIZTOSAN T'#214'R'#214'LJEM AZ AL'#193'BBI P'#201'NZT'#193'RT ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object DELPENZTARNEVPANEL: TPanel
      Left = 32
      Top = 48
      Width = 409
      Height = 25
      BevelOuter = bvNone
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object TOROLIGENGOMB: TBitBtn
      Left = 104
      Top = 80
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'T'#214'R'#214'LJ'#220'K !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = TOROLIGENGOMBClick
    end
    object TOROLNEMGOMB: TBitBtn
      Left = 240
      Top = 80
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM T'#214'RL'#214'K'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = TOROLNEMGOMBClick
    end
  end
  object PENZTARSOURCE: TDataSource
    DataSet = PENZTARQUERY
    Left = 80
    Top = 136
  end
  object inditotimer: TTimer
    Enabled = False
    OnTimer = inditotimerTimer
    Left = 48
    Top = 136
  end
  object PENZTARTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = PENZTARDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 184
  end
  object PENZTARDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = PENZTARTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 184
  end
  object PENZTARQUERY: TIBQuery
    Database = PENZTARDBASE
    Transaction = PENZTARTRANZ
    Active = True
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM PENZTAR')
    Left = 32
    Top = 184
  end
  object VALQUERY: TIBQuery
    Database = VALDBASE
    Transaction = VALTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 216
  end
  object VALDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 216
  end
  object VALTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 216
  end
end
