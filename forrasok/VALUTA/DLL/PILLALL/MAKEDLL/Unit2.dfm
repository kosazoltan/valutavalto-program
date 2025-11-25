object PILLANATNYIFORM: TPILLANATNYIFORM
  Left = 205
  Top = 131
  AlphaBlendValue = 180
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'PILLANATNYIFORM'
  ClientHeight = 727
  ClientWidth = 1016
  Color = clTeal
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Shape2: TShape
    Left = 0
    Top = 0
    Width = 1016
    Height = 727
    Align = alClient
    Brush.Color = 6710886
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 128
    Top = 32
    Width = 758
    Height = 41
    Caption = 'A PILLANATNYI P'#201'NZT'#193'R'#193'LL'#193'S KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -35
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 56
    Top = 96
    Width = 897
    Height = 569
  end
  object Label2: TLabel
    Left = 96
    Top = 696
    Width = 278
    Height = 24
    Caption = 'BANKK'#193'RTY'#193'VAL FIZETVE:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label3: TLabel
    Left = 512
    Top = 696
    Width = 235
    Height = 25
    Caption = ' (bankk'#225'rty'#225's kez-i k'#246'lts'#233'g:'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -21
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label4: TLabel
    Left = 944
    Top = 696
    Width = 10
    Height = 29
    Caption = ')'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -23
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object KESZLETRACS: TDBGrid
    Left = 56
    Top = 104
    Width = 897
    Height = 569
    BorderStyle = bsNone
    Color = clWhite
    DataSource = PILLANATNYISOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clNavy
    Font.Height = -16
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
    Columns = <
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEM'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clTeal
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'VNEM'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 81
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VALUTANEV'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clGreen
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'VALUTA NEVE'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -19
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 198
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NYITO'
        Font.Charset = ANSI_CHARSET
        Font.Color = clTeal
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        Title.Alignment = taCenter
        Title.Caption = 'NYIT'#211
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 112
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'BEVETEL'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'BEV'#201'TEL'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 111
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KIADAS'
        Font.Charset = ANSI_CHARSET
        Font.Color = clMaroon
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = []
        Title.Alignment = taCenter
        Title.Caption = 'KIAD'#193'S'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 110
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'KEZELESIDIJ'
        Font.Charset = ANSI_CHARSET
        Font.Color = clFuchsia
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'KEZ-I D'#205'J'
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'ZARO'
        Font.Charset = ANSI_CHARSET
        Font.Color = clRed
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Title.Alignment = taCenter
        Title.Caption = 'Z'#193'R'#211
        Title.Color = clWhite
        Title.Font.Charset = EASTEUROPE_CHARSET
        Title.Font.Color = clBlack
        Title.Font.Height = -21
        Title.Font.Name = 'Times New Roman'
        Title.Font.Style = [fsBold, fsItalic]
        Width = 154
        Visible = True
      end>
  end
  object NYOMTATOGOMB: TPanel
    Left = 104
    Top = 656
    Width = 281
    Height = 25
    Cursor = crHandPoint
    Caption = 'PILLANATNYI '#193'LL'#193'S KINYOMTAT'#193'SA'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    OnClick = NYOMTATOGOMBClick
  end
  object kezdikprintgomb: TPanel
    Left = 400
    Top = 656
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'KEZEL'#201'SI D'#205'J NYOMTAT'#193'SA'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    OnClick = KEZDIJPRINTGOMBClick
  end
  object escapegomb: TPanel
    Left = 664
    Top = 656
    Width = 249
    Height = 25
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#336'MEN'#220'RE (Escape)'
    Color = 4539717
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -15
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
    OnClick = ESCAPEGOMBClick
  end
  object Panel1: TPanel
    Left = 918
    Top = 96
    Width = 27
    Height = 41
    BevelOuter = bvNone
    Color = 4539717
    TabOrder = 4
  end
  object BANKKARTYAPANEL: TPanel
    Left = 384
    Top = 698
    Width = 97
    Height = 22
    Caption = '555 000 Ft'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 5
  end
  object BKKTSGPANEL: TPanel
    Left = 848
    Top = 700
    Width = 89
    Height = 20
    Caption = '55000 Ft'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object BANKKARTYATAKARO: TPanel
    Left = 88
    Top = 680
    Width = 873
    Height = 41
    BevelOuter = bvNone
    Color = 6710886
    TabOrder = 6
  end
  object PILLANATNYISOURCE: TDataSource
    DataSet = ARFOLYAMQUERY
    Left = 56
    Top = 208
  end
  object ARFOLYAMDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 56
    Top = 256
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = ARFOLYAMDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 96
    Top = 256
  end
  object ARFOLYAMQUERY: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 136
    Top = 256
    object ARFOLYAMQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'ARFOLYAM.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object ARFOLYAMQUERYVALUTANEV: TIBStringField
      FieldName = 'VALUTANEV'
      Origin = 'ARFOLYAM.VALUTANEV'
      FixedChar = True
    end
    object ARFOLYAMQUERYVETELIARFOLYAM: TFloatField
      FieldName = 'VETELIARFOLYAM'
      Origin = 'ARFOLYAM.VETELIARFOLYAM'
    end
    object ARFOLYAMQUERYELADASIARFOLYAM: TFloatField
      FieldName = 'ELADASIARFOLYAM'
      Origin = 'ARFOLYAM.ELADASIARFOLYAM'
    end
    object ARFOLYAMQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'ARFOLYAM.ELSZAMOLASIARFOLYAM'
    end
    object ARFOLYAMQUERYMODOSITOSZAZALEK: TFloatField
      FieldName = 'MODOSITOSZAZALEK'
      Origin = 'ARFOLYAM.MODOSITOSZAZALEK'
    end
    object ARFOLYAMQUERYNYITO: TIntegerField
      FieldName = 'NYITO'
      Origin = 'ARFOLYAM.NYITO'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYBEVETEL: TIntegerField
      FieldName = 'BEVETEL'
      Origin = 'ARFOLYAM.BEVETEL'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYKIADAS: TIntegerField
      FieldName = 'KIADAS'
      Origin = 'ARFOLYAM.KIADAS'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYZARO: TIntegerField
      FieldName = 'ZARO'
      Origin = 'ARFOLYAM.ZARO'
      DisplayFormat = '### ### ###'
    end
    object ARFOLYAMQUERYK1VETEL: TFloatField
      FieldName = 'K1VETEL'
      Origin = 'ARFOLYAM.K1VETEL'
    end
    object ARFOLYAMQUERYK2VETEL: TFloatField
      FieldName = 'K2VETEL'
      Origin = 'ARFOLYAM.K2VETEL'
    end
    object ARFOLYAMQUERYK1ELADAS: TFloatField
      FieldName = 'K1ELADAS'
      Origin = 'ARFOLYAM.K1ELADAS'
    end
    object ARFOLYAMQUERYK2ELADAS: TFloatField
      FieldName = 'K2ELADAS'
      Origin = 'ARFOLYAM.K2ELADAS'
    end
    object ARFOLYAMQUERYSHKVETARFOLYAM: TFloatField
      FieldName = 'SHKVETARFOLYAM'
      Origin = 'ARFOLYAM.SHKVETARFOLYAM'
    end
    object ARFOLYAMQUERYSHKELADARFOLYAM: TFloatField
      FieldName = 'SHKELADARFOLYAM'
      Origin = 'ARFOLYAM.SHKELADARFOLYAM'
    end
    object ARFOLYAMQUERYKEZELESIDIJ: TIntegerField
      FieldName = 'KEZELESIDIJ'
      Origin = 'ARFOLYAM.KEZELESIDIJ'
      DisplayFormat = '### ### ###'
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 16
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
    Left = 48
    Top = 16
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
end
