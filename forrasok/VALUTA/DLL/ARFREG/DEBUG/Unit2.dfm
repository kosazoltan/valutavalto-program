object ARFOLYAMTAROLO: TARFOLYAMTAROLO
  Left = 200
  Top = 107
  BorderStyle = bsNone
  Caption = 'ARFOLYAMTAROLO'
  ClientHeight = 654
  ClientWidth = 1022
  Color = clInactiveCaptionText
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object TORTENETPANEL: TPanel
    Left = 320
    Top = 168
    Width = 481
    Height = 385
    BevelOuter = bvNone
    Color = clInactiveCaptionText
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 2
    Visible = False
    object Bevel1: TBevel
      Left = 16
      Top = 16
      Width = 449
      Height = 353
    end
    object Label1: TLabel
      Left = 64
      Top = 24
      Width = 349
      Height = 36
      Caption = #193'RFOLYAM T'#214'RT'#201'NET'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -32
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object EHAVIGOMB: TBitBtn
      Left = 56
      Top = 104
      Width = 185
      Height = 25
      Cursor = crHandPoint
      Caption = 'E-havi '#225'rfolyamok'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = EHAVIGOMBClick
    end
    object REGEBBIGOMB: TBitBtn
      Left = 264
      Top = 104
      Width = 161
      Height = 25
      Cursor = crHandPoint
      Caption = 'R'#233'gebbi '#225'rfolyamok'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = REGEBBIGOMBClick
    end
    object HOCOMBO: TComboBox
      Left = 224
      Top = 152
      Width = 153
      Height = 27
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 2
      Text = 'SZEPTEMBER'
      OnChange = EVCOMBOChange
    end
    object EVCOMBO: TComboBox
      Left = 128
      Top = 152
      Width = 89
      Height = 27
      Cursor = crHandPoint
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 19
      ParentFont = False
      TabOrder = 3
      Text = '2010'
      OnChange = EVCOMBOChange
    end
    object megsegomb: TBitBtn
      Left = 384
      Top = 336
      Width = 75
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -11
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = VISSZAGOMBClick
    end
    object DATUMRENDBENGOMB: TBitBtn
      Left = 192
      Top = 200
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'D'#225'tum rendben'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 5
      OnClick = datumrendbengombClick
    end
  end
  object WRITEPANEL: TPanel
    Left = 912
    Top = 360
    Width = 977
    Height = 610
    BevelOuter = bvNone
    Caption = 'AZ '#193'RFOLYAMT'#193'BLA R'#214'GZIT'#201'SE'
    Color = clInactiveCaptionText
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 0
  end
  object READPANEL: TPanel
    Left = -1987
    Top = 0
    Width = 1017
    Height = 649
    Color = 12300288
    TabOrder = 1
    Visible = False
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 1001
      Height = 33
      Brush.Color = clRed
      Shape = stRoundRect
    end
    object RACS: TStringGrid
      Left = 16
      Top = 45
      Width = 1001
      Height = 564
      ColCount = 8
      DefaultColWidth = 122
      DefaultRowHeight = 18
      FixedColor = 11599871
      RowCount = 29
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = []
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
    object KOVETKEZOGOMB: TBitBtn
      Left = 656
      Top = 612
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'K'#214'VETKEZ'#336
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = KOVETKEZOGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 824
      Top = 612
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'VISSZA'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = VISSZAGOMBClick
    end
    object LIMITGOMB: TBitBtn
      Left = 144
      Top = 612
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'KEDV. LIMITEK'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = LIMITGOMBClick
    end
    object KEDVEZMENYPANEL: TPanel
      Left = -555
      Top = 128
      Width = 440
      Height = 220
      BevelInner = bvRaised
      BevelWidth = 2
      Color = clInactiveCaptionText
      TabOrder = 4
      object Label2: TLabel
        Left = 104
        Top = 24
        Width = 248
        Height = 24
        Caption = 'KEDVEZM'#201'NY HAT'#193'ROK'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Times New Roman'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Panel3: TPanel
        Left = 32
        Top = 112
        Width = 97
        Height = 25
        Caption = '1.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object Panel4: TPanel
        Left = 32
        Top = 144
        Width = 97
        Height = 25
        Caption = '2.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object TOL1PANEL: TPanel
        Left = 144
        Top = 112
        Width = 120
        Height = 25
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
      end
      object TOL2PANEL: TPanel
        Left = 144
        Top = 144
        Width = 120
        Height = 25
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
      end
      object IG1PANEL: TPanel
        Left = 280
        Top = 112
        Width = 120
        Height = 25
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
      end
      object IG2PANEL: TPanel
        Left = 280
        Top = 144
        Width = 120
        Height = 25
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
      end
      object KEDVVISSZAGOMB: TBitBtn
        Left = 344
        Top = 184
        Width = 75
        Height = 25
        Cursor = crHandPoint
        Cancel = True
        Caption = 'Vissza'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Times New Roman'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 6
        OnClick = KEDVVISSZAGOMBClick
      end
      object Panel2: TPanel
        Left = 32
        Top = 72
        Width = 97
        Height = 25
        Caption = 'KEDVEZM'#201'NY'
        Color = clInactiveBorder
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 7
      end
      object Panel5: TPanel
        Left = 144
        Top = 72
        Width = 121
        Height = 25
        Caption = '- T'#211'L'
        Color = clInactiveBorder
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
      end
      object Panel8: TPanel
        Left = 280
        Top = 72
        Width = 121
        Height = 25
        Caption = '- IG'
        Color = clInactiveBorder
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 9
      end
    end
    object KISPANEL: TPanel
      Left = 52
      Top = 498
      Width = 80
      Height = 40
      BevelInner = bvRaised
      Color = clInactiveCaptionText
      TabOrder = 5
    end
    object MASIKHONAPGOMB: TBitBtn
      Left = 320
      Top = 612
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#193'SIK H'#211'NAP'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 6
      OnClick = MASIKHONAPGOMBClick
    end
    object ARFOLYAMCIMPANEL: TPanel
      Left = 16
      Top = 12
      Width = 985
      Height = 25
      BevelOuter = bvNone
      Caption = 
        '2010 SZEPTEMBER 30 12 '#211'RA 30 PERCKOR KIADOTT 77 SORSZ'#193'MU '#193'RFOLYA' +
        'MT'#193'BLA.'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 7
    end
    object ELOZOGOMB: TBitBtn
      Left = 488
      Top = 612
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'EL'#214'Z'#336
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 8
      OnClick = ELOZOGOMBClick
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 160
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
    Left = 160
    Top = 160
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 192
    Top = 160
  end
  object ARFOLYAMQUERY: TIBQuery
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 128
  end
  object ARFOLYAMDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\ARFOLYAM.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = ARFOLYAMTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 192
    Top = 128
  end
  object ARFOLYAMTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = ARFOLYAMDBASE
    AutoStopAction = saNone
    Left = 224
    Top = 128
  end
  object ARFOLYAMTABLA: TIBTable
    Database = ARFOLYAMDBASE
    Transaction = ARFOLYAMTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 128
    Top = 128
  end
  object USZOTIMER: TTimer
    Enabled = False
    Interval = 1
    OnTimer = USZOTIMERTimer
    Left = 144
    Top = 592
  end
  object kilepo: TTimer
    Enabled = False
    Interval = 50
    OnTimer = kilepoTimer
    Left = 48
    Top = 64
  end
end
