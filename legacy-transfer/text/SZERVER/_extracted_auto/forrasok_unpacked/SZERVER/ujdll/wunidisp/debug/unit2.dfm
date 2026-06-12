object WUNIDISPLAY: TWUNIDISPLAY
  Left = 192
  Top = 114
  BorderStyle = bsNone
  Caption = 'WUNIDISPLAY'
  ClientHeight = 613
  ClientWidth = 870
  Color = clTeal
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
    Brush.Color = clTeal
    Pen.Color = clYellow
    Pen.Width = 5
  end
  object Label1: TLabel
    Left = 56
    Top = 16
    Width = 778
    Height = 34
    Caption = 'WESTERN UNION '#201'S '#193'FAVISSZAT'#201'RIT'#201'S ADATAI '
    Font.Charset = ANSI_CHARSET
    Font.Color = clWhite
    Font.Height = -29
    Font.Name = 'Cooper Black'
    Font.Style = []
    ParentFont = False
    Transparent = True
  end
  object EGYSEGPANEL: TPanel
    Left = 16
    Top = 56
    Width = 464
    Height = 46
    BevelOuter = bvNone
    Caption = 'P'#201'NZT'#193'RAK '#214'SSZESITETT ADATAI'
    Color = 10551200
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object IDOSZAKPANEL: TPanel
    Left = 482
    Top = 56
    Width = 369
    Height = 46
    BevelOuter = bvNone
    Caption = '2009 SZEPTEMBER 1 - 30'
    Color = 10551200
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clTeal
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
  end
  object Panel3: TPanel
    Left = 16
    Top = 104
    Width = 332
    Height = 46
    BevelOuter = bvNone
    Caption = 'TRANZAKCI'#211' TIPUSA'
    Color = 14745568
    Font.Charset = ANSI_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
  end
  object Panel4: TPanel
    Left = 350
    Top = 104
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Caption = 'WESTERN UNION $'
    Color = 11599871
    Font.Charset = ANSI_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 3
  end
  object Panel5: TPanel
    Left = 518
    Top = 104
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Caption = 'WESTERN UNION Ft'
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 4
  end
  object Panel6: TPanel
    Left = 686
    Top = 104
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Caption = #193'FAVISSZAIG'#201'NYL'#201'S'
    Color = 11599871
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 5
  end
  object Panel7: TPanel
    Left = 16
    Top = 200
    Width = 136
    Height = 142
    BevelOuter = bvNone
    Caption = 'BEV'#201'TEL'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 6
  end
  object Panel8: TPanel
    Left = 16
    Top = 152
    Width = 332
    Height = 46
    BevelOuter = bvNone
    Caption = 'NYIT'#211'K'#201'SZLET'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object Panel15: TPanel
    Left = 16
    Top = 488
    Width = 332
    Height = 46
    BevelOuter = bvNone
    Caption = 'Z'#193'R'#211'K'#201'SZLET'
    Color = 14745568
    Font.Charset = ANSI_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object Panel16: TPanel
    Left = 16
    Top = 344
    Width = 136
    Height = 142
    BevelOuter = bvNone
    Caption = 'KIAD'#193'S'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
  end
  object USDNYITOPANEL: TPanel
    Left = 350
    Top = 152
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 10
  end
  object HUFGBEPANEL: TPanel
    Left = 518
    Top = 200
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 11
  end
  object HUFNYITOPANEL: TPanel
    Left = 518
    Top = 152
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 12
  end
  object HUFGKIPANEL: TPanel
    Left = 518
    Top = 344
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 13
  end
  object USDGBEPANEL: TPanel
    Left = 350
    Top = 200
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 14
  end
  object AFANYITOPANEL: TPanel
    Left = 686
    Top = 152
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 15
  end
  object AFAGBEPANEL: TPanel
    Left = 686
    Top = 200
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 16
  end
  object USDGKIPANEL: TPanel
    Left = 350
    Top = 344
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 17
  end
  object USDZAROPANEL: TPanel
    Left = 350
    Top = 488
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 18
  end
  object AFAPBEPANEL: TPanel
    Left = 686
    Top = 296
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 19
  end
  object HUFZAROPANEL: TPanel
    Left = 518
    Top = 488
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 20
  end
  object AFAZAROPANEL: TPanel
    Left = 686
    Top = 488
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 21
  end
  object QUITGOMB: TBitBtn
    Left = 648
    Top = 544
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Cancel = True
    Caption = 'SZERVER MEN'#220
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 22
    OnClick = QUITGOMBClick
  end
  object Panel2: TPanel
    Left = 154
    Top = 200
    Width = 194
    Height = 46
    BevelOuter = bvNone
    Caption = 'Intercash/Innova'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 23
  end
  object Panel10: TPanel
    Left = 154
    Top = 248
    Width = 194
    Height = 46
    BevelOuter = bvNone
    Caption = #220'gyf'#233'lt'#246'l'
    Color = 14745568
    Font.Charset = ANSI_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 24
  end
  object Panel11: TPanel
    Left = 154
    Top = 296
    Width = 194
    Height = 46
    BevelOuter = bvNone
    Caption = 'P'#233'nzt'#225'rt'#243'l'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 25
  end
  object USDUBEPANEL: TPanel
    Left = 350
    Top = 248
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 26
  end
  object HUFUBEPANEL: TPanel
    Left = 518
    Top = 248
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 27
  end
  object Panel13: TPanel
    Left = 154
    Top = 344
    Width = 194
    Height = 46
    BevelOuter = bvNone
    BiDiMode = bdLeftToRight
    Caption = 'Intercash/innova'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentBiDiMode = False
    ParentFont = False
    TabOrder = 28
  end
  object Panel14: TPanel
    Left = 154
    Top = 392
    Width = 194
    Height = 46
    BevelOuter = bvNone
    Caption = #220'gyf'#233'lnek'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 29
  end
  object Panel17: TPanel
    Left = 154
    Top = 440
    Width = 194
    Height = 46
    BevelOuter = bvNone
    Caption = 'P'#233'nzt'#225'rnak'
    Color = 14745568
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clGreen
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 30
  end
  object USDPBEPANEL: TPanel
    Left = 350
    Top = 296
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 31
  end
  object USDUKIPANEL: TPanel
    Left = 350
    Top = 392
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 32
  end
  object HUFUKIPANEL: TPanel
    Left = 518
    Top = 392
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 33
  end
  object USDPKIPANEL: TPanel
    Left = 350
    Top = 440
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 34
  end
  object AFA: TPanel
    Left = 686
    Top = 248
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clMedGray
    TabOrder = 35
  end
  object HUFPBEPANEL: TPanel
    Left = 518
    Top = 296
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 36
  end
  object HUFPKIPANEL: TPanel
    Left = 518
    Top = 440
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 37
  end
  object AFAGKIPANEL: TPanel
    Left = 686
    Top = 344
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 38
  end
  object AFAUKIPANEL: TPanel
    Left = 686
    Top = 392
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 39
  end
  object AFAPKIPANEL: TPanel
    Left = 686
    Top = 440
    Width = 166
    Height = 46
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 40
  end
  object MASADATOKGOMB: TBitBtn
    Left = 24
    Top = 544
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S ADATOK'
    TabOrder = 41
    OnClick = MASADATOKGOMBClick
  end
  object MASEGYSEGGOMB: TBitBtn
    Left = 232
    Top = 544
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'M'#193'S EGYS'#201'G'
    TabOrder = 42
    OnClick = MASEGYSEGGOMBClick
  end
  object MASIDOSZAKGOMB: TBitBtn
    Left = 440
    Top = 544
    Width = 201
    Height = 25
    Cursor = crHandPoint
    Caption = 'MASIK ID'#336'SZAK'
    TabOrder = 43
    OnClick = MASIDOSZAKGOMBClick
  end
  object ZALOGPLUSBOX: TCheckBox
    Left = 320
    Top = 584
    Width = 409
    Height = 17
    Caption = 'AZ EXPRESSZ '#201'KSZERH'#193'ZZAL EGY'#220'TT'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWhite
    Font.Height = -16
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 44
    OnClick = ZALOGPLUSBOXClick
  end
  object RECEPTTABLA: TIBTable
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    TableName = 'WUNIGYUJTO'
    Left = 752
    Top = 16
  end
  object RECEPTDBASE: TIBDatabase
    DatabaseName = 'C:\RECEPTOR\DATABASE\RECEPTOR.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = RECEPTTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 784
    Top = 16
  end
  object RECEPTTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = RECEPTDBASE
    AutoStopAction = saNone
    Left = 816
    Top = 16
  end
  object RECEPTQUERY: TIBQuery
    Database = RECEPTDBASE
    Transaction = RECEPTTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 696
    Top = 16
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 16
    Top = 16
  end
end
