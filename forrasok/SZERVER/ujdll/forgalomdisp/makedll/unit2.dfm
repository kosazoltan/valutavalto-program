object FORGDISPLAY: TFORGDISPLAY
  Left = 186
  Top = 114
  BorderStyle = bsNone
  Caption = 'FORGDISPLAY'
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
    Left = 136
    Top = 24
    Width = 549
    Height = 36
    Caption = 'ID'#214'SZAKI FORGALOM KIMUTAT'#193'SA'
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -32
    Font.Name = 'Lemon'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object Label8: TLabel
    Left = 184
    Top = 64
    Width = 134
    Height = 24
    Caption = 'Vizsg'#225'lt iroda:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -21
    Font.Name = 'Lemon'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object Label9: TLabel
    Left = 152
    Top = 96
    Width = 159
    Height = 24
    Caption = 'Vizsg'#225'lt id'#337'szak:'
    Font.Charset = ANSI_CHARSET
    Font.Color = clTeal
    Font.Height = -21
    Font.Name = 'Lemon'
    Font.Style = [fsItalic]
    ParentFont = False
  end
  object Shape2: TShape
    Left = 48
    Top = 160
    Width = 755
    Height = 393
  end
  object IRODAPANEL: TPanel
    Left = 376
    Top = 63
    Width = 353
    Height = 31
    BevelOuter = bvNone
    Caption = 'AZ IROD'#193'K '#214'SSZESITETT ADATAI'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Lemon'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object Panel2: TPanel
    Left = 56
    Top = 168
    Width = 41
    Height = 73
    Color = clMoneyGreen
    TabOrder = 1
    object Label5: TLabel
      Left = 8
      Top = 8
      Width = 25
      Height = 19
      Caption = 'VA-'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 8
      Top = 28
      Width = 26
      Height = 19
      Caption = 'LU-'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 8
      Top = 48
      Width = 20
      Height = 19
      Caption = 'TA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel3: TPanel
    Left = 104
    Top = 168
    Width = 81
    Height = 73
    Color = clMoneyGreen
    TabOrder = 2
    object Label2: TLabel
      Left = 2
      Top = 8
      Width = 75
      Height = 16
      Caption = 'Elsz'#225'mol'#225'si'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 16
      Top = 24
      Width = 56
      Height = 16
      Caption = #225'rfolyam'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 16
      Top = 48
      Width = 45
      Height = 16
      Caption = '(100/Ft)'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel4: TPanel
    Left = 192
    Top = 208
    Width = 145
    Height = 33
    Caption = 'BANKJEGY'
    Color = clMoneyGreen
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
  end
  object Panel5: TPanel
    Left = 648
    Top = 208
    Width = 145
    Height = 33
    Caption = 'FORINT'
    Color = clMoneyGreen
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
  end
  object Panel6: TPanel
    Left = 496
    Top = 208
    Width = 145
    Height = 33
    Caption = 'BANKJEGY'
    Color = clMoneyGreen
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
  end
  object Panel7: TPanel
    Left = 344
    Top = 208
    Width = 145
    Height = 33
    Caption = 'FORINT'
    Color = clMoneyGreen
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
  end
  object Panel8: TPanel
    Left = 192
    Top = 168
    Width = 297
    Height = 33
    Caption = 'VALUTA V'#193'S'#193'RL'#193'S'
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object Panel9: TPanel
    Left = 496
    Top = 168
    Width = 297
    Height = 33
    Caption = 'VALUTA ELAD'#193'S'
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object FORGALOMRACS: TDBGrid
    Left = 56
    Top = 248
    Width = 737
    Height = 257
    Color = 11599871
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
        Width = 41
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELSZAMOLASIARFOLYAM'
        Title.Alignment = taCenter
        Title.Caption = '...'
        Width = 89
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETT'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 149
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'VETTERTEK'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 152
        Visible = True
      end
      item
        Alignment = taCenter
        Expanded = False
        FieldName = 'ELADOTT'
        Title.Alignment = taCenter
        Title.Caption = '.....'
        Width = 151
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
    Left = 368
    Top = 96
    Width = 305
    Height = 27
    BevelOuter = bvNone
    Caption = '2020 szeptember 12 - 25'
    Color = clSkyBlue
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -19
    Font.Name = 'Lemon'
    Font.Style = []
    ParentFont = False
    TabOrder = 10
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 240
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S EGYS'#201'G'
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -15
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 11
    OnClick = MasEgysegGombClick
  end
  object Panel11: TPanel
    Left = 56
    Top = 512
    Width = 193
    Height = 33
    Caption = #214'SSZESEN'
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 12
  end
  object KILEPOGOMB: TBitBtn
    Left = 608
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'SZERVER MEN'#220'RE'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 13
    OnClick = KILEPOGOMBClick
  end
  object SVETTFTPANEL: TPanel
    Left = 256
    Top = 512
    Width = 265
    Height = 33
    Color = clMoneyGreen
    Font.Charset = HEBREW_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 14
  end
  object SELADOTTFTPANEL: TPanel
    Left = 528
    Top = 512
    Width = 265
    Height = 33
    Color = clMoneyGreen
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 15
  end
  object MASADATGOMB: TBitBtn
    Left = 56
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 16
    OnClick = MASADATGOMBClick
  end
  object MASDATUMGOMB: TBitBtn
    Left = 424
    Top = 568
    Width = 177
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'SIK ID'#336'SZAK'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 17
    OnClick = MASDATUMGOMBClick
  end
  object ZALOGPLUSBOX: TCheckBox
    Left = 152
    Top = 136
    Width = 393
    Height = 17
    Caption = 'AZ EXPRESSZ '#201'KSZERH'#193'ZZAL EGY'#220'TT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 18
    Visible = False
    OnClick = ZALOGPLUSBOXClick
  end
  object RECEPTORDBASE: TIBDatabase
    Connected = True
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECEPTORTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 16
    Top = 48
  end
  object RECEPTORTRANZ: TIBTransaction
    Active = True
    DefaultDatabase = RECEPTORDBASE
    AutoStopAction = saNone
    Left = 48
    Top = 16
  end
  object FORGALOMSOURCE: TDataSource
    DataSet = RECEPTORQUERY
    Left = 48
    Top = 48
  end
  object RECEPTORQUERY: TIBQuery
    Database = RECEPTORDBASE
    Transaction = RECEPTORTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    SQL.Strings = (
      '')
    Left = 16
    Top = 88
    object RECEPTORQUERYIRODASZAM: TIntegerField
      FieldName = 'IRODASZAM'
      Origin = 'FORGALOMGYUJTO.IRODASZAM'
    end
    object RECEPTORQUERYERTEKTAR: TIntegerField
      FieldName = 'ERTEKTAR'
      Origin = 'FORGALOMGYUJTO.ERTEKTAR'
    end
    object RECEPTORQUERYVALUTANEM: TIBStringField
      FieldName = 'VALUTANEM'
      Origin = 'FORGALOMGYUJTO.VALUTANEM'
      FixedChar = True
      Size = 3
    end
    object RECEPTORQUERYELSZAMOLASIARFOLYAM: TFloatField
      FieldName = 'ELSZAMOLASIARFOLYAM'
      Origin = 'FORGALOMGYUJTO.ELSZAMOLASIARFOLYAM'
      DisplayFormat = '### ###'
    end
    object RECEPTORQUERYVETT: TFloatField
      FieldName = 'VETT'
      Origin = 'FORGALOMGYUJTO.VETT'
      DisplayFormat = '### ### ###'
    end
    object RECEPTORQUERYELADOTT: TFloatField
      FieldName = 'ELADOTT'
      Origin = 'FORGALOMGYUJTO.ELADOTT'
      DisplayFormat = '### ### ###'
    end
    object RECEPTORQUERYVETTERTEK: TFloatField
      FieldName = 'VETTERTEK'
      Origin = 'FORGALOMGYUJTO.VETTERTEK'
      DisplayFormat = '### ### ###'
    end
    object RECEPTORQUERYELADOTTERTEK: TFloatField
      FieldName = 'ELADOTTERTEK'
      Origin = 'FORGALOMGYUJTO.ELADOTTERTEK'
      DisplayFormat = '### ### ###'
    end
    object RECEPTORQUERYCEGBETU: TIBStringField
      FieldName = 'CEGBETU'
      Origin = 'FORGALOMGYUJTO.CEGBETU'
      FixedChar = True
      Size = 1
    end
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 88
    Top = 16
  end
  object PARAQUERY: TIBQuery
    Database = PARADBASE
    Transaction = PARATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 816
    Top = 16
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
    Left = 816
    Top = 56
  end
  object PARATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = PARADBASE
    AutoStopAction = saNone
    Left = 816
    Top = 96
  end
end
