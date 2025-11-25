object STORNOFORM: TSTORNOFORM
  Left = 190
  Top = 119
  BorderStyle = bsNone
  Caption = 'STORNOFORM'
  ClientHeight = 517
  ClientWidth = 612
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  OnActivate = FormActivate
  OnKeyPress = FormKeyPress
  PixelsPerInch = 96
  TextHeight = 13
  object Label10: TLabel
    Left = 80
    Top = 8
    Width = 468
    Height = 35
    Caption = 'MAI BIZONYLAT STORN'#211'JA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = 'Elephant'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Panel1: TPanel
    Left = 16
    Top = 48
    Width = 577
    Height = 449
    BevelOuter = bvNone
    Color = clGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 0
    object Label8: TLabel
      Left = 32
      Top = 24
      Width = 516
      Height = 31
      Caption = 'V'#193'LASSZA KI A STORN'#211'ZAND'#211' BIZONYLATOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label9: TLabel
      Left = 72
      Top = 352
      Width = 139
      Height = 34
      Caption = 'Bizonylat:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -29
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 400
      Top = 352
      Width = 128
      Height = 32
      Caption = 'keres'#233'se ...'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object radiok: TGroupBox
      Left = 24
      Top = 64
      Width = 193
      Height = 281
      Caption = ' '
      TabOrder = 5
      OnClick = radiokClick
    end
    object BIZONYLATRACS: TDBGrid
      Left = 224
      Top = 76
      Width = 329
      Height = 267
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 11599871
      DataSource = STORNOSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnDblClick = BIZONYLATRACSDblClick
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'BIZONYLATSZAM'
          ReadOnly = True
          Title.Alignment = taCenter
          Title.Caption = 'BIZONYLAT'
          Title.Color = clBlack
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -21
          Title.Font.Name = 'Arial'
          Title.Font.Style = [fsBold]
          Width = 141
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'FIZETENDO'
          ReadOnly = True
          Title.Alignment = taCenter
          Title.Caption = #214'SSZEG'
          Title.Color = clBlack
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -21
          Title.Font.Name = 'Arial'
          Title.Font.Style = [fsBold]
          Width = 151
          Visible = True
        end>
    end
    object VR: TRadioButton
      Left = 32
      Top = 128
      Width = 161
      Height = 17
      Caption = 'Valuta v'#233'tele'
      Checked = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      TabStop = True
      OnClick = VRClick
    end
    object ER: TRadioButton
      Left = 32
      Top = 168
      Width = 177
      Height = 17
      Caption = 'Valuta elad'#225'sa'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ERClick
    end
    object UR: TRadioButton
      Left = 32
      Top = 248
      Width = 169
      Height = 17
      Caption = 'P'#233'nz '#225'tv'#233'tele'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = URClick
    end
    object FR: TRadioButton
      Left = 32
      Top = 296
      Width = 177
      Height = 17
      Caption = 'P'#233'nz '#225'tad'#225'sa'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = FRClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 16
      Top = 408
      Width = 257
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA A MEN'#220'RE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = VISSZAGOMBClick
    end
    object STORNOGOMB: TBitBtn
      Left = 280
      Top = 408
      Width = 275
      Height = 25
      Cursor = crHandPoint
      Caption = 'EZT A BIZONYLATOT STORN'#211'ZOM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      OnClick = STORNOGOMBClick
    end
    object BIZELOPANEL: TPanel
      Left = 224
      Top = 354
      Width = 81
      Height = 33
      BevelOuter = bvNone
      Caption = 'UF143'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 8
    end
    object bizvegedit: TEdit
      Left = 304
      Top = 353
      Width = 89
      Height = 37
      Enabled = False
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 9
    end
  end
  object surepanel: TPanel
    Left = -1874
    Top = 120
    Width = 289
    Height = 201
    BevelOuter = bvNone
    Color = clRed
    TabOrder = 1
    Visible = False
    object Label2: TLabel
      Left = 40
      Top = 24
      Width = 219
      Height = 22
      Caption = 'BIZTOSAN STORN'#211'ZZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 48
      Top = 104
      Width = 208
      Height = 22
      Caption = 'SZ'#193'M'#218' BIZONYLATOT'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object SUREBIZSZAMPANEL: TPanel
      Left = 56
      Top = 56
      Width = 185
      Height = 41
      BevelOuter = bvNone
      Caption = 'V143123456'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object IGENGOMB: TBitBtn
      Left = 16
      Top = 152
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      TabOrder = 1
      OnClick = IGENGOMBClick
    end
    object NEMGOMB: TBitBtn
      Left = 152
      Top = 152
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      TabOrder = 2
      OnClick = NEMGOMBClick
    end
  end
  object VEGPANEL: TPanel
    Left = -222
    Top = 72
    Width = 417
    Height = 305
    Color = clWhite
    TabOrder = 2
    Visible = False
    object Label4: TLabel
      Left = 32
      Top = 16
      Width = 358
      Height = 23
      Caption = 'EGY BIZONYLAT '#201'RV'#201'NYTELEN'#205'T'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 80
      Top = 64
      Width = 130
      Height = 23
      Caption = 'Bizonylatsz'#225'm:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 80
      Top = 120
      Width = 126
      Height = 21
      Caption = 'Bizonylat '#233'rt'#233'ke:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label12: TLabel
      Left = 72
      Top = 216
      Width = 137
      Height = 21
      Caption = 'Storn'#243'z'#225's indoka:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 104
      Top = 168
      Width = 100
      Height = 21
      Caption = 'Nyugtasz'#225'm:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object BIZSZAMPANEL: TPanel
      Left = 216
      Top = 56
      Width = 129
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object ERTEKPANEL: TPanel
      Left = 216
      Top = 112
      Width = 161
      Height = 33
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object STARTGOMB: TBitBtn
      Left = 24
      Top = 264
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'STORN'#211'Z'#193'S INDUL'
      TabOrder = 2
      OnClick = STARTGOMBClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 216
      Top = 264
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 3
      OnClick = MEGSEMGOMBClick
    end
    object INDOKEDIT: TEdit
      Left = 216
      Top = 218
      Width = 161
      Height = 27
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      MaxLength = 10
      ParentFont = False
      TabOrder = 4
      OnKeyDown = INDOKEDITKeyDown
    end
    object nyugtapanel: TPanel
      Left = 216
      Top = 159
      Width = 129
      Height = 41
      BevelOuter = bvNone
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
    object NYUGTATAKARO: TPanel
      Left = -888
      Top = 158
      Width = 353
      Height = 57
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 6
    end
  end
  object FUGGONY: TPanel
    Left = -1850
    Top = 16
    Width = 537
    Height = 417
    BevelOuter = bvNone
    Color = clGray
    TabOrder = 4
    Visible = False
  end
  object LASTKERDOPANEL: TPanel
    Left = -1450
    Top = 168
    Width = 513
    Height = 105
    BevelOuter = bvNone
    TabOrder = 3
    Visible = False
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 513
      Height = 105
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 3
    end
    object Label11: TLabel
      Left = 32
      Top = 24
      Width = 465
      Height = 24
      Caption = 'A NAV BIZONYLAT RENDBEN KINYOMODOTT ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object maystornogomb: TBitBtn
      Left = 56
      Top = 64
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN KINYOMODOTT'
      TabOrder = 0
    end
    object nosuccessgomb: TBitBtn
      Left = 264
      Top = 64
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM SIKER'#220'LT A NYOMTAT'#193'S'
      TabOrder = 1
      OnClick = NEMGOMBClick
    end
  end
  object KISUGYFELPANEL: TPanel
    Left = 248
    Top = 280
    Width = 313
    Height = 41
    Caption = 'KIS'#220'GYF'#201'L VISSZAVON'#193'S'
    Color = clBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
    Visible = False
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    Active = True
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM BLOKKFEJ')
    Left = 288
    Top = 240
  end
  object VALUTADBASE: TIBDatabase
    Connected = True
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
    Left = 320
    Top = 240
  end
  object VALUTATRANZ: TIBTransaction
    Active = True
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 352
    Top = 240
  end
  object STORNOSOURCE: TDataSource
    DataSet = TEMPQUERY
    Left = 496
    Top = 192
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 192
    object TEMPQUERYBIZONYLATSZAM: TIBStringField
      FieldName = 'BIZONYLATSZAM'
      Origin = 'BLOKKFEJ.BIZONYLATSZAM'
      FixedChar = True
      Size = 10
    end
    object TEMPQUERYFIZETENDO: TIntegerField
      FieldName = 'FIZETENDO'
      Origin = 'BLOKKFEJ.FIZETENDO'
      DisplayFormat = '### ### ###'
    end
  end
  object TEMPDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 192
  end
  object TEMPTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = TEMPDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 320
    Top = 192
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 240
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 464
    Top = 192
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 256
    Top = 352
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 288
    Top = 352
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 320
    Top = 352
  end
end
