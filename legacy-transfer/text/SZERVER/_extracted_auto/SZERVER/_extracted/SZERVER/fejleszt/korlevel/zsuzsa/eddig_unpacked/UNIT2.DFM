object superform: Tsuperform
  Left = 192
  Top = 114
  Width = 855
  Height = 655
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 847
    Height = 621
    Align = alClient
    Brush.Color = 4539717
    Pen.Color = clWhite
    Pen.Width = 6
  end
  object Label1: TLabel
    Left = 152
    Top = 32
    Width = 581
    Height = 37
    Caption = 'K'#214'RLEVELEK SUPERVISORI FELADATAI'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object KISMENUPANEL: TPanel
    Left = 200
    Top = 104
    Width = 425
    Height = 201
    BevelWidth = 5
    Color = clWhite
    TabOrder = 0
    object KLDELETE: TBitBtn
      Left = 32
      Top = 24
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY K'#214'RLEV'#201'L T'#214'RL'#201'SE'
      TabOrder = 0
      OnClick = KLDELETEClick
    end
    object KLINSERT: TBitBtn
      Left = 32
      Top = 56
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY K'#214'RLEV'#201'L BESZUR'#193'SA'
      TabOrder = 1
      OnClick = KLINSERTClick
    end
    object BANSIGN: TBitBtn
      Left = 32
      Top = 88
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'EGY SZIGN'#211' LETILT'#193'SA'
      TabOrder = 2
      OnClick = BANSIGNClick
    end
    object KLREADLIST: TBitBtn
      Left = 32
      Top = 120
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'RLEV'#201'L OLVAS'#193'SOK ID'#336'PONTJAI'
      ModalResult = 1
      TabOrder = 3
      OnClick = KLREADLISTClick
    end
    object KILEPOGOMB: TBitBtn
      Left = 32
      Top = 152
      Width = 369
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S A SUPERVISORI MEN'#220'B'#336'L'
      TabOrder = 4
      OnClick = KILEPOGOMBClick
    end
  end
  object DELPANEL: TPanel
    Left = -1400
    Top = -100
    Width = 657
    Height = 577
    TabOrder = 1
    object Label2: TLabel
      Left = 128
      Top = 8
      Width = 391
      Height = 36
      Caption = 'EGY K'#214'RLEV'#201'L T'#214'RL'#201'SE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object DELRACS: TDBGrid
      Left = 8
      Top = 56
      Width = 641
      Height = 481
      DataSource = DELSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IKTATOSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'IKTAT'#211'SZ'#193'M'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TARTALOM'
          Title.Alignment = taCenter
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object REMOVEGOMB: TBitBtn
      Left = 32
      Top = 544
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'EZT A K'#214'RLEVELET T'#214'R'#214'LNI'
      TabOrder = 1
      OnClick = REMOVEGOMBClick
    end
    object DELRETURNGOMB: TBitBtn
      Left = 416
      Top = 544
      Width = 225
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 2
      OnClick = DELRETURNGOMBClick
    end
  end
  object INSPANEL: TPanel
    Left = -1400
    Top = -200
    Width = 657
    Height = 577
    TabOrder = 2
    object Label3: TLabel
      Left = 120
      Top = 8
      Width = 431
      Height = 36
      Caption = 'EGY K'#214'RLEV'#201'L BESZ'#218'R'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object INSRACS: TDBGrid
      Left = 8
      Top = 56
      Width = 641
      Height = 417
      DataSource = INSSOURCE
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'DATUM'
          Title.Alignment = taCenter
          Title.Caption = 'D'#193'TUM'
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IKTATOSZAM'
          Title.Alignment = taCenter
          Title.Caption = 'IKTAT'#211
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TARTALOM'
          Title.Alignment = taCenter
          Title.Color = clYellow
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end>
    end
    object VALASZTOGOMB: TBitBtn
      Left = 8
      Top = 512
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'BESZ'#218'RAND'#211' K'#214'RLEV'#201'L KIV'#193'LASZT'#193'SA'
      TabOrder = 1
      OnClick = VALASZTOGOMBClick
    end
    object INSERTGOMB: TBitBtn
      Left = 336
      Top = 512
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'BESZ'#218'R'#193'S A V'#193'LASZTOTT K'#214'RLEV'#201'L UT'#193'N'
      TabOrder = 2
      OnClick = INSERTGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 336
      Top = 544
      Width = 313
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
    object VALASZTOTTPANEL: TPanel
      Left = 8
      Top = 480
      Width = 633
      Height = 25
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
    end
  end
  object FOLYAMATPANEL: TPanel
    Left = 192
    Top = 328
    Width = 433
    Height = 57
    BevelOuter = bvNone
    Caption = 'V'#201'GREHAJT'#193'S FOLYAMATBAN ....'
    Color = clRed
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object BANPANEL: TPanel
    Left = 224
    Top = 400
    Width = 385
    Height = 153
    TabOrder = 4
    object Label4: TLabel
      Left = 72
      Top = 24
      Width = 244
      Height = 24
      Caption = 'EGY SZIGN'#211' LETILT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 56
      Top = 72
      Width = 117
      Height = 21
      Caption = 'Letiltott szign'#243':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object szignoedit: TEdit
      Left = 184
      Top = 68
      Width = 121
      Height = 32
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 5
      ParentFont = False
      TabOrder = 0
      OnEnter = szignoeditEnter
      OnExit = szignoeditExit
      OnKeyDown = szignoeditKeyDown
    end
    object tiltogomb: TBitBtn
      Left = 48
      Top = 112
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'LETILTVA'
      TabOrder = 1
      OnClick = tiltogombClick
    end
    object MEGSEMTILTGOMB: TBitBtn
      Left = 200
      Top = 112
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      TabOrder = 2
    end
  end
  object KORLQUERY: TIBQuery
    Database = KORLDBASE
    Transaction = KORLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 24
    Top = 16
  end
  object KORLDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = KORLTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 16
  end
  object KORLTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = KORLDBASE
    AutoStopAction = saNone
    Left = 88
    Top = 16
  end
  object DELSOURCE: TDataSource
    DataSet = KORLQUERY
    Left = 128
    Top = 16
  end
  object KORLTABLA: TIBTable
    Database = KORLDBASE
    Transaction = KORLTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'DATUM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'IKTATOSZAM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 10
      end
      item
        Name = 'SORREND'
        DataType = ftSmallint
      end
      item
        Name = 'SORSZAM'
        DataType = ftSmallint
      end
      item
        Name = 'FILENEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 15
      end
      item
        Name = 'TARTALOM'
        Attributes = [faFixed]
        DataType = ftString
        Size = 80
      end
      item
        Name = 'STORNO'
        DataType = ftSmallint
      end
      item
        Name = 'SORTEMP'
        DataType = ftSmallint
      end>
    IndexDefs = <
      item
        Name = 'ALTXKORL2015'
        Fields = 'SORREND'
      end>
    StoreDefs = True
    TableName = 'KORL2015'
    Left = 24
    Top = 48
  end
  object INSSOURCE: TDataSource
    DataSet = KORLQUERY
    Left = 128
    Top = 48
  end
  object OpenDialog1: TOpenDialog
    Left = 56
    Top = 48
  end
end
