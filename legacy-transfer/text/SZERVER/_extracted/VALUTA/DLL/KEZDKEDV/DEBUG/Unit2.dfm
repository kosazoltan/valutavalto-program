object Form2: TForm2
  Left = 192
  Top = 125
  BorderStyle = bsNone
  Caption = 'Form2'
  ClientHeight = 383
  ClientWidth = 685
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  PixelsPerInch = 96
  TextHeight = 13
  object ALAPLAP: TPanel
    Left = 0
    Top = 0
    Width = 681
    Height = 381
    BevelOuter = bvNone
    Color = clGradientInactiveCaption
    TabOrder = 0
    OnMouseMove = ALAPLAPMouseMove
    object Shape1: TShape
      Left = 0
      Top = 0
      Width = 681
      Height = 381
      Align = alClient
      Brush.Color = 16311512
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label1: TLabel
      Left = 104
      Top = 16
      Width = 459
      Height = 31
      Caption = 'KEZEL'#201'SI D'#205'J KEDVEZM'#201'NYEK'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -27
      Font.Name = 'Cooper Black'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object FELEZOPANEL: TPanel
      Left = 24
      Top = 71
      Width = 209
      Height = 209
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnMouseMove = ALAPLAPMouseMove
      object Label2: TLabel
        Left = 24
        Top = 8
        Width = 170
        Height = 23
        Caption = 'KEZEL'#201'SI D'#205'J FELEZ'#201'SE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object PERMHALF: TPanel
        Tag = 1
        Left = 8
        Top = 48
        Width = 193
        Height = 57
        Cursor = crHandPoint
        Color = clWhite
        TabOrder = 0
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
        object Label5: TLabel
          Left = 8
          Top = 8
          Width = 174
          Height = 18
          Caption = #220'GYVEZET'#336', F'#336#201'RT'#201'KT'#193'ROS'
          OnClick = Label5Click
        end
        object Label6: TLabel
          Left = 48
          Top = 28
          Width = 90
          Height = 18
          Caption = 'ENGED'#201'LY'#201'VEL'
          OnClick = Label5Click
        end
      end
      object ACTHALF: TPanel
        Tag = 2
        Left = 8
        Top = 112
        Width = 193
        Height = 41
        Cursor = crHandPoint
        Caption = 'AKCI'#211' KERET'#201'BEN'
        Color = clWhite
        TabOrder = 1
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
      end
      object CARDHALF: TPanel
        Tag = 3
        Left = 8
        Top = 160
        Width = 193
        Height = 41
        Cursor = crHandPoint
        Caption = 'K'#193'RTY'#193'S FELEZ'#201'S'
        Color = clWhite
        TabOrder = 2
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
      end
    end
    object ELENGEDOPANEL: TPanel
      Left = 240
      Top = 72
      Width = 217
      Height = 161
      Color = clMoneyGreen
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnMouseMove = ALAPLAPMouseMove
      object Label3: TLabel
        Left = 8
        Top = 8
        Width = 197
        Height = 23
        Caption = 'KEZEL'#201'SI D'#205'J ELENGED'#201'SE'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object PERMDEL: TPanel
        Tag = 4
        Left = 8
        Top = 48
        Width = 200
        Height = 57
        Cursor = crHandPoint
        Color = clWhite
        TabOrder = 0
        OnClick = PERMDELClick
        OnMouseMove = PerMouseMove
        object Label7: TLabel
          Left = 16
          Top = 8
          Width = 174
          Height = 18
          Caption = #220'GYVEZET'#336', F'#336#201'RT'#201'KT'#193'ROS'
          OnClick = Label7Click
        end
        object Label8: TLabel
          Left = 48
          Top = 28
          Width = 90
          Height = 18
          Caption = 'ENGED'#201'LY'#201'VEL'
          OnClick = Label7Click
        end
      end
      object CARDDEL: TPanel
        Tag = 5
        Left = 8
        Top = 112
        Width = 200
        Height = 41
        Cursor = crHandPoint
        Caption = 'K'#193'RTY'#193'S ELENGED'#201'S'
        Color = clWhite
        TabOrder = 1
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
      end
    end
    object EXTRAPANEL: TPanel
      Left = 464
      Top = 72
      Width = 201
      Height = 161
      Color = clMoneyGreen
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnMouseMove = ALAPLAPMouseMove
      object Label4: TLabel
        Left = 8
        Top = 8
        Width = 176
        Height = 23
        Caption = 'SPECI'#193'LIS KEZEL'#201'SI D'#205'J'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object EGYEDI: TPanel
        Tag = 6
        Left = 8
        Top = 64
        Width = 185
        Height = 41
        Cursor = crHandPoint
        Caption = 'EGYEDI KEZEL'#201'SI D'#205'J (3%%)'
        Color = clWhite
        TabOrder = 0
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
      end
      object ANYTAX: TPanel
        Tag = 7
        Left = 8
        Top = 112
        Width = 185
        Height = 41
        Cursor = crHandPoint
        Caption = 'SPECI'#193'LIS KEZEL'#201'SI D'#205'J'
        Color = clWhite
        TabOrder = 1
        OnClick = PERMHALFClick
        OnMouseMove = PerMouseMove
      end
    end
    object Panel2: TPanel
      Left = 24
      Top = 288
      Width = 641
      Height = 33
      BevelOuter = bvNone
      Color = 16311512
      TabOrder = 3
      object CARDPANEL: TPanel
        Left = 450
        Top = 0
        Width = 190
        Height = 33
        BevelOuter = bvNone
        BiDiMode = bdLeftToRight
        Color = clMoneyGreen
        ParentBiDiMode = False
        TabOrder = 1
        Visible = False
        object Label9: TLabel
          Left = 8
          Top = 8
          Width = 97
          Height = 19
          Caption = 'K'#193'RTYASZ'#193'M:'
          Font.Charset = EASTEUROPE_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Calibri'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object CARDNUMEDIT: TEdit
          Left = 112
          Top = 4
          Width = 70
          Height = 26
          Color = clYellow
          Font.Charset = ANSI_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Calibri'
          Font.Style = []
          MaxLength = 10
          ParentFont = False
          TabOrder = 0
          OnKeyDown = CARDNUMEDITKeyDown
        end
      end
      object INFOPANEL: TPanel
        Left = 0
        Top = 0
        Width = 450
        Height = 33
        BevelOuter = bvNone
        Caption = 'KEZEL'#201'SI D'#205'J FELEZ'#201'SE '#220'GYVEZET'#336' VAGY F'#336#201'RT'#201'KT'#193'ROS ENGED'#201'LY'#201'VEL'
        Color = clCream
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        OnMouseMove = ALAPLAPMouseMove
      end
    end
    object MEGSEMGOMB: TBitBtn
      Left = 464
      Top = 340
      Width = 193
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM ADOK KEDVEZM'#201'NYT'
      TabOrder = 4
      OnClick = MEGSEMGOMBClick
    end
    object FORINTPANEL: TPanel
      Left = 224
      Top = 340
      Width = 85
      Height = 25
      BevelOuter = bvNone
      Caption = '5 800  Ft'
      Color = 16311512
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -21
      Font.Name = 'Calibri'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      Visible = False
    end
    object RENDBENGOMB: TBitBtn
      Left = 328
      Top = 340
      Width = 129
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Enabled = False
      TabOrder = 6
      OnClick = RENDBENGOMBClick
    end
    object TEXTPANEL: TPanel
      Left = 25
      Top = 336
      Width = 200
      Height = 33
      BevelOuter = bvNone
      Caption = 'KEDVEZM'#201'NYES KEZEL'#201'SI D'#205'J:'
      Color = 16311512
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 7
      Visible = False
    end
    object TAKARO: TPanel
      Left = -1789
      Top = 64
      Width = 649
      Height = 217
      BevelOuter = bvNone
      TabOrder = 9
      Visible = False
    end
    object GETKDPANEL: TPanel
      Left = 240
      Top = 240
      Width = 425
      Height = 40
      Color = clMoneyGreen
      TabOrder = 8
      Visible = False
      object Label10: TLabel
        Left = 16
        Top = 8
        Width = 256
        Height = 23
        Caption = 'K'#201'REM A ELT'#201'R'#336' KEZEL'#201'SI D'#205'JAT:'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label11: TLabel
        Left = 336
        Top = 8
        Width = 16
        Height = 23
        Caption = 'Ft'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object KEZDIJEDIT: TEdit
        Left = 280
        Top = 7
        Width = 49
        Height = 31
        Color = clYellow
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Calibri'
        Font.Style = [fsItalic]
        MaxLength = 4
        ParentFont = False
        TabOrder = 0
        OnKeyDown = KEZDIJEDITKeyDown
      end
    end
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 16
    Top = 8
  end
  object VALUTADBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = VALUTATRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 8
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 80
    Top = 8
  end
  object KILEPO: TTimer
    Enabled = False
    Interval = 150
    OnTimer = KILEPOTimer
    Left = 336
    Top = 200
  end
end
