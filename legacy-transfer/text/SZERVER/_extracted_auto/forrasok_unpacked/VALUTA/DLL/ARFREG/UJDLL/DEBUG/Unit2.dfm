object ARFOLYAMTAROLO: TARFOLYAMTAROLO
  Left = 219
  Top = 122
  BorderStyle = bsNone
  ClientHeight = 741
  ClientWidth = 1008
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
  object READPANEL: TPanel
    Left = 5
    Top = 16
    Width = 998
    Height = 713
    BevelOuter = bvNone
    Color = clGray
    Font.Charset = ANSI_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'Calibri'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Visible = False
    object Shape1: TShape
      Left = 8
      Top = 8
      Width = 980
      Height = 33
      Brush.Color = clRed
      Pen.Color = clYellow
      Pen.Width = 3
      Shape = stRoundRect
    end
    object RACS: TStringGrid
      Left = 8
      Top = 45
      Width = 980
      Height = 620
      ColCount = 8
      DefaultColWidth = 120
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
    object ARFOLYAMCIMPANEL: TPanel
      Left = 16
      Top = 12
      Width = 961
      Height = 25
      BevelOuter = bvNone
      Caption = 
        '2010 SZEPTEMBER 30 12 '#211'RA 30 PERCKOR KIADOTT 77 SORSZ'#193'MU '#193'RFOLYA' +
        'MT'#193'BLA.'
      Color = clRed
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object MASIKDATUMGOMB: TBitBtn
      Left = 432
      Top = 672
      Width = 137
      Height = 25
      Caption = 'M'#193'SIK D'#193'TUM'
      TabOrder = 2
      OnClick = MASIKDATUMGOMBClick
    end
    object VISSZAGOMB: TBitBtn
      Left = 848
      Top = 672
      Width = 137
      Height = 25
      Cursor = crHandPoint
      Caption = 'VISSZA A F'#336'MEN'#220'RE'
      TabOrder = 3
      OnClick = VISSZAGOMBClick
    end
    object MASIKIDOGOMB: TBitBtn
      Left = 576
      Top = 672
      Width = 137
      Height = 25
      Caption = 'M'#193'SIK ID'#336'PONT'
      TabOrder = 4
      OnClick = MasikIdoGombClick
    end
    object MASIKHONAPGOMB: TBitBtn
      Left = 288
      Top = 672
      Width = 139
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#193'SIK H'#211'NAP'
      TabOrder = 5
      OnClick = MASIKHONAPGOMBClick
    end
    object DATUMVALASZTOPANEL: TPanel
      Left = 320
      Top = 184
      Width = 150
      Height = 337
      BevelOuter = bvNone
      TabOrder = 6
      Visible = False
      object Shape3: TShape
        Left = 0
        Top = 0
        Width = 150
        Height = 337
        Align = alClient
        Pen.Color = clRed
        Pen.Width = 3
      end
      object Label2: TLabel
        Left = 48
        Top = 16
        Width = 69
        Height = 23
        Caption = 'V'#193'LASSZ'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label3: TLabel
        Left = 40
        Top = 40
        Width = 82
        Height = 23
        Caption = 'D'#193'TUMOT'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
        Transparent = True
      end
      object DATUMBOX: TListBox
        Left = 16
        Top = 80
        Width = 121
        Height = 249
        BorderStyle = bsNone
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = []
        ItemHeight = 23
        Items.Strings = (
          '2023.01.23'
          '2023.10.25'
          '2023.10.26'
          '2023.10.28'
          '2023.10.29'
          '2023.10.30'
          '2023.10.31')
        ParentFont = False
        TabOrder = 0
        OnDblClick = DATUMBOXDblClick
      end
      object Panel1: TPanel
        Left = 4
        Top = 70
        Width = 140
        Height = 3
        BevelOuter = bvNone
        Color = clRed
        TabOrder = 1
      end
    end
    object IDOVALASZTOPANEL: TPanel
      Left = 650
      Top = 216
      Width = 105
      Height = 210
      BevelOuter = bvNone
      TabOrder = 7
      Visible = False
      object Shape4: TShape
        Left = 0
        Top = 0
        Width = 105
        Height = 210
        Align = alClient
        Pen.Color = clRed
        Pen.Width = 3
      end
      object Label4: TLabel
        Left = 24
        Top = 8
        Width = 59
        Height = 19
        Caption = 'V'#193'LASSZ'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object Label5: TLabel
        Left = 8
        Top = 24
        Width = 83
        Height = 19
        Caption = 'ID'#336'PONTOT'
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
      end
      object IDOBOX: TListBox
        Left = 16
        Top = 64
        Width = 73
        Height = 137
        BorderStyle = bsNone
        Font.Charset = ANSI_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ItemHeight = 19
        Items.Strings = (
          '18:11:04'
          '04:44:12'
          '06:12:33'
          '08.15:44')
        ParentFont = False
        TabOrder = 0
        OnDblClick = IDOBOXDblClick
      end
      object Panel2: TPanel
        Left = 5
        Top = 56
        Width = 95
        Height = 3
        BevelOuter = bvNone
        Color = clRed
        TabOrder = 1
      end
    end
  end
  object HONAPKEROPANEL: TPanel
    Left = -1989
    Top = 192
    Width = 313
    Height = 137
    BevelOuter = bvNone
    Caption = '  '
    Color = clSkyBlue
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Calibri'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 1
    Visible = False
    object Shape2: TShape
      Left = 0
      Top = 0
      Width = 313
      Height = 137
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 4
    end
    object Label1: TLabel
      Left = 32
      Top = 16
      Width = 248
      Height = 26
      Caption = 'K'#201'REM A KIV'#193'NT H'#211'NAPOT:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object EVCOMBO: TComboBox
      Left = 56
      Top = 48
      Width = 65
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 0
      Text = '2023'
    end
    object HOCOMBO: TComboBox
      Left = 120
      Top = 48
      Width = 137
      Height = 31
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsBold, fsItalic]
      ItemHeight = 23
      ParentFont = False
      TabOrder = 1
      Text = 'SZEPTEMBER'
    end
    object HONAPRENDBENGOMB: TBitBtn
      Left = 32
      Top = 88
      Width = 121
      Height = 25
      Caption = 'H'#211'NAP RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = HONAPRENDBENGOMBClick
    end
    object BitBtn3: TBitBtn
      Left = 160
      Top = 88
      Width = 121
      Height = 25
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
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
  object kilepo: TTimer
    Enabled = False
    Interval = 50
    OnTimer = kilepoTimer
    Left = 24
    Top = 88
  end
end
