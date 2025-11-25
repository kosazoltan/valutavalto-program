object FORM2: TFORM2
  Left = 420
  Top = 214
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'FORM2'
  ClientHeight = 403
  ClientWidth = 644
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object HRKMENUPANEL: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 400
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 640
      Height = 400
      Align = alClient
      Brush.Color = clMoneyGreen
      Pen.Color = clTeal
      Pen.Width = 4
    end
    object Panel2: TPanel
      Left = 48
      Top = 56
      Width = 561
      Height = 41
      BevelOuter = bvNone
      Caption = 'HORV'#193'T KUNA H'#193'ZIP'#201'NZT'#193'R'
      Color = clMoneyGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clTeal
      Font.Height = -32
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object HRKATADGOMB: TBitBtn
      Left = 96
      Top = 144
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'HORV'#193'T KUNA BEK'#220'LD'#201'SE AZ '#201'RT'#201'KT'#193'RBA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = HRKATADGOMBClick
    end
    object HRKPILLGOMB: TBitBtn
      Left = 96
      Top = 184
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'HORV'#193'T KUNA JELENLEGI K'#201'SZLETE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = HRKPILLGOMBClick
    end
    object HRKBIZONYLATGOMB: TBitBtn
      Left = 88
      Top = 224
      Width = 449
      Height = 25
      Cursor = crHandPoint
      Caption = 'BIZONYLATOK MEGTEKINT'#201'SE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = HRKBIZONYLATGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 240
      Top = 312
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = VISSZAGOMBClick
    end
  end
  object PILLKEZDIJPANEL: TPanel
    Left = -1500
    Top = 136
    Width = 529
    Height = 209
    BevelOuter = bvNone
    TabOrder = 3
    Visible = False
    object Shape9: TShape
      Left = 0
      Top = 0
      Width = 529
      Height = 209
      Align = alClient
      Brush.Color = 11599871
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label21: TLabel
      Left = 24
      Top = 32
      Width = 476
      Height = 24
      Caption = 'A KEZEL'#201'SI K'#214'LTS'#201'G PILLANATNYI K'#201'SZLETE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object PILLOSSZEGPANEL: TPanel
      Left = 136
      Top = 88
      Width = 289
      Height = 41
      BevelOuter = bvNone
      Color = 11599871
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object PillKeszBackGomb: TBitBtn
      Left = 224
      Top = 152
      Width = 115
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = PillKeszBackGombClick
    end
  end
  object KEZELESIFOPANEL: TPanel
    Left = -1987
    Top = 110
    Width = 589
    Height = 273
    BevelOuter = bvNone
    Color = clGreen
    TabOrder = 1
    Visible = False
    object Shape7: TShape
      Left = 0
      Top = 0
      Width = 589
      Height = 273
      Align = alClient
      Brush.Color = clGreen
      Pen.Color = clYellow
      Pen.Width = 5
    end
    object Label11: TLabel
      Left = 152
      Top = 112
      Width = 168
      Height = 28
      Caption = 'Bizonylat sz'#225'ma:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 128
      Top = 40
      Width = 374
      Height = 36
      Caption = 'HORV'#193'T KUNA '#193'TAD'#193'SA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 144
      Top = 152
      Width = 173
      Height = 31
      Caption = #193'tadott '#246'sszeg:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 464
      Top = 155
      Width = 57
      Height = 31
      Caption = 'HRK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object KEZBIZPANEL: TPanel
      Left = 328
      Top = 112
      Width = 105
      Height = 29
      Caption = 'K-00666'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object KUNAEDIT: TEdit
      Left = 328
      Top = 156
      Width = 129
      Height = 37
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      Text = '125351000'
      OnEnter = KUNAEDITEnter
      OnExit = KUNAEDITExit
      OnKeyDown = KUNAEDITKeyDown
    end
    object KONYVELOGOMB: TBitBtn
      Left = 160
      Top = 224
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'NYVEL'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KONYVELOGOMBClick
    end
    object KEZKONYVMEGSEMGOMB: TBitBtn
      Left = 328
      Top = 224
      Width = 145
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = KEZKONYVMEGSEMGOMBClick
    end
  end
  object BIZONYLATPANEL: TPanel
    Left = -1987
    Top = 0
    Width = 640
    Height = 400
    BevelOuter = bvNone
    BevelWidth = 3
    Color = 6776679
    TabOrder = 2
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 640
      Height = 400
      Align = alClient
      Brush.Color = 16311512
      Pen.Width = 5
    end
    object HRKRACS: TDBGrid
      Left = 32
      Top = 64
      Width = 569
      Height = 265
      DataSource = HRKSOURCE
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
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
      OnCellClick = HrkRacsCellClick
      OnDblClick = HrkRacsDblClick
      OnKeyUp = HrkRacsKeyUp
      OnMouseUp = HrkRacsMouseUp
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 85
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IDO'
          Title.Alignment = taCenter
          Title.Caption = 'ID'#336
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 57
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BEVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'BEV'#201'TEL'
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 102
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'KIADAS'
          Title.Alignment = taCenter
          Title.Caption = 'KIAD'#193'S'
          Title.Color = clYellow
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 98
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'BIZONYLAT'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 125
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAR'
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'R'
          Title.Color = clYellow
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -16
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 71
          Visible = True
        end>
    end
    object STORNOGOMB: TBitBtn
      Left = 32
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Bizonylat storn'#243
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = STORNOGOMBClick
    end
    object LISTAVISSZAGOMB: TBitBtn
      Left = 472
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Vissza a men'#369're'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = LISTAVISSZAGOMBClick
    end
    object KEZBIZONYFOCIMPANEL: TPanel
      Left = 40
      Top = 16
      Width = 481
      Height = 41
      BevelOuter = bvNone
      Caption = 'A horv'#225't kuna forgalmi bizonylatai'
      Color = 13684944
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object STORNOPANEL: TPanel
      Left = 224
      Top = 280
      Width = 185
      Height = 41
      Caption = 'STORNO'
      Color = clYellow
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -37
      Font.Name = 'Arial Rounded MT Bold'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object REPRINTGOMB: TBitBtn
      Left = 248
      Top = 344
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'Nyomtat'#225's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = REPRINTGOMBClick
    end
    object surepanel: TPanel
      Left = 176
      Top = 136
      Width = 305
      Height = 161
      Color = clGray
      TabOrder = 6
      Visible = False
      object Label4: TLabel
        Left = 16
        Top = 16
        Width = 280
        Height = 19
        Caption = 'BIZTOSAN STORNOZZA A BIZONYLATOT ?'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWhite
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object SIGENGOMB: TBitBtn
        Left = 48
        Top = 40
        Width = 99
        Height = 25
        Cursor = crHandPoint
        Caption = 'IGEN'
        TabOrder = 0
        OnClick = SIGENGOMBClick
      end
      object SNEMGOMB: TBitBtn
        Left = 160
        Top = 40
        Width = 97
        Height = 25
        Cursor = crHandPoint
        Caption = 'M'#201'GSEM'
        TabOrder = 1
      end
      object SUREFEDEL: TPanel
        Left = -72
        Top = 40
        Width = 281
        Height = 113
        BevelOuter = bvNone
        Color = clGray
        TabOrder = 2
        Visible = False
        object Label5: TLabel
          Left = 16
          Top = 24
          Width = 54
          Height = 18
          Caption = 'INDOKA:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWhite
          Font.Height = -15
          Font.Name = 'Calibri'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object STORNOEDIT: TEdit
          Left = 80
          Top = 24
          Width = 169
          Height = 21
          CharCase = ecUpperCase
          TabOrder = 0
          OnEnter = KUNAEDITEnter
          OnExit = KUNAEDITExit
          OnKeyDown = STORNOEDITKeyDown
        end
        object STORNOGOGOMB: TButton
          Left = 8
          Top = 72
          Width = 129
          Height = 25
          Cursor = crHandPoint
          Caption = 'STORN'#211' MEHET'
          TabOrder = 1
          OnClick = STORNOGOGOMBClick
        end
        object STORNONOGOMB: TBitBtn
          Left = 144
          Top = 72
          Width = 129
          Height = 25
          Cursor = crHandPoint
          Caption = 'M'#201'GSEM'
          TabOrder = 2
        end
      end
    end
  end
  object HRKSOURCE: TDataSource
    DataSet = HRKQUERY
    Left = 160
    Top = 104
  end
  object HRKDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\HAZIHRK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HRKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 104
  end
  object HRKTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = HRKDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 128
    Top = 104
  end
  object HRKQUERY: TIBQuery
    Database = HRKDBASE
    Transaction = HRKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 64
    Top = 104
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 360
    Top = 104
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 392
    Top = 104
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 424
    Top = 104
  end
  object NAPLOQUERY: TIBQuery
    Database = NAPLODBASE
    Transaction = NAPLOTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 24
    Top = 24
  end
  object NAPLODBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\HAZIHRK.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = NAPLOTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 24
  end
  object NAPLOTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = NAPLODBASE
    AutoStopAction = saNone
    Left = 88
    Top = 24
  end
end
