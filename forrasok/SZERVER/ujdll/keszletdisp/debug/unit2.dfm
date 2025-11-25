object KESZLETDISPLAY: TKESZLETDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'KESZLETDISPLAY'
  ClientHeight = 613
  ClientWidth = 870
  Color = clSkyBlue
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
    Left = 40
    Top = 40
    Width = 649
    Height = 73
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape2: TShape
    Left = 8
    Top = 128
    Width = 697
    Height = 233
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 32
    Top = 376
    Width = 657
    Height = 57
    Brush.Color = clYellow
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape4: TShape
    Left = 0
    Top = 0
    Width = 870
    Height = 613
    Align = alClient
    Brush.Color = clSkyBlue
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 200
    Top = 8
    Width = 478
    Height = 32
    Caption = 'ID'#214'SZAKI K'#201'SZLETEK KIMUTAT'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -27
    Font.Name = 'Lemon'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label2: TLabel
    Left = 80
    Top = 48
    Width = 192
    Height = 27
    Caption = 'Vizsg'#225'lt egys'#233'g:'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -24
    Font.Name = 'Cooper Black'
    Font.Style = [fsItalic]
    ParentColor = False
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 64
    Top = 80
    Width = 101
    Height = 27
    Caption = 'Id'#337'szak:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clNavy
    Font.Height = -24
    Font.Name = 'Cooper Black'
    Font.Style = [fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape5: TShape
    Left = 64
    Top = 120
    Width = 745
    Height = 401
    Pen.Width = 3
  end
  object Shape6: TShape
    Left = 64
    Top = 528
    Width = 745
    Height = 73
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label6: TLabel
    Left = 88
    Top = 539
    Width = 94
    Height = 18
    Caption = 'Valuta '#233'rt'#233'k:'
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clPurple
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentColor = False
    ParentFont = False
    Transparent = True
  end
  object Label5: TLabel
    Left = 320
    Top = 539
    Width = 92
    Height = 18
    Caption = 'Forint '#233'rt'#233'k:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clPurple
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label4: TLabel
    Left = 560
    Top = 539
    Width = 102
    Height = 18
    Caption = #214'sszes '#233'rt'#233'k:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clPurple
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object IRODAPANEL: TPanel
    Left = 280
    Top = 48
    Width = 401
    Height = 25
    BevelOuter = bvNone
    Caption = 'IROD'#193'K '#214'SSZESITETT ADATAI'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object IDOSZAKPANEL: TPanel
    Left = 176
    Top = 80
    Width = 273
    Height = 25
    BevelOuter = bvNone
    Caption = '2020 szeptember 34 -21'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -21
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object KESZLETRACS: TDBGrid
    Left = 88
    Top = 136
    Width = 697
    Height = 369
    BorderStyle = bsNone
    DataSource = KESZLETSOURCE
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = []
    Columns = <
      item
        Alignment = taCenter
        Color = clAqua
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clBlue
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'VAL'
        Width = 33
        Visible = True
      end
      item
        Color = clYellow
        Expanded = False
        FieldName = 'KESZLET'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clRed
        Font.Height = -12
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'K'#201'SZLET'
        Width = 70
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET1'
        Title.Caption = '20.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET2'
        Title.Alignment = taCenter
        Title.Caption = '10.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET3'
        Title.Alignment = taCenter
        Title.Caption = '5.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET4'
        Title.Alignment = taCenter
        Title.Caption = '2.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET5'
        Title.Alignment = taCenter
        Title.Caption = '1.000'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET6'
        Title.Alignment = taCenter
        Title.Caption = '500'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET7'
        Title.Alignment = taCenter
        Title.Caption = '200'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET8'
        Title.Alignment = taCenter
        Title.Caption = '100'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET9'
        Title.Alignment = taCenter
        Title.Caption = '50'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET10'
        Title.Alignment = taCenter
        Title.Caption = '20'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET11'
        Title.Alignment = taCenter
        Title.Caption = '10'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET12'
        Title.Alignment = taCenter
        Title.Caption = '5'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET13'
        Title.Alignment = taCenter
        Title.Caption = '2'
        Width = 40
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CIMLET14'
        Title.Alignment = taCenter
        Title.Caption = '1'
        Width = 40
        Visible = True
      end>
  end
  object kilepogomb: TBitBtn
    Left = 624
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A MEN'#220'RE'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = kilepogombClick
    OnEnter = POSTAGOMBEnter
    OnExit = POSTAGOMBExit
    OnMouseMove = POSTAGOMBMouseMove
  end
  object VALUTAPANEL: TPanel
    Left = 187
    Top = 536
    Width = 126
    Height = 25
    BevelOuter = bvNone
    Caption = '123 245 000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object FORINTPANEL: TPanel
    Left = 412
    Top = 536
    Width = 133
    Height = 25
    BevelOuter = bvNone
    Caption = '250 000 000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object OSSZESPANEL: TPanel
    Left = 672
    Top = 536
    Width = 129
    Height = 25
    BevelOuter = bvNone
    Caption = '180 000 000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object MASADATGOMB: TBitBtn
    Left = 72
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
    OnClick = MASADATGOMBClick
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 256
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S EGYS'#201'G'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
    OnClick = MASEGYSEGGOMBClick
  end
  object MASDATUMGOMB: TBitBtn
    Left = 440
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ID'#336'SZAK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
    OnClick = MASDATUMGOMBClick
  end
  object ZALOGPLUSBOX: TCheckBox
    Left = 472
    Top = 88
    Width = 345
    Height = 17
    Caption = 'AZ EXPRESSZ '#201'KSZERH'#193'ZZAL EGY'#220'TT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
    Visible = False
    OnClick = ZALOGPLUSBOXClick
  end
  object KESZLETDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = keszlettranz
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 24
    Top = 56
  end
  object keszlettranz: TIBTransaction
    Active = True
    DefaultDatabase = KESZLETDBASE
    AutoStopAction = saNone
    Left = 24
    Top = 16
  end
  object KESZLETSOURCE: TDataSource
    DataSet = KESZLETQUERY
    Left = 824
    Top = 16
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 824
    Top = 248
  end
  object PARADBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = PARATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 824
    Top = 280
  end
  object PARATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 824
    Top = 320
  end
  object KESZLETQUERY: TIBQuery
    Database = KESZLETDBASE
    Transaction = keszlettranz
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      'select * from cimletgyujto')
    Left = 64
    Top = 16
    object KESZLETQUERYIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
      Origin = 'CIMLETGYUJTO.IRODASZAM'
    end
    object KESZLETQUERYERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
      Origin = 'CIMLETGYUJTO.ERTEKTAR'
    end
    object KESZLETQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'CIMLETGYUJTO.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object KESZLETQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'CIMLETGYUJTO.ELSZAMOLASIARFOLYAM'
    end
    object KESZLETQUERYKESZLET: TFloatField
      FieldName = 'KESZLET'
      Origin = 'CIMLETGYUJTO.KESZLET'
      DisplayFormat = '### ### ###'
    end
    object KESZLETQUERYFORINTERTEK: TFloatField
      FieldName = 'FORINTERTEK'
      Origin = 'CIMLETGYUJTO.FORINTERTEK'
    end
    object KESZLETQUERYCIMLET1: TIntegerField
      FieldName = 'CIMLET1'
      Origin = 'CIMLETGYUJTO.CIMLET1'
    end
    object KESZLETQUERYCIMLET2: TIntegerField
      FieldName = 'CIMLET2'
      Origin = 'CIMLETGYUJTO.CIMLET2'
    end
    object KESZLETQUERYCIMLET3: TIntegerField
      FieldName = 'CIMLET3'
      Origin = 'CIMLETGYUJTO.CIMLET3'
    end
    object KESZLETQUERYCIMLET4: TIntegerField
      FieldName = 'CIMLET4'
      Origin = 'CIMLETGYUJTO.CIMLET4'
    end
    object KESZLETQUERYCIMLET5: TIntegerField
      FieldName = 'CIMLET5'
      Origin = 'CIMLETGYUJTO.CIMLET5'
    end
    object KESZLETQUERYCIMLET6: TIntegerField
      FieldName = 'CIMLET6'
      Origin = 'CIMLETGYUJTO.CIMLET6'
    end
    object KESZLETQUERYCIMLET7: TIntegerField
      FieldName = 'CIMLET7'
      Origin = 'CIMLETGYUJTO.CIMLET7'
    end
    object KESZLETQUERYCIMLET8: TIntegerField
      FieldName = 'CIMLET8'
      Origin = 'CIMLETGYUJTO.CIMLET8'
    end
    object KESZLETQUERYCIMLET9: TIntegerField
      FieldName = 'CIMLET9'
      Origin = 'CIMLETGYUJTO.CIMLET9'
    end
    object KESZLETQUERYCIMLET10: TIntegerField
      FieldName = 'CIMLET10'
      Origin = 'CIMLETGYUJTO.CIMLET10'
    end
    object KESZLETQUERYCIMLET11: TIntegerField
      FieldName = 'CIMLET11'
      Origin = 'CIMLETGYUJTO.CIMLET11'
    end
    object KESZLETQUERYCIMLET12: TIntegerField
      FieldName = 'CIMLET12'
      Origin = 'CIMLETGYUJTO.CIMLET12'
    end
    object KESZLETQUERYCIMLET13: TIntegerField
      FieldName = 'CIMLET13'
      Origin = 'CIMLETGYUJTO.CIMLET13'
    end
    object KESZLETQUERYCIMLET14: TIntegerField
      FieldName = 'CIMLET14'
      Origin = 'CIMLETGYUJTO.CIMLET14'
    end
    object KESZLETQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'CIMLETGYUJTO.CEGBETU'
      FixedChar = True
      Size = 1
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPOTimer
    Left = 72
    Top = 64
  end
end
