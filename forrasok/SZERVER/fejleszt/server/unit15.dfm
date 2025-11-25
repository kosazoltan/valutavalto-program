object UGYFELFORGALOMPOTLO: TUGYFELFORGALOMPOTLO
  Left = 192
  Top = 114
  Width = 696
  Height = 480
  Caption = 'UGYFELFORGALOMPOTLO'
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
    Left = 8
    Top = 8
    Width = 673
    Height = 433
    Color = clActiveBorder
    TabOrder = 0
    object Label1: TLabel
      Left = 144
      Top = 16
      Width = 419
      Height = 29
      Caption = #220'GYF'#201'LFORGALOM K'#201'ZI P'#211'TL'#193'SA'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 80
      Top = 56
      Width = 196
      Height = 20
      Caption = 'IRODA MEGNEVEZ'#201'SE:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 192
      Top = 88
      Width = 74
      Height = 20
      Caption = 'D'#193'TUM:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label18: TLabel
      Left = 16
      Top = 112
      Width = 76
      Height = 16
      Caption = 'VALUT'#193'K'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object IRODANEVPANEL: TPanel
      Left = 280
      Top = 56
      Width = 361
      Height = 25
      Color = clInactiveCaptionText
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object DATUMPANEL: TPanel
      Left = 280
      Top = 88
      Width = 361
      Height = 25
      Color = clInactiveCaptionText
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object BitBtn1: TBitBtn
      Left = 488
      Top = 400
      Width = 155
      Height = 25
      Cursor = crHandPoint
      Caption = 'M'#201'GSEM R'#214'GZITEM'
      TabOrder = 2
      OnClick = BitBtn1Click
    end
    object ROGZITOGOMB: TBitBtn
      Left = 24
      Top = 392
      Width = 153
      Height = 25
      Cursor = crHandPoint
      Caption = 'ADATOK R'#214'GZIT'#201'SE'
      TabOrder = 3
      OnClick = ROGZITOGOMBClick
    end
    object VALUTALISTA: TListBox
      Left = 24
      Top = 136
      Width = 65
      Height = 249
      Cursor = crHandPoint
      ItemHeight = 13
      TabOrder = 4
      OnClick = VALUTALISTAClick
      OnDblClick = VALUTALISTAClick
      OnEnter = VALUTALISTAEnter
      OnExit = VALUTALISTAExit
      OnKeyDown = VALUTALISTAKeyDown
      OnKeyUp = Edit1KeyUp
    end
    object Panel4: TPanel
      Left = 120
      Top = 136
      Width = 529
      Height = 249
      Color = clWhite
      TabOrder = 5
      object Label4: TLabel
        Left = 0
        Top = 20
        Width = 238
        Height = 20
        Caption = 'VALUTA MEGNEVEZ'#201'SE:  '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label5: TLabel
        Left = 85
        Top = 65
        Width = 138
        Height = 16
        Caption = 'V'#193'S'#193'ROLT VALUTA:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 432
        Top = 65
        Width = 72
        Height = 20
        Caption = 'Forint'#233'rt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label7: TLabel
        Left = 95
        Top = 95
        Width = 129
        Height = 16
        Caption = 'ELADOTT VALUTA:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label8: TLabel
        Left = 8
        Top = 155
        Width = 215
        Height = 16
        Caption = 'VALUTA '#193'TAD'#193'S P'#201'NZT'#193'RNAK:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label9: TLabel
        Left = 5
        Top = 125
        Width = 220
        Height = 16
        Caption = 'VALUTA '#193'TV'#201'TEL P'#201'NZT'#193'RT'#211'L:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label10: TLabel
        Left = 88
        Top = 152
        Width = 3
        Height = 13
      end
      object Label11: TLabel
        Left = 32
        Top = 185
        Width = 192
        Height = 16
        Caption = 'VALUTA '#193'TV'#201'TEL BANKT'#211'L:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label12: TLabel
        Left = 30
        Top = 215
        Width = 187
        Height = 16
        Alignment = taRightJustify
        Caption = 'VALUTA '#193'TAD'#193'S BANKNAK:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label13: TLabel
        Left = 432
        Top = 95
        Width = 72
        Height = 20
        Caption = 'Forint'#233'rt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label14: TLabel
        Left = 432
        Top = 125
        Width = 85
        Height = 20
        Caption = 'P'#233'nzt'#225'rt'#243'l'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label15: TLabel
        Left = 432
        Top = 155
        Width = 93
        Height = 20
        Caption = 'P'#233'nzt'#225'rnak'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label16: TLabel
        Left = 432
        Top = 185
        Width = 65
        Height = 20
        Caption = 'Bankt'#243'l'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object Label17: TLabel
        Left = 432
        Top = 215
        Width = 73
        Height = 20
        Caption = 'Banknak'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object VETTVALEDIT: TEdit
        Tag = 1
        Left = 224
        Top = 60
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object VETTFORINTEDIT: TEdit
        Tag = 2
        Left = 328
        Top = 60
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object ELADOTTVALEDIT: TEdit
        Tag = 3
        Left = 224
        Top = 90
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object ATVETTEDIT: TEdit
        Tag = 5
        Left = 224
        Top = 120
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object ATADOTTEDIT: TEdit
        Tag = 7
        Left = 224
        Top = 150
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object BANKIATVETEDIT: TEdit
        Tag = 9
        Left = 224
        Top = 180
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object BANKIATADASEDIT: TEdit
        Tag = 11
        Left = 224
        Top = 210
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 6
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object ELADOTTFORINTEDIT: TEdit
        Tag = 4
        Left = 328
        Top = 90
        Width = 97
        Height = 28
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 7
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object TOLPENZTAR: TEdit
        Tag = 6
        Left = 328
        Top = 120
        Width = 97
        Height = 28
        CharCase = ecUpperCase
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        MaxLength = 4
        ParentFont = False
        TabOrder = 8
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object NAKPENZTAR: TEdit
        Tag = 8
        Left = 328
        Top = 150
        Width = 97
        Height = 28
        CharCase = ecUpperCase
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        MaxLength = 4
        ParentFont = False
        TabOrder = 9
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object TOLBANK: TEdit
        Tag = 10
        Left = 328
        Top = 180
        Width = 97
        Height = 28
        CharCase = ecUpperCase
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        MaxLength = 4
        ParentFont = False
        TabOrder = 10
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object NAKBANK: TEdit
        Tag = 12
        Left = 328
        Top = 210
        Width = 97
        Height = 28
        CharCase = ecUpperCase
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        MaxLength = 4
        ParentFont = False
        TabOrder = 11
        OnEnter = VETTVALEDITEnter
        OnExit = VETTVALEDITExit
        OnKeyDown = VETTVALEDITKeyDown
      end
      object VALNEVPANEL: TPanel
        Left = 224
        Top = 8
        Width = 201
        Height = 41
        Caption = 'AUSZTR'#193'L DOLL'#193'R'
        Color = clInactiveCaptionText
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -16
        Font.Name = 'MS Sans Serif'
        Font.Style = []
        ParentFont = False
        TabOrder = 12
      end
    end
  end
  object BLOKKDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = BLOKKTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 48
    Top = 16
  end
  object BLOKKTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = BLOKKDBASE
    AutoStopAction = saNone
    Left = 80
    Top = 16
  end
  object BLOKKQUERY: TIBQuery
    Database = BLOKKDBASE
    Transaction = BLOKKTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 120
    Top = 16
  end
end
