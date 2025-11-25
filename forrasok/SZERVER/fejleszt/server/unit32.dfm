object JUTALEKSZAZALEK: TJUTALEKSZAZALEK
  Left = 192
  Top = 114
  BorderIcons = []
  BorderStyle = bsNone
  Caption = 'JUTALEKSZAZALEK'
  ClientHeight = 530
  ClientWidth = 750
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
    Height = 530
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 750
      Height = 530
      Brush.Color = 8421631
      Pen.Color = clWhite
      Pen.Width = 8
    end
    object Shape1: TShape
      Left = 96
      Top = 80
      Width = 569
      Height = 329
      Pen.Width = 2
      Shape = stRoundRect
    end
    object Label1: TLabel
      Left = 32
      Top = 40
      Width = 682
      Height = 31
      Caption = 'P'#201'NZT'#193'RAK JUTAL'#201'K SZ'#193'ZAL'#201'K'#193'NAK BE'#193'LLIT'#193'SA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -27
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape3: TShape
      Left = 584
      Top = 360
      Width = 65
      Height = 17
    end
    object jutalekracs: TDBGrid
      Left = 112
      Top = 96
      Width = 537
      Height = 297
      BorderStyle = bsNone
      DataSource = JUTALEKSOURCE
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      Options = [dgEditing, dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgConfirmDelete, dgCancelOnExit]
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
      OnEnter = jutalekracsEnter
      OnExit = jutalekracsExit
      OnKeyDown = jutalekracsKeyDown
      OnMouseMove = jutalekracsMouseMove
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'PENZTAR'
          ReadOnly = True
          Title.Alignment = taCenter
          Title.Caption = 'P'#201'NZT'#193'R'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 105
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IRODANEV'
          ReadOnly = True
          Title.Alignment = taCenter
          Title.Caption = 'IRODA MEGNEVEZ'#201'S'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 265
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'SZAZALEK'
          Title.Alignment = taCenter
          Title.Caption = 'JUTAL'#201'K %-KA'
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 127
          Visible = True
        end>
    end
    object BitBtn1: TBitBtn
      Left = 120
      Top = 432
      Width = 169
      Height = 25
      Cursor = crHandPoint
      Caption = 'BE'#193'LLIT'#193'S RENDBEN'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnEnter = BitBtn1Enter
      OnExit = BitBtn1Exit
      OnMouseMove = BitBtn1MouseMove
    end
    object BitBtn2: TBitBtn
      Left = 512
      Top = 432
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      OnClick = BitBtn2Click
      OnEnter = BitBtn1Enter
      OnExit = BitBtn1Exit
      OnMouseMove = BitBtn1MouseMove
    end
  end
  object JUTALEKTABLA: TIBTable
    Database = JUTALEKDBASE
    Transaction = JUTALEKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    FieldDefs = <
      item
        Name = 'PENZTAR'
        DataType = ftSmallint
      end
      item
        Name = 'SZAZALEK'
        DataType = ftFloat
      end
      item
        Name = 'IRODANEV'
        Attributes = [faFixed]
        DataType = ftString
        Size = 33
      end>
    IndexDefs = <
      item
        Name = 'IDX_JUTALEKSZAZALEK'
        Fields = 'PENZTAR'
      end>
    IndexFieldNames = 'PENZTAR'
    StoreDefs = True
    TableName = 'JUTALEKSZAZALEK'
    Left = 64
    Top = 256
    object JUTALEKTABLAPENZTAR: TIntegerField
      FieldName = 'PENZTAR'
    end
    object JUTALEKTABLASZAZALEK: TFloatField
      FieldName = 'SZAZALEK'
      DisplayFormat = '0.#####'
      EditFormat = '0.#####'
    end
    object JUTALEKTABLAIRODANEV: TIBStringField
      FieldName = 'IRODANEV'
      Size = 33
    end
  end
  object JUTALEKDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = JUTALEKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 96
    Top = 256
  end
  object JUTALEKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = JUTALEKDBASE
    AutoStopAction = saNone
    Left = 128
    Top = 256
  end
  object JUTALEKSOURCE: TDataSource
    DataSet = JUTALEKTABLA
    Left = 176
    Top = 256
  end
end
