object ELADASFORM: TELADASFORM
  Left = 192
  Top = 118
  BorderIcons = []
  BorderStyle = bsNone
  Caption = '0'
  ClientHeight = 755
  ClientWidth = 1001
  Color = clGradientActiveCaption
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Shape22: TShape
    Left = 0
    Top = 0
    Width = 1001
    Height = 756
    Brush.Color = 16756991
    Pen.Color = clNavy
    Pen.Width = 6
  end
  object Label6: TLabel
    Left = 560
    Top = 720
    Width = 42
    Height = 20
    Caption = 'End'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label10: TLabel
    Left = 808
    Top = 720
    Width = 72
    Height = 20
    Caption = 'Escape'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 296
    Top = 16
    Width = 441
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 344
    Top = 24
    Width = 373
    Height = 108
    Caption = 'ELAD'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clSilver
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label11: TLabel
    Left = 328
    Top = 16
    Width = 373
    Height = 108
    Caption = 'ELAD'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 752
    Top = 24
    Width = 225
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 24
    Top = 136
    Width = 945
    Height = 353
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape16: TShape
    Left = 40
    Top = 552
    Width = 177
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape17: TShape
    Left = 232
    Top = 552
    Width = 745
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape19: TShape
    Left = 448
    Top = 664
    Width = 249
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape20: TShape
    Left = 728
    Top = 664
    Width = 249
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape21: TShape
    Left = 24
    Top = 16
    Width = 257
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape25: TShape
    Left = 504
    Top = 496
    Width = 457
    Height = 48
    Brush.Color = clBlack
    Pen.Width = 2
  end
  object Panel14: TPanel
    Left = 506
    Top = 498
    Width = 103
    Height = 21
    Caption = 'Nett'#243' forint:'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 12
  end
  object Panel18: TPanel
    Left = 506
    Top = 520
    Width = 166
    Height = 21
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 16
  end
  object KDPANEL: TPanel
    Left = 40
    Top = 496
    Width = 457
    Height = 48
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 18
    object Shape18: TShape
      Left = 0
      Top = 0
      Width = 457
      Height = 48
      Align = alClient
      Pen.Width = 2
    end
    object TAKARO: TPanel
      Left = 2
      Top = 2
      Width = 453
      Height = 21
      BevelOuter = bvNone
      Color = clSilver
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 3
      Visible = False
    end
    object Panel11: TPanel
      Left = 2
      Top = 25
      Width = 103
      Height = 21
      Caption = 'Kezel'#233'si d'#237'j'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object EZRELEKPANEL: TPanel
      Left = 106
      Top = 25
      Width = 108
      Height = 21
      Color = clYellow
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object KEZDIJENGEDMENYGOMB: TBitBtn
      Left = 216
      Top = 25
      Width = 240
      Height = 21
      Cursor = crHandPoint
      Caption = 'Kezel'#233'si d'#237'j kedvezm'#233'nyek'
      Enabled = False
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = KEZDIJENGEDMENYGOMBClick
    end
  end
  object ENDGOMB: TBitBtn
    Left = 456
    Top = 672
    Width = 233
    Height = 33
    Cursor = crHandPoint
    Caption = 'K'#201'SZEN VAN'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = AdatbevitelKesz
  end
  object ESCAPEGOMB: TBitBtn
    Left = 736
    Top = 672
    Width = 233
    Height = 33
    Cursor = crHandPoint
    Caption = 'VISSZA A F'#214'MEN'#220'RE'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = ESCAPEGOMBClick
  end
  object SZAMLAALAPLAP: TPanel
    Left = 48
    Top = 144
    Width = 905
    Height = 329
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 2
    object Shape4: TShape
      Left = 123
      Top = 80
      Width = 313
      Height = 37
    end
    object Shape5: TShape
      Left = 123
      Top = 120
      Width = 313
      Height = 37
    end
    object Shape6: TShape
      Left = 123
      Top = 160
      Width = 313
      Height = 37
    end
    object Shape7: TShape
      Left = 123
      Top = 200
      Width = 313
      Height = 37
    end
    object Shape8: TShape
      Left = 123
      Top = 240
      Width = 313
      Height = 37
    end
    object Shape9: TShape
      Left = 123
      Top = 280
      Width = 313
      Height = 37
    end
    object Shape10: TShape
      Left = 746
      Top = 80
      Width = 145
      Height = 37
    end
    object Shape11: TShape
      Left = 746
      Top = 120
      Width = 145
      Height = 37
    end
    object Shape12: TShape
      Left = 746
      Top = 160
      Width = 145
      Height = 37
    end
    object Shape13: TShape
      Left = 746
      Top = 200
      Width = 145
      Height = 37
    end
    object Shape14: TShape
      Left = 746
      Top = 240
      Width = 145
      Height = 37
    end
    object Shape15: TShape
      Left = 746
      Top = 280
      Width = 145
      Height = 37
    end
    object Panel2: TPanel
      Left = 24
      Top = 40
      Width = 97
      Height = 33
      Caption = 'DNEM'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object Panel3: TPanel
      Left = 120
      Top = 40
      Width = 316
      Height = 33
      Caption = 'VALUTA MEGNEVEZ'#201'SE'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object Panel4: TPanel
      Left = 436
      Top = 40
      Width = 150
      Height = 33
      Caption = #193'RFOLYAM'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
    object Panel5: TPanel
      Left = 586
      Top = 40
      Width = 160
      Height = 33
      Caption = 'BANKJEGY'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
    end
    object Panel6: TPanel
      Left = 746
      Top = 40
      Width = 143
      Height = 33
      Caption = 'FIZETEND'#336
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 4
    end
    object WD1: TEdit
      Tag = 1
      Left = 24
      Top = 80
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 5
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WD2: TEdit
      Tag = 2
      Left = 24
      Top = 120
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 6
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WD3: TEdit
      Tag = 3
      Left = 24
      Top = 160
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 7
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WD4: TEdit
      Tag = 4
      Left = 24
      Top = 200
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 8
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WD5: TEdit
      Tag = 5
      Left = 24
      Top = 240
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 9
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WD6: TEdit
      Tag = 6
      Left = 24
      Top = 280
      Width = 97
      Height = 37
      BevelKind = bkFlat
      CharCase = ecUpperCase
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      MaxLength = 3
      ParentFont = False
      TabOrder = 10
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WN1: TPanel
      Tag = 1
      Left = 124
      Top = 81
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
    end
    object WN2: TPanel
      Tag = 2
      Left = 124
      Top = 121
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 12
    end
    object WN3: TPanel
      Tag = 3
      Left = 124
      Top = 161
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 13
    end
    object WN4: TPanel
      Tag = 4
      Left = 124
      Top = 201
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 14
    end
    object WN5: TPanel
      Tag = 5
      Left = 124
      Top = 241
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 15
    end
    object WA1: TEdit
      Tag = 1
      Left = 438
      Top = 80
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 16
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA2: TEdit
      Tag = 2
      Left = 438
      Top = 120
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 17
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA3: TEdit
      Tag = 3
      Left = 438
      Top = 160
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 18
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA4: TEdit
      Tag = 4
      Left = 438
      Top = 200
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 19
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA5: TEdit
      Tag = 5
      Left = 438
      Top = 240
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 20
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA6: TEdit
      Tag = 6
      Left = 438
      Top = 280
      Width = 148
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 21
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WB1: TEdit
      Tag = 1
      Left = 588
      Top = 80
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 22
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WB2: TEdit
      Tag = 2
      Left = 588
      Top = 120
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 23
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WB3: TEdit
      Tag = 3
      Left = 588
      Top = 160
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WB4: TEdit
      Tag = 4
      Left = 588
      Top = 200
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 25
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WB5: TEdit
      Tag = 5
      Left = 588
      Top = 240
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WB6: TEdit
      Tag = 6
      Left = 588
      Top = 280
      Width = 156
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 27
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WF1: TPanel
      Tag = 1
      Left = 747
      Top = 81
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 28
    end
    object WF2: TPanel
      Tag = 2
      Left = 747
      Top = 121
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 29
    end
    object WF3: TPanel
      Tag = 3
      Left = 747
      Top = 161
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 30
    end
    object WF4: TPanel
      Tag = 4
      Left = 747
      Top = 201
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 31
    end
    object WF6: TPanel
      Tag = 6
      Left = 747
      Top = 281
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 32
    end
    object WN6: TPanel
      Tag = 6
      Left = 124
      Top = 281
      Width = 311
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 33
    end
    object WF5: TPanel
      Tag = 5
      Left = 747
      Top = 241
      Width = 143
      Height = 35
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 34
    end
    object BKINFOPANEL: TPanel
      Left = 312
      Top = 0
      Width = 369
      Height = 41
      BevelOuter = bvNone
      Caption = 'BANK'#193'RTY'#193'S FIZET'#201'S !'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -24
      Font.Name = 'Arial Narrow'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 35
      Visible = False
    end
  end
  object Panel7: TPanel
    Left = 48
    Top = 560
    Width = 161
    Height = 89
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 3
    object Label2: TLabel
      Left = 24
      Top = 16
      Width = 119
      Height = 24
      Caption = 'BLOKKSZ'#193'M:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object BIZONYLATLABEL: TLabel
      Left = 8
      Top = 48
      Width = 144
      Height = 29
      Caption = 'E123456789'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel8: TPanel
    Left = 240
    Top = 560
    Width = 729
    Height = 89
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 4
    object Label4: TLabel
      Left = 24
      Top = 32
      Width = 154
      Height = 29
      Caption = 'FIZETEND'#336':'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object SUMOSSZEGLABEL: TLabel
      Left = 200
      Top = -16
      Width = 504
      Height = 109
      Caption = '                   0'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -96
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object KONVSUMPANEL: TPanel
      Left = 0
      Top = 0
      Width = 193
      Height = 89
      BevelOuter = bvNone
      Color = 11599871
      TabOrder = 0
      object Label14: TLabel
        Left = 8
        Top = 16
        Width = 174
        Height = 23
        Caption = 'Konverzi'#243's elad'#225's'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
      object Label25: TLabel
        Left = 40
        Top = 48
        Width = 113
        Height = 23
        Caption = 'forint '#233'rt'#233'ke'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsBold, fsItalic]
        ParentFont = False
      end
    end
  end
  object TRANZDIJPANEL: TPanel
    Left = 863
    Top = 498
    Width = 96
    Height = 21
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 7
  end
  object NETTOPANEL: TPanel
    Left = 610
    Top = 498
    Width = 113
    Height = 21
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 8
  end
  object LIMITBEKEROPANEL: TPanel
    Left = -1800
    Top = 300
    Width = 465
    Height = 153
    BevelOuter = bvNone
    BevelWidth = 2
    Color = 16756991
    TabOrder = 5
    Visible = False
    object Shape23: TShape
      Left = 0
      Top = 0
      Width = 465
      Height = 153
      Align = alClient
      Brush.Color = 16756991
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label8: TLabel
      Left = 24
      Top = 24
      Width = 425
      Height = 24
      Caption = 'H'#193'NY FORINT'#201'RT V'#193'S'#193'ROLNA VALUT'#193'T ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object Label9: TLabel
      Left = 280
      Top = 68
      Width = 81
      Height = 29
      Caption = 'forint'#233'rt'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      Transparent = True
    end
    object LIMITEDIT: TEdit
      Left = 152
      Top = 64
      Width = 121
      Height = 37
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      Text = '1000000'
      OnEnter = LIMITEDITEnter
      OnExit = LIMITEDITExit
      OnKeyDown = LIMITEDITKeyDown
    end
    object LIMITOKEGOMB: TBitBtn
      Left = 112
      Top = 112
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'RENDBEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = LIMITOKEGOMBClick
    end
    object LIMITMEGSEMGOMB: TBitBtn
      Left = 240
      Top = 112
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Cancel = True
      Caption = 'M'#201'GSEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = LIMITMEGSEMGOMBClick
    end
  end
  object arfolyamgomb: TPanel
    Left = 760
    Top = 56
    Width = 209
    Height = 33
    Cursor = crHandPoint
    Caption = #193'RFOLYAM ENGEDM'#201'NYEK'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
    OnClick = ARFOLYAMGOMBClick
  end
  object KONVCIMPANEL: TPanel
    Left = 312
    Top = 18
    Width = 409
    Height = 100
    BevelOuter = bvNone
    Caption = 'Konverzi'#243's elad'#225's'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -48
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 10
  end
  object Panel10: TPanel
    Left = 32
    Top = 24
    Width = 241
    Height = 89
    BevelOuter = bvNone
    Caption = ' '
    Color = clWhite
    TabOrder = 11
    object Label5: TLabel
      Left = 0
      Top = 16
      Width = 112
      Height = 19
      Caption = 'FORINT KERET:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object Label19: TLabel
      Left = 40
      Top = 56
      Width = 66
      Height = 19
      Caption = 'MARADT:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object LIMITFORINT: TPanel
      Left = 112
      Top = 8
      Width = 121
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
    end
    object MARADTForint: TPanel
      Left = 112
      Top = 48
      Width = 121
      Height = 33
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
    end
    object LIMITTAKARO: TPanel
      Left = 0
      Top = 0
      Width = 241
      Height = 89
      Align = alClient
      BevelOuter = bvNone
      Color = clWhite
      TabOrder = 2
      object Label16: TLabel
        Left = 64
        Top = 32
        Width = 114
        Height = 23
        Caption = 'NINCS LIMIT'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object SETLIMITGOMB: TBitBtn
        Left = 24
        Top = 24
        Width = 201
        Height = 41
        Cursor = crHandPoint
        Caption = 'LIMIT BE'#193'LL'#205'T'#193'S'
        Font.Charset = EASTEUROPE_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Arial'
        Font.Style = [fsItalic]
        ParentFont = False
        TabOrder = 0
        OnClick = SETLIMITGOMBClick
      end
    end
  end
  object Panel15: TPanel
    Left = 724
    Top = 498
    Width = 138
    Height = 21
    BevelOuter = bvNone
    Caption = 'Kezel'#233'si k'#246'lts'#233'g:'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 13
  end
  object KEREKITESPANEL: TPanel
    Left = 863
    Top = 520
    Width = 96
    Height = 21
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 14
  end
  object Panel17: TPanel
    Left = 672
    Top = 520
    Width = 190
    Height = 21
    Caption = 'Kerek'#237't'#233'si kompenz'#225'ci'#243':'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 15
  end
  object NOINTERNETPANEL: TPanel
    Left = 64
    Top = 144
    Width = 225
    Height = 33
    Caption = 'NINCS SZERVER'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 17
    Visible = False
  end
  object QUITSUREPANEL: TPanel
    Left = -889
    Top = 300
    Width = 453
    Height = 161
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 6
    Visible = False
    object Shape24: TShape
      Left = 0
      Top = 0
      Width = 453
      Height = 161
      Align = alClient
      Brush.Color = 16728319
      Pen.Color = clMaroon
      Pen.Width = 5
      Shape = stRoundRect
    end
    object Label3: TLabel
      Left = 40
      Top = 40
      Width = 388
      Height = 24
      Caption = 'BIZTOSAN ELVETI EZT AZ ELAD'#193'ST ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clYellow
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object IGENKILEPGOMB: TBitBtn
      Left = 112
      Top = 96
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IgenKilepGombClick
      OnEnter = NemlepkiGombEnter
      OnExit = NemlepkiGombExit
    end
    object NEMLEPKIGOMB: TBitBtn
      Left = 240
      Top = 96
      Width = 121
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clMaroon
      Font.Height = -16
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NemlepkiGOMBClick
      OnEnter = NemlepkiGombEnter
      OnExit = NemlepkiGombExit
    end
  end
  object KONVHIBAPANEL: TPanel
    Left = -1985
    Top = 304
    Width = 473
    Height = 140
    TabOrder = 19
    Visible = False
    object Shape32: TShape
      Left = 1
      Top = 1
      Width = 471
      Height = 138
      Align = alClient
      Pen.Color = clRed
      Pen.Width = 5
    end
    object Label17: TLabel
      Left = 64
      Top = 40
      Width = 347
      Height = 21
      Caption = 'KONVERZI'#211' NEM FOLYTATHAT'#211
      Font.Charset = ANSI_CHARSET
      Font.Color = clRed
      Font.Height = -16
      Font.Name = 'Elephant'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
    end
    object mindiffpanel: TPanel
      Left = 40
      Top = 72
      Width = 417
      Height = 41
      BevelOuter = bvNone
      Caption = 'az elad'#225's '#233'rt'#233'ke t'#246'bb, mint a v'#233'tel '#233'rt'#233'ke'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      Visible = False
    end
    object toobigpanel: TPanel
      Left = 24
      Top = 72
      Width = 417
      Height = 41
      BevelOuter = bvNone
      Caption = 'a v'#233'tel '#233'rt'#233'ke t'#246'bb, mint 5.000 Ft az elad'#225's '#233'rt'#233'k'#233'hez k'#233'pest'
      Color = clWhite
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      Visible = False
    end
  end
  object ENGEDELYADOPANEL: TPanel
    Left = -1987
    Top = 320
    Width = 425
    Height = 241
    BevelOuter = bvNone
    Color = clWhite
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Calibri'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 20
    Visible = False
    object Shape26: TShape
      Left = 0
      Top = 0
      Width = 425
      Height = 241
      Align = alClient
    end
    object Label7: TLabel
      Left = 32
      Top = 32
      Width = 360
      Height = 26
      Caption = 'AZ '#193'RFOLYAMKEDVEZM'#201'NY AD'#193'S'#193'NAK TIPUSA'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Impact'
      Font.Style = []
      ParentFont = False
    end
    object ETGOMB: TPanel
      Tag = 16
      Left = 40
      Top = 80
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = #201'RT'#201'KT'#193'ROS ENGED'#201'LYEZTE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = 25
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = ETGOMBClick
    end
    object FETGOMB: TPanel
      Tag = 32
      Left = 40
      Top = 112
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'F'#336#201'RT'#201'KT'#193'ROS ENGED'#201'LYEZTE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = 25
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = ETGOMBClick
    end
    object UVGOMB: TPanel
      Tag = 64
      Left = 40
      Top = 144
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = #220'GYVEZET'#336' ENGED'#201'LYEZTE'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = 25
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ETGOMBClick
    end
    object MENTESGOMB: TPanel
      Tag = 128
      Left = 40
      Top = 176
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'JUTAL'#201'KMENTES ENGED'#201'LYEZ'#201'S'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = 25
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ETGOMBClick
    end
  end
  object TETDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\VALUTA.FDB'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TETTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 232
  end
  object TETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 240
    Top = 232
  end
  object TETQUERY: TIBQuery
    Database = TETDBASE
    Transaction = TETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 232
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 304
    Top = 232
  end
  object TEMPDBASE: TIBDatabase
    DatabaseName = 'C:\VALUTA\DATABASE\valuta.fdb'
    Params.Strings = (
      'user_name=SYSDBA'
      'lc_ctype=WIN1250'
      'password=dek@nySo')
    LoginPrompt = False
    DefaultTransaction = TEMPTRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 336
    Top = 232
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 368
    Top = 232
  end
  object VEGETIMER: TTimer
    Enabled = False
    Interval = 150
    OnTimer = VEGETIMERTimer
    Left = 88
    Top = 224
  end
  object VALUTATRANZ: TIBTransaction
    Active = False
    DefaultDatabase = VALUTADBASE
    AutoStopAction = saNone
    Left = 400
    Top = 272
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
    Left = 368
    Top = 272
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 336
    Top = 272
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 304
    Top = 272
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 176
    Top = 272
  end
  object REMOTEDBASE: TIBDatabase
    Params.Strings = (
      'user_name=SYSDBA'
      'password=dek@nySo'
      'lc_ctype=WIN1250')
    LoginPrompt = False
    DefaultTransaction = REMOTETRANZ
    IdleTimer = 0
    SQLDialect = 3
    TraceFlags = []
    Left = 208
    Top = 272
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 240
    Top = 272
  end
  object KILEP: TTimer
    Enabled = False
    Interval = 120
    OnTimer = KILEPTimer
    Left = 48
    Top = 88
  end
end
