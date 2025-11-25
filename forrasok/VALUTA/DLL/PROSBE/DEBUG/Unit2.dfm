object PROSBELEP: TPROSBELEP
  Left = 199
  Top = 123
  AlphaBlendValue = 200
  BorderStyle = bsNone
  ClientHeight = 316
  ClientWidth = 641
  Color = clBlack
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
  object BIZTOSPANEL: TPanel
    Left = 0
    Top = 0
    Width = 649
    Height = 321
    BevelOuter = bvNone
    Color = 5592405
    TabOrder = 2
    object Label6: TLabel
      Left = 240
      Top = 16
      Width = 159
      Height = 36
      Caption = 'Biztos, hogy'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 272
      Top = 112
      Width = 89
      Height = 36
      Caption = 'azonos'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape2: TShape
      Left = 144
      Top = 208
      Width = 369
      Height = 73
      Brush.Color = 10066329
      Pen.Width = 2
      Shape = stRoundRect
    end
    object ELSONEVPANEL: TPanel
      Left = 64
      Top = 64
      Width = 537
      Height = 41
      BevelOuter = bvNone
      Caption = 'KOVACSN'#201' HERGER'#214'DER VILMALLE'
      Color = 5592405
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object HASNEVPANEL: TPanel
      Left = 56
      Top = 152
      Width = 545
      Height = 41
      BevelOuter = bvNone
      Caption = 'KOV'#193'CSN'#201' H. ALADAR LAJOSNE-VAL'
      Color = 5592405
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object SAMEPERSONGOMB: TBitBtn
      Left = 152
      Top = 216
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'A K'#201'T N'#201'V UGYANAZ A SZEM'#201'LY'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = SAMEPERSONGOMBClick
    end
    object MISTAKEGOMB: TBitBtn
      Left = 152
      Top = 248
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'ELT'#201'VESZTETTEM A JEL'#214'L'#201'ST'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = MISTAKEGOMBClick
    end
  end
  object PENZTAROSLISTAPANEL: TPanel
    Left = 0
    Top = -8
    Width = 649
    Height = 321
    BevelOuter = bvNone
    Color = 10066329
    TabOrder = 3
    object Shape6: TShape
      Left = 32
      Top = 56
      Width = 577
      Height = 201
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape7: TShape
      Left = 240
      Top = 264
      Width = 169
      Height = 48
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Panel1: TPanel
      Left = 16
      Top = 8
      Width = 617
      Height = 41
      BevelOuter = bvNone
      Caption = 'P'#233'nzt'#225'rosok list'#225'ja'
      Color = 10066329
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -37
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object PROSRACS: TDBGrid
      Left = 48
      Top = 64
      Width = 545
      Height = 177
      BorderStyle = bsNone
      DataSource = PROSSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnCellClick = PROSRACSCellClick
      OnDblClick = PROSRACSDblClick
      OnKeyDown = PROSRACSKeyDown
      Columns = <
        item
          Expanded = False
          FieldName = 'PENZTAROSNEV'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -24
          Font.Name = 'Times New Roman'
          Font.Style = [fsItalic]
          Title.Alignment = taCenter
          Title.Caption = 'Regisztr'#225'lt p'#233'nzt'#225'rosok'
          Title.Color = 11599871
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -32
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 520
          Visible = True
        end>
    end
    object KILEPOGOMB: TBitBtn
      Left = 248
      Top = 272
      Width = 153
      Height = 33
      Cursor = crHandPoint
      Caption = 'Kil'#233'p'#233's'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KILEPOGOMBClick
    end
  end
  object JELSZOPANEL: TPanel
    Left = 128
    Top = 0
    Width = 649
    Height = 257
    BevelOuter = bvNone
    Color = 7829367
    TabOrder = 0
    object Label2: TLabel
      Left = 112
      Top = 128
      Width = 155
      Height = 27
      Caption = 'P'#233'nzt'#225'ros neve:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label1: TLabel
      Left = 64
      Top = 176
      Width = 205
      Height = 27
      Caption = 'A p'#233'nzt'#225'ros jelszava:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      OnDblClick = Label1DblClick
    end
    object Label3: TLabel
      Left = 160
      Top = 40
      Width = 346
      Height = 41
      Caption = 'A JELSZ'#211' BEK'#201'R'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -35
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Shape4: TShape
      Left = 280
      Top = 174
      Width = 297
      Height = 33
      Pen.Width = 2
    end
    object Shape5: TShape
      Left = 280
      Top = 120
      Width = 297
      Height = 33
      Pen.Width = 2
    end
    object prosnevedit: TEdit
      Left = 288
      Top = 123
      Width = 273
      Height = 28
      BorderStyle = bsNone
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      MaxLength = 28
      ParentFont = False
      TabOrder = 0
    end
    object jelszoedit: TEdit
      Left = 288
      Top = 180
      Width = 225
      Height = 21
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
      PasswordChar = '#'
      TabOrder = 1
      Text = 'JELSZOEDIT'
      OnEnter = jelszoeditEnter
      OnExit = jelszoeditExit
      OnKeyDown = JELSZOEDITKeyDown
    end
  end
  object LISTAPANEL: TPanel
    Left = 440
    Top = 0
    Width = 649
    Height = 321
    BevelOuter = bvNone
    Color = 4473924
    TabOrder = 1
    object Label4: TLabel
      Left = 88
      Top = 0
      Width = 466
      Height = 31
      Caption = 'M'#233'g nincs r'#246'gzitve a  k'#246'zponti ID-k'#243'dot !'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 168
      Top = 40
      Width = 324
      Height = 21
      Caption = 'V'#225'laszd ki magadat az ID-k'#243'd t'#225'bl'#225'zatb'#243'l'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Shape3: TShape
      Left = 80
      Top = 72
      Width = 489
      Height = 177
      Brush.Color = 7829367
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Shape1: TShape
      Left = 185
      Top = 267
      Width = 280
      Height = 35
      Pen.Width = 2
      Shape = stRoundRect
    end
    object IDKODLISTA: TListBox
      Left = 104
      Top = 80
      Width = 449
      Height = 161
      Cursor = crHandPoint
      BorderStyle = bsNone
      Color = 7829367
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 0
      OnDblClick = IDKODLISTADblClick
      OnKeyDown = IDKODLISTAKeyDown
    end
    object rendbengomb: TBitBtn
      Left = 192
      Top = 272
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = rendbengombClick
    end
    object MEGSEMGOMB: TBitBtn
      Left = 328
      Top = 272
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = MEGSEMGOMBClick
    end
  end
  object PROSSOURCE: TDataSource
    DataSet = VALUTAQUERY
    Left = 136
    Top = 272
  end
  object VALUTADBASE: TIBDatabase
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
    Left = 72
    Top = 272
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 104
    Top = 272
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'SELECT * FROM PENZTAROSOK')
    Left = 40
    Top = 272
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    IndexFieldNames = 'PENZTAROSNEV'
    TableName = 'PENZTAROSOK'
    Left = 8
    Top = 272
  end
end
