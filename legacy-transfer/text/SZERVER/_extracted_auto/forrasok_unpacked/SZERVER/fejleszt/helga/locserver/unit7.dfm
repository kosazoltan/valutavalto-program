object HIBAKDISPLAY: THIBAKDISPLAY
  Left = 198
  Top = 118
  Width = 759
  Height = 565
  Caption = 'HIBAKDISPLAY'
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
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clSkyBlue
    TabOrder = 0
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 750
      Height = 530
      Brush.Color = 170
      Pen.Color = clWhite
      Pen.Width = 8
    end
    object Label1: TLabel
      Left = 64
      Top = 40
      Width = 622
      Height = 36
      Caption = 'A  TEGNAP BE'#201'RKEZETT HIB'#193'S ADATOK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWhite
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Shape1: TShape
      Left = 32
      Top = 96
      Width = 689
      Height = 369
      Brush.Color = 8421631
      Pen.Width = 3
      Shape = stRoundRect
    end
    object VISSZAGOMB: TBitBtn
      Left = 616
      Top = 480
      Width = 99
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Default = True
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = VISSZAGOMBClick
    end
    object HIBAKRACS: TDBGrid
      Left = 56
      Top = 112
      Width = 641
      Height = 345
      BorderStyle = bsNone
      Color = 8421631
      DataSource = HIBAKSource
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -13
      Font.Name = 'Times New Roman'
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
      Columns = <
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'IRODA'
          Title.Alignment = taCenter
          Title.Caption = 'IRODASZ'#193'M'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 107
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'IRODANEV'
          Title.Alignment = taCenter
          Title.Caption = 'AZ IRODA MEGNEVEZ'#201'SE'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 331
          Visible = True
        end
        item
          Alignment = taCenter
          Expanded = False
          FieldName = 'VALUTANEM'
          Title.Alignment = taCenter
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 110
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'ELTERES'
          Title.Alignment = taCenter
          Title.Caption = 'ELT'#201'R'#201'S'
          Title.Color = clSkyBlue
          Title.Font.Charset = EASTEUROPE_CHARSET
          Title.Font.Color = clNavy
          Title.Font.Height = -16
          Title.Font.Name = 'Times New Roman'
          Title.Font.Style = [fsBold, fsItalic]
          Width = 94
          Visible = True
        end>
    end
  end
  object HIBAKTABLA: TIBTable
    Database = HIBAKDBASE
    Transaction = HIBAKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'HIBAK'
    Left = 40
    Top = 392
    object HIBAKTABLAIRODA: TIntegerField
      FieldName = 'IRODA'
    end
    object HIBAKTABLAIRODANEV: TIBStringField
      FieldName = 'IRODANEV'
      Size = 35
    end
    object HIBAKTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object HIBAKTABLAELTERES: TFloatField
      FieldName = 'ELTERES'
      DisplayFormat = '###,###,###'
    end
  end
  object HIBAKDBASE: TIBDatabase
    DatabaseName = 'localhost:C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = HIBAKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 72
    Top = 392
  end
  object HIBAKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = HIBAKDBASE
    AutoStopAction = saNone
    Left = 104
    Top = 392
  end
  object HIBAKSource: TDataSource
    DataSet = HIBAKTABLA
    Left = 144
    Top = 392
  end
end
