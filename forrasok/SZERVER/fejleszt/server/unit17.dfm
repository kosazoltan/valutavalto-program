object MNBLISTADISPLAY: TMNBLISTADISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'MNB LIST'#193'K '
  ClientHeight = 496
  ClientWidth = 742
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
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 750
    Height = 497
    Color = 16311512
    TabOrder = 0
    object Label1: TLabel
      Left = 144
      Top = 470
      Width = 112
      Height = 16
      Caption = 'V'#201'TEL DARAB'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 368
      Top = 470
      Width = 123
      Height = 16
      Caption = 'ELAD'#193'S DARAB'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object MNBRACS: TDBGrid
      Left = 8
      Top = 104
      Width = 721
      Height = 353
      Color = 8454016
      DataSource = DISPLAYSOURCE
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ReadOnly = True
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnColEnter = MNBRACSColEnter
      OnDrawDataCell = MNBRACSDrawDataCell
      OnDblClick = MNBRACSDblClick
      OnKeyUp = MNBRACSKeyUp
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'VALUTANEM'
          Title.Alignment = taCenter
          Title.Caption = 'Val'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 33
          Visible = True
        end
        item
          Alignment = taCenter
          Color = clYellow
          Expanded = False
          FieldName = 'MEGJEGYZES'
          Title.Alignment = taCenter
          Title.Caption = 'St'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 26
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'NYITO'
          Title.Alignment = taCenter
          Title.Caption = 'Nyit'#243
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VETEL'
          Title.Alignment = taCenter
          Title.Caption = 'V'#233'tel'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELADAS'
          Title.Alignment = taCenter
          Title.Caption = 'Elad'#225's'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKIATVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'Bank +'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'BANKIATADAS'
          Title.Alignment = taCenter
          Title.Caption = 'Bank -'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTARIATVETEL'
          Title.Alignment = taCenter
          Title.Caption = 'P'#233'nzt'#225'r +'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'PENZTARIKIADAS'
          Title.Alignment = taCenter
          Title.Caption = 'P'#233'nzt'#225'r -'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 62
          Visible = True
        end
        item
          Color = clYellow
          Expanded = False
          FieldName = 'ZARO'
          Title.Alignment = taCenter
          Title.Caption = 'Z'#193'R'#211
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'SZAMITOTTZARO'
          Title.Alignment = taCenter
          Title.Caption = 'Sz'#225'mitott'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'TOBBLET'
          Title.Alignment = taCenter
          Title.Caption = 'T'#246'bblet'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'HIANY'
          Title.Alignment = taCenter
          Title.Caption = 'Hi'#225'ny'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VISSZAPLUSZ'
          Title.Alignment = taCenter
          Title.Caption = 'Vissza +'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'VISSZAMINUSZ'
          Title.Alignment = taCenter
          Title.Caption = 'Vissza -'
          Title.Color = clLime
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clBlue
          Title.Font.Height = -13
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = []
          Width = 66
          Visible = True
        end>
    end
    object FOCIMPANEL: TPanel
      Left = 8
      Top = 8
      Width = 721
      Height = 41
      Caption = 'BEST CHANGE '#214'SSZES'#205'TETT ADATAI'
      Color = 15780519
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object DISPLAYQUIT: TBitBtn
      Left = 632
      Top = 464
      Width = 99
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = DISPLAYQUITClick
    end
    object toligpanel: TPanel
      Left = 120
      Top = 56
      Width = 497
      Height = 41
      Caption = '2008 SZEPTEMBER 11 '#201'S 22 K'#214'Z'#214'TT'
      Color = 15780519
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object nyomtatogomb: TBitBtn
      Left = 8
      Top = 464
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'NYOMTAT'#193'S  (F8)'
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object DNEM1PANEL: TPanel
      Left = 8
      Top = 56
      Width = 105
      Height = 41
      Color = clAqua
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 5
    end
    object DNEM2PANEL: TPanel
      Left = 624
      Top = 56
      Width = 105
      Height = 41
      Color = clAqua
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -32
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 6
    end
    object Panel2: TPanel
      Left = 264
      Top = 464
      Width = 73
      Height = 25
      Caption = '12400'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 7
    end
    object Panel3: TPanel
      Left = 496
      Top = 464
      Width = 73
      Height = 25
      Caption = 'Panel3'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
  end
  object DISPLAYSOURCE: TDataSource
    DataSet = DISPLAYTABLA
    Left = 16
    Top = 160
  end
  object DISPLAYTABLA: TIBTable
    Database = DISPLAYDBASE
    Transaction = DISPLAYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'IRODASZAM'
        DataType = ftInteger
      end
      item
        Name = 'ERTEKTAR'
        DataType = ftInteger
      end
      item
        Name = 'VALUTANEM'
        DataType = ftString
        Size = 3
      end
      item
        Name = 'NYITO'
        DataType = ftFloat
      end
      item
        Name = 'VETEL'
        DataType = ftFloat
      end
      item
        Name = 'ELADAS'
        DataType = ftFloat
      end
      item
        Name = 'HIANY'
        DataType = ftFloat
      end
      item
        Name = 'TOBBLET'
        DataType = ftFloat
      end
      item
        Name = 'BANKIATVETEL'
        DataType = ftFloat
      end
      item
        Name = 'BANKIATADAS'
        DataType = ftFloat
      end
      item
        Name = 'PENZTARIKIADAS'
        DataType = ftFloat
      end
      item
        Name = 'PENZTARIATVETEL'
        DataType = ftFloat
      end
      item
        Name = 'ZARO'
        DataType = ftFloat
      end
      item
        Name = 'SZAMITOTTZARO'
        DataType = ftFloat
      end
      item
        Name = 'VETELDARAB'
        DataType = ftInteger
      end
      item
        Name = 'ELADASDARAB'
        DataType = ftInteger
      end
      item
        Name = 'IRODADNEM'
        DataType = ftString
        Size = 6
      end
      item
        Name = 'VISSZAPLUSZ'
        DataType = ftFloat
      end
      item
        Name = 'VISSZAMINUSZ'
        DataType = ftFloat
      end
      item
        Name = 'MEGJEGYZES'
        DataType = ftString
        Size = 2
      end>
    IndexDefs = <
      item
        Name = 'IDX_MNB'
        Fields = 'VALUTANEM'
      end>
    IndexFieldNames = 'VALUTANEM'
    StoreDefs = True
    TableName = 'MNB'
    Left = 16
    Top = 400
    object DISPLAYTABLAIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
    end
    object DISPLAYTABLAERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
    end
    object DISPLAYTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object DISPLAYTABLANYITO: TFloatField
      FieldName = 'NYITO'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAVETEL: TFloatField
      FieldName = 'VETEL'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAELADAS: TFloatField
      FieldName = 'ELADAS'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAHIANY: TFloatField
      FieldName = 'HIANY'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLATOBBLET: TFloatField
      FieldName = 'TOBBLET'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLABANKIATVETEL: TFloatField
      FieldName = 'BANKIATVETEL'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLABANKIATADAS: TFloatField
      FieldName = 'BANKIATADAS'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAPENZTARIKIADAS: TFloatField
      FieldName = 'PENZTARIKIADAS'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAPENZTARIATVETEL: TFloatField
      FieldName = 'PENZTARIATVETEL'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAZARO: TFloatField
      FieldName = 'ZARO'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLASZAMITOTTZARO: TFloatField
      FieldName = 'SZAMITOTTZARO'
      DisplayFormat = '###,###,###'
    end
    object DISPLAYTABLAVETELDARAB: TIntegerField
      FieldName = 'VETELDARAB'
    end
    object DISPLAYTABLAELADASDARAB: TIntegerField
      FieldName = 'ELADASDARAB'
    end
    object DISPLAYTABLAIRODADNEM: TIBStringField
      FieldName = 'IRODADNEM'
      FixedChar = True
      Size = 6
    end
    object DISPLAYTABLAMEGJEGYZES: TIBStringField
      FieldName = 'MEGJEGYZES'
      FixedChar = True
      Size = 2
    end
    object DISPLAYTABLAVISSZAPLUSZ: TFloatField
      FieldName = 'VISSZAPLUSZ'
    end
    object DISPLAYTABLAVISSZAMINUSZ: TFloatField
      FieldName = 'VISSZAMINUSZ'
    end
  end
  object DISPLAYDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = DISPLAYTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 400
  end
  object DISPLAYTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = DISPLAYDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 400
  end
  object DISPLAYQUERY: TIBQuery
    Database = DISPLAYDBASE
    Transaction = DISPLAYTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 120
    Top = 400
  end
end
