object MNBDISPLAY: TMNBDISPLAY
  Left = 192
  Top = 114
  AlphaBlendValue = 180
  BorderStyle = bsNone
  Caption = 'MNBDISPLAY'
  ClientHeight = 684
  ClientWidth = 1079
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
  object Shape1: TShape
    Left = 0
    Top = 0
    Width = 1079
    Height = 684
    Align = alClient
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Button1: TButton
    Left = 40
    Top = 560
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object RACSPANEL: TPanel
    Left = 5
    Top = 5
    Width = 1068
    Height = 674
    BevelOuter = bvNone
    Color = clMoneyGreen
    TabOrder = 1
    object MNBRACS: TDBGrid
      Left = 8
      Top = 62
      Width = 1057
      Height = 579
      Color = clWhite
      DataSource = MNBSOURCE
      FixedColor = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
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
          FieldName = 'VALUTANEM'
          Title.Alignment = taCenter
          Title.Caption = 'DNEM'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 43
          Visible = True
        end
        item
          Alignment = taCenter
          Color = clYellow
          Expanded = False
          FieldName = 'MEGJEGYZES'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Title.Alignment = taCenter
          Title.Caption = 'ST'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 28
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'NYITO'
          Title.Alignment = taCenter
          Title.Caption = 'NYIT'#211
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 68
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VETEL'
          Title.Alignment = taCenter
          Title.Caption = 'V'#201'TEL'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 78
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELADAS'
          Title.Alignment = taCenter
          Title.Caption = 'ELAD'#193'S'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 84
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKIATVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'BANK +'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 70
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKIATADAS'
          Title.Alignment = taCenter
          Title.Caption = 'BANK -'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 69
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTARIATVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'PT'#193'R +'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 74
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTARIKIADAS'
          Title.Alignment = taCenter
          Title.Caption = 'PT'#193'R -'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 75
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TOBBLET'
          Title.Alignment = taCenter
          Title.Caption = 'T'#214'BB:'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 59
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'HIANY'
          Title.Alignment = taCenter
          Title.Caption = 'HI'#193'NY:'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 68
          Visible = True
        end
        item
          Color = clYellow
          Expanded = False
          FieldName = 'ZARO'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Title.Alignment = taCenter
          Title.Caption = 'Z'#193'R'#211
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 88
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SZAMITOTTZARO'
          Title.Alignment = taCenter
          Title.Caption = 'SZ'#193'MZ'#193'R'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 77
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VISSZAPLUSZ'
          Title.Alignment = taCenter
          Title.Caption = 'VISSZA+'
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 65
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VISSZAMINUSZ'
          Title.Alignment = taCenter
          Title.Caption = 'VISSZA-'
          Title.Font.Charset = ANSI_CHARSET
          Title.Font.Color = clWhite
          Title.Font.Height = -11
          Title.Font.Name = 'Calibri'
          Title.Font.Style = [fsBold]
          Width = 62
          Visible = True
        end>
    end
    object KFTPANEL: TPanel
      Left = 8
      Top = 8
      Width = 245
      Height = 25
      BevelOuter = bvNone
      Color = clGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clYellow
      Font.Height = -24
      Font.Name = 'Stencil'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
    object KORZETPANEL: TPanel
      Left = 8
      Top = 36
      Width = 245
      Height = 25
      BevelOuter = bvNone
      Color = clTeal
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object IRODANEVPANEL: TPanel
      Left = 256
      Top = 8
      Width = 801
      Height = 25
      BevelOuter = bvNone
      Color = clGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -24
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
    end
    object DATUMPANEL: TPanel
      Left = 256
      Top = 36
      Width = 801
      Height = 25
      BevelOuter = bvNone
      Color = clTeal
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
    end
    object KILEPESGOMB: TBitBtn
      Left = 600
      Top = 645
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'KIL'#201'P'#201'S'
      TabOrder = 5
      OnClick = KILEPESGOMBClick
    end
    object MASEGYSEGGOMB: TBitBtn
      Left = 332
      Top = 645
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#193'SIK EGYS'#201'G'
      TabOrder = 6
      OnClick = MASEGYSEGGOMBClick
    end
    object BitBtn2: TBitBtn
      Left = 466
      Top = 645
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#193'SIK ID'#211'SZAK'
      TabOrder = 7
      OnClick = BitBtn2Click
    end
  end
  object MNBQUERY: TIBQuery
    Database = MNBDBASE
    Transaction = MNBTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 32
    Top = 424
    object MNBQUERYIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
      Origin = 'MNB.IRODASZAM'
    end
    object MNBQUERYERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
      Origin = 'MNB.ERTEKTAR'
    end
    object MNBQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'MNB.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object MNBQUERYNYITO: TFloatField
      FieldName = 'NYITO'
      Origin = 'MNB.NYITO'
      DisplayFormat = '### ### ### ###'
    end
    object MNBQUERYVETEL: TFloatField
      FieldName = 'VETEL'
      Origin = 'MNB.VETEL'
      DisplayFormat = '### ### ### ###'
    end
    object MNBQUERYELADAS: TFloatField
      FieldName = 'ELADAS'
      Origin = 'MNB.ELADAS'
      DisplayFormat = '### ### ### ###'
    end
    object MNBQUERYHIANY: TFloatField
      FieldName = 'HIANY'
      Origin = 'MNB.HIANY'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYTOBBLET: TFloatField
      FieldName = 'TOBBLET'
      Origin = 'MNB.TOBBLET'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYBANKIATVETEL: TFloatField
      FieldName = 'BANKIATVETEL'
      Origin = 'MNB.BANKIATVETEL'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYBANKIATADAS: TFloatField
      FieldName = 'BANKIATADAS'
      Origin = 'MNB.BANKIATADAS'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYPENZTARIKIADAS: TFloatField
      FieldName = 'PENZTARIKIADAS'
      Origin = 'MNB.PENZTARIKIADAS'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYPENZTARIATVETEL: TFloatField
      FieldName = 'PENZTARIATVETEL'
      Origin = 'MNB.PENZTARIATVETEL'
      DisplayFormat = '### ### ###'
    end
    object MNBQUERYZARO: TFloatField
      FieldName = 'ZARO'
      Origin = 'MNB.ZARO'
      DisplayFormat = '### ### ### ###'
    end
    object MNBQUERYSZAMITOTTZARO: TFloatField
      FieldName = 'SZAMITOTTZARO'
      Origin = 'MNB.SZAMITOTTZARO'
      DisplayFormat = '### ### ### ###'
    end
    object MNBQUERYVETELDARAB: TIntegerField
      FieldName = 'VETELDARAB'
      Origin = 'MNB.VETELDARAB'
    end
    object MNBQUERYELADASDARAB: TIntegerField
      FieldName = 'ELADASDARAB'
      Origin = 'MNB.ELADASDARAB'
    end
    object MNBQUERYIRODADNEM: TIBStringField
      FieldName = 'IRODADNEM'
      Origin = 'MNB.IRODADNEM'
      FixedChar = True
      Size = 6
    end
    object MNBQUERYVISSZAPLUSZ: TFloatField
      FieldName = 'VISSZAPLUSZ'
      Origin = 'MNB.VISSZAPLUSZ'
    end
    object MNBQUERYVISSZAMINUSZ: TFloatField
      FieldName = 'VISSZAMINUSZ'
      Origin = 'MNB.VISSZAMINUSZ'
    end
    object MNBQUERYMEGJEGYZES: TIBStringField
      FieldName = 'MEGJEGYZES'
      Origin = 'MNB.MEGJEGYZES'
      FixedChar = True
      Size = 2
    end
    object MNBQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'MNB.CEGBETU'
      FixedChar = True
      Size = 1
    end
    object MNBQUERYBANKKARTYA: TIntegerField
      FieldName = 'BANKKARTYA'
      Origin = 'MNB.BANKKARTYA'
    end
  end
  object MNBDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = MNBTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 424
  end
  object MNBTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = MNBDBASE
    AutoStopAction = saNone
    Left = 96
    Top = 424
  end
  object MNBSOURCE: TDataSource
    DataSet = MNBQUERY
    Left = 136
    Top = 424
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 176
    Top = 424
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 464
  end
  object RECEPTORDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 64
    Top = 464
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 464
  end
  object ARTQUERY: TIBQuery
    Database = ARTDBASE
    Transaction = ARTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 32
    Top = 504
  end
  object ARTDBASE: TIBDatabase
    DatabaseName = 'C:\CARTCASH\DATABASE\ARTCASH.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = ARTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 504
  end
  object ARTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARTDBASE
    AutoStopAction = saNone
    Left = 112
    Top = 504
  end
end
