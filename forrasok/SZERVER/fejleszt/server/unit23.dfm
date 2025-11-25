object FORGALOMDISPLAY: TFORGALOMDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'FORGALOMDISPLAY'
  ClientHeight = 446
  ClientWidth = 704
  Color = clRed
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 40
    Top = 0
    Width = 622
    Height = 42
    Caption = 'ID'#214'SZAKI FORGALOM KIMUTAT'#193'SA'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clYellow
    Font.Height = -37
    Font.Name = 'Times New Roman'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object IRODAPANEL: TPanel
    Left = 8
    Top = 40
    Width = 673
    Height = 41
    Caption = 'VIZSG'#193'LT IRODA:  AZ IROD'#193'K '#214'SSZESITETT ADATAI'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 8
    Top = 128
    Width = 41
    Height = 73
    Color = clInactiveBorder
    TabOrder = 1
    object Label5: TLabel
      Left = 8
      Top = 16
      Width = 22
      Height = 16
      Caption = 'VA-'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 8
      Top = 32
      Width = 21
      Height = 16
      Caption = 'LU-'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label7: TLabel
      Left = 8
      Top = 48
      Width = 18
      Height = 16
      Caption = 'TA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
  end
  object Panel3: TPanel
    Left = 56
    Top = 128
    Width = 81
    Height = 73
    Color = clInactiveBorder
    TabOrder = 2
    object Label2: TLabel
      Left = 2
      Top = 8
      Width = 73
      Height = 16
      Caption = 'Elsz'#225'mol'#225'si'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label3: TLabel
      Left = 16
      Top = 24
      Width = 52
      Height = 16
      Caption = #225'rfolyam'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object Label4: TLabel
      Left = 16
      Top = 48
      Width = 46
      Height = 16
      Caption = '(100/Ft)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
  end
  object Panel4: TPanel
    Left = 144
    Top = 168
    Width = 129
    Height = 33
    Caption = 'BANKJEGY'
    Color = clInactiveBorder
    TabOrder = 3
  end
  object Panel5: TPanel
    Left = 552
    Top = 168
    Width = 129
    Height = 33
    Caption = 'FORINT'
    Color = clInactiveBorder
    TabOrder = 4
  end
  object Panel6: TPanel
    Left = 416
    Top = 168
    Width = 129
    Height = 33
    Caption = 'BANKJEGY'
    Color = clInactiveBorder
    TabOrder = 5
  end
  object Panel7: TPanel
    Left = 280
    Top = 168
    Width = 129
    Height = 33
    Caption = 'FORINT'
    Color = clInactiveBorder
    TabOrder = 6
  end
  object Panel8: TPanel
    Left = 144
    Top = 128
    Width = 265
    Height = 33
    Caption = 'VALUTA V'#193'S'#193'RL'#193'S'
    Color = clInactiveBorder
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object Panel9: TPanel
    Left = 416
    Top = 128
    Width = 265
    Height = 33
    Caption = 'VALUTA ELAD'#193'S'
    Color = clInactiveBorder
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object FORGALOMRACS: TDBGrid
    Left = 8
    Top = 208
    Width = 689
    Height = 161
    DataSource = FORGALOMSOURCE
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [dgTitles, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 9
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
        Title.Caption = '...'
        Width = 42
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELSZAMOLASIARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = '...'
        Width = 85
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETT'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 137
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETTERTEK'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 135
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADOTT'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 136
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADOTTERTEK'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Title.Font.Charset = DEFAULT_CHARSET
        Title.Font.Color = clWindowText
        Title.Font.Height = -3
        Title.Font.Name = 'MS Sans Serif'
        Title.Font.Style = []
        Width = 122
        Visible = True
      end>
  end
  object IDOSZAKPANEL: TPanel
    Left = 8
    Top = 88
    Width = 673
    Height = 33
    Caption = 'VIZSG'#193'LT ID'#214'SZAK: 2009 SZEPTEMBER 23 -30'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
  end
  object NYOMTATASGOMB: TBitBtn
    Left = 192
    Top = 416
    Width = 177
    Height = 25
    Cursor = crNo
    Caption = 'NYOMTAT'#193'S'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clSilver
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 11
  end
  object Panel11: TPanel
    Left = 8
    Top = 376
    Width = 129
    Height = 33
    Caption = #214'SSZESEN'
    Color = clInactiveBorder
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 12
  end
  object BitBtn2: TBitBtn
    Left = 376
    Top = 416
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'VISSZA A MEN'#220'RE'
    TabOrder = 13
    OnClick = BitBtn2Click
  end
  object SVETTFTPANEL: TPanel
    Left = 144
    Top = 376
    Width = 265
    Height = 33
    Caption = 'SVETTFTPANEL'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 14
  end
  object SELADOTTFTPANEL: TPanel
    Left = 416
    Top = 376
    Width = 265
    Height = 33
    Caption = 'SELADOTTFTPANEL'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 15
  end
  object FORGALOMTABLA: TIBTable
    Database = FORGALOMDBASE
    Transaction = FORGALOMTRANZ
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
        Attributes = [faFixed]
        DataType = ftString
        Size = 3
      end
      item
        Name = 'ELSZAMOLASIARFOLYAM'
        DataType = ftFloat
      end
      item
        Name = 'VETT'
        DataType = ftFloat
      end
      item
        Name = 'ELADOTT'
        DataType = ftFloat
      end
      item
        Name = 'VETTERTEK'
        DataType = ftFloat
      end
      item
        Name = 'ELADOTTERTEK'
        DataType = ftFloat
      end>
    IndexDefs = <
      item
        Name = 'IDX_FORGALOMGYUJTO'
        Fields = 'IRODASZAM;VALUTANEM'
      end
      item
        Name = 'ALTXFORGALOMGYUJTO'
        Fields = 'IRODASZAM'
      end>
    IndexFieldNames = 'IRODASZAM;VALUTANEM'
    StoreDefs = True
    TableName = 'FORGALOMGYUJTO'
    Left = 16
    Top = 272
    object FORGALOMTABLAERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
    end
    object FORGALOMTABLAIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
    end
    object FORGALOMTABLAVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Size = 3
    end
    object FORGALOMTABLAVETT: TFloatField
      FieldName = 'VETT'
      DisplayFormat = '###,###,###'
    end
    object FORGALOMTABLAVETTERTEK: TFloatField
      FieldName = 'VETTERTEK'
      DisplayFormat = '###,###,###'
    end
    object FORGALOMTABLAELADOTT: TFloatField
      FieldName = 'ELADOTT'
      DisplayFormat = '###,###,###'
    end
    object FORGALOMTABLAELADOTTERTEK: TFloatField
      FieldName = 'ELADOTTERTEK'
      DisplayFormat = '###,###,###'
    end
    object FORGALOMTABLAELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      DisplayFormat = '###,###,###.00'
    end
  end
  object FORGALOMDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = FORGALOMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 272
  end
  object FORGALOMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = FORGALOMDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 272
  end
  object FORGALOMSOURCE: TDataSource
    DataSet = FORGALOMTABLA
    Left = 16
    Top = 312
  end
end
