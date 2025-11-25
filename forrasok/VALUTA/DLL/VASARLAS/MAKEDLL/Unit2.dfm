object VASARLASFORM: TVASARLASFORM
  Left = 197
  Top = 130
  AlphaBlendValue = 225
  BorderIcons = []
  BorderStyle = bsNone
  BorderWidth = 2
  Caption = 'eur'
  ClientHeight = 752
  ClientWidth = 1031
  Color = 6324288
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Shape23: TShape
    Left = -16
    Top = -8
    Width = 1000
    Height = 752
    Brush.Color = 10726813
    Pen.Color = clGray
    Pen.Width = 5
  end
  object Label4: TLabel
    Left = 544
    Top = 710
    Width = 37
    Height = 24
    Caption = 'End'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Label6: TLabel
    Left = 816
    Top = 710
    Width = 62
    Height = 24
    Caption = 'Escape'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -21
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape1: TShape
    Left = 152
    Top = 10
    Width = 649
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label1: TLabel
    Left = 240
    Top = 16
    Width = 516
    Height = 109
    Caption = 'V'#193'S'#193'RL'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clSilver
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label7: TLabel
    Left = 224
    Top = 8
    Width = 516
    Height = 109
    Caption = 'V'#193'S'#193'RL'#193'S'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clNavy
    Font.Height = -96
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Shape2: TShape
    Left = 24
    Top = 128
    Width = 945
    Height = 361
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 40
    Top = 550
    Width = 177
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape4: TShape
    Left = 232
    Top = 550
    Width = 745
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape6: TShape
    Left = 432
    Top = 660
    Width = 265
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape7: TShape
    Left = 712
    Top = 660
    Width = 265
    Height = 49
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape20: TShape
    Left = 816
    Top = 8
    Width = 169
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Shape22: TShape
    Left = 8
    Top = 8
    Width = 129
    Height = 105
    Pen.Width = 2
    Shape = stRoundRect
  end
  object Label8: TLabel
    Left = 24
    Top = 16
    Width = 102
    Height = 16
    Caption = 'SAJ'#193'THAT'#193'SK'#214'R'#220
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold]
    ParentFont = False
    Transparent = True
  end
  object Label9: TLabel
    Left = 40
    Top = 32
    Width = 69
    Height = 16
    Caption = 'ENGEDM'#201'NY'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial Narrow'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    Transparent = True
  end
  object Shape24: TShape
    Left = 40
    Top = 496
    Width = 460
    Height = 48
    Brush.Color = clBlack
    Pen.Width = 2
  end
  object Shape5: TShape
    Left = 504
    Top = 496
    Width = 457
    Height = 48
    Brush.Color = clBlack
    Pen.Width = 2
  end
  object Panel14: TPanel
    Left = 42
    Top = 498
    Width = 455
    Height = 22
    BevelOuter = bvNone
    TabOrder = 21
  end
  object Panel11: TPanel
    Left = 506
    Top = 520
    Width = 167
    Height = 21
    TabOrder = 15
  end
  object Panel12: TPanel
    Left = 506
    Top = 498
    Width = 103
    Height = 21
    BevelOuter = bvNone
    Caption = 'Nett'#243' forint:'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 16
  end
  object KEZDIJENGEDMENYGOMB: TBitBtn
    Left = 256
    Top = 522
    Width = 241
    Height = 21
    Cursor = crHandPoint
    Caption = 'Kezel'#233'si d'#237'j engedm'#233'nyek'
    Enabled = False
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -15
    Font.Name = 'Arial'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 20
    OnClick = KezdijEngedmenyGombClick
  end
  object SZAMLAALAPLAP: TPanel
    Left = 40
    Top = 136
    Width = 905
    Height = 329
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    object Shape8: TShape
      Left = 123
      Top = 80
      Width = 313
      Height = 37
    end
    object Shape9: TShape
      Left = 123
      Top = 120
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
      Left = 123
      Top = 160
      Width = 313
      Height = 37
    end
    object Shape12: TShape
      Left = 123
      Top = 200
      Width = 313
      Height = 37
    end
    object Shape13: TShape
      Left = 123
      Top = 240
      Width = 313
      Height = 37
    end
    object Shape14: TShape
      Left = 123
      Top = 280
      Width = 313
      Height = 37
    end
    object Shape15: TShape
      Left = 746
      Top = 120
      Width = 145
      Height = 37
    end
    object Shape16: TShape
      Left = 746
      Top = 160
      Width = 145
      Height = 37
    end
    object Shape17: TShape
      Left = 746
      Top = 200
      Width = 145
      Height = 37
    end
    object Shape18: TShape
      Left = 746
      Top = 240
      Width = 145
      Height = 37
    end
    object Shape19: TShape
      Left = 746
      Top = 280
      Width = 145
      Height = 37
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
      TabOrder = 0
      Text = ' '
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
      TabOrder = 1
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
      TabOrder = 2
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
      TabOrder = 3
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
      TabOrder = 4
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
      TabOrder = 5
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = DnemKeyDown
    end
    object WA1: TEdit
      Tag = 1
      Left = 438
      Top = 80
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 6
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
      TabOrder = 7
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object Panel1: TPanel
      Left = 24
      Top = 40
      Width = 97
      Height = 33
      BevelWidth = 2
      Caption = 'DNEM'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
    end
    object Panel5: TPanel
      Left = 120
      Top = 40
      Width = 316
      Height = 33
      BevelWidth = 2
      Caption = 'VALUTA MEGNEVEZ'#201'SE'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
    end
    object Panel6: TPanel
      Left = 436
      Top = 40
      Width = 150
      Height = 33
      BevelWidth = 2
      Caption = #193'RFOLYAM'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
    end
    object Panel7: TPanel
      Left = 586
      Top = 40
      Width = 160
      Height = 33
      BevelWidth = 2
      Caption = 'BANKJEGY'
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
    end
    object Panel8: TPanel
      Left = 746
      Top = 40
      Width = 143
      Height = 33
      BevelWidth = 2
      Caption = 'FIZETEND'#336
      Color = 16311512
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 12
    end
    object WA2: TEdit
      Tag = 2
      Left = 440
      Top = 120
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 13
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA3: TEdit
      Tag = 3
      Left = 440
      Top = 160
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 14
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA4: TEdit
      Tag = 4
      Left = 440
      Top = 200
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 15
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA5: TEdit
      Tag = 5
      Left = 440
      Top = 240
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 16
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
    end
    object WA6: TEdit
      Tag = 6
      Left = 440
      Top = 280
      Width = 148
      Height = 37
      Cursor = crHandPoint
      BevelKind = bkFlat
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      TabOrder = 17
      Text = ' '
      OnDblClick = WA1DblClick
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = ArfolyamKeyDown
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
      TabOrder = 18
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
      TabOrder = 19
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
      TabOrder = 20
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
      TabOrder = 21
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
      TabOrder = 22
      Text = ' '
      OnEnter = WD1Enter
      OnExit = WD1Exit
      OnKeyDown = BankjegyKeyDown
    end
    object WN1: TPanel
      Tag = 1
      Left = 128
      Top = 81
      Width = 305
      Height = 32
      BevelOuter = bvNone
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 23
    end
    object WN2: TPanel
      Tag = 2
      Left = 124
      Top = 121
      Width = 311
      Height = 35
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 24
    end
    object WN3: TPanel
      Tag = 3
      Left = 124
      Top = 161
      Width = 311
      Height = 35
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 25
    end
    object WN4: TPanel
      Tag = 4
      Left = 124
      Top = 201
      Width = 311
      Height = 35
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 26
    end
    object WN5: TPanel
      Tag = 5
      Left = 124
      Top = 241
      Width = 311
      Height = 35
      Caption = ' '
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 27
    end
    object WN6: TPanel
      Tag = 6
      Left = 124
      Top = 281
      Width = 311
      Height = 35
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
    object WF1: TPanel
      Tag = 1
      Left = 747
      Top = 81
      Width = 143
      Height = 35
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
    object WF2: TPanel
      Tag = 2
      Left = 747
      Top = 121
      Width = 143
      Height = 35
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
    object WF3: TPanel
      Tag = 3
      Left = 747
      Top = 161
      Width = 143
      Height = 35
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
    object WF4: TPanel
      Tag = 4
      Left = 747
      Top = 201
      Width = 143
      Height = 35
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
    object WF5: TPanel
      Tag = 5
      Left = 747
      Top = 241
      Width = 143
      Height = 35
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
    object WF6: TPanel
      Tag = 6
      Left = 747
      Top = 281
      Width = 143
      Height = 35
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
  end
  object Panel3: TPanel
    Left = 240
    Top = 560
    Width = 729
    Height = 81
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clWhite
    TabOrder = 1
    object SUMOSSZEGLABEL: TLabel
      Left = 200
      Top = -8
      Width = 48
      Height = 109
      Caption = '0'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clRed
      Font.Height = -96
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 8
      Top = 24
      Width = 177
      Height = 33
      Caption = 'FIZETEND'#336':'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -29
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object ESCAPEGOMB: TBitBtn
    Left = 720
    Top = 668
    Width = 249
    Height = 33
    Cursor = crHandPoint
    Cancel = True
    Caption = 'Vissza a f'#246'men'#252're'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = ESCAPEGOMBClick
  end
  object ENDGOMB: TBitBtn
    Left = 440
    Top = 668
    Width = 249
    Height = 33
    Cursor = crHandPoint
    Caption = 'K'#233'szen van'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = AdatBevitelkesz
  end
  object Panel4: TPanel
    Left = 48
    Top = 552
    Width = 153
    Height = 89
    BevelOuter = bvNone
    BevelWidth = 2
    Color = clWhite
    TabOrder = 4
    object Label3: TLabel
      Left = 16
      Top = 16
      Width = 135
      Height = 24
      Caption = 'BLOKKSZ'#193'M:'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Times New Roman'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object BIZONYLATLABEL: TLabel
      Left = 8
      Top = 56
      Width = 8
      Height = 29
      Caption = ' '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -23
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object SHKPANEL: TPanel
    Left = 44
    Top = 56
    Width = 57
    Height = 49
    BevelOuter = bvNone
    Caption = ' '
    Color = clWhite
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -48
    Font.Name = 'Arial Rounded MT Bold'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
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
  object ezrelekpanel: TPanel
    Left = 147
    Top = 522
    Width = 108
    Height = 21
    Cursor = crHandPoint
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
  object NETTOPANEL: TPanel
    Left = 610
    Top = 498
    Width = 113
    Height = 21
    BevelOuter = bvNone
    Color = clYellow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 9
  end
  object ARFOLYAMGOMB: TPanel
    Left = 824
    Top = 48
    Width = 155
    Height = 33
    Cursor = crHandPoint
    Caption = #193'RFOLYAM ENGEDM'#201'NY'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 10
    OnClick = ARFOLYAMGOMBClick
  end
  object KONVCIMPANEL: TPanel
    Left = 176
    Top = 12
    Width = 593
    Height = 101
    BevelOuter = bvNone
    Caption = 'Konverzi'#243's v'#225's'#225'rl'#225's'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clBlack
    Font.Height = -64
    Font.Name = 'Times New Roman'
    Font.Style = [fsBold, fsItalic]
    ParentFont = False
    TabOrder = 11
  end
  object KONVSUMPANEL: TPanel
    Left = 240
    Top = 560
    Width = 193
    Height = 89
    BevelOuter = bvNone
    Color = 11599871
    TabOrder = 12
    object Label14: TLabel
      Left = 16
      Top = 8
      Width = 111
      Height = 23
      Caption = 'V'#193'S'#193'ROLT '
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label18: TLabel
      Left = 48
      Top = 32
      Width = 104
      Height = 23
      Caption = 'VALUTA(K)'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object Label23: TLabel
      Left = 96
      Top = 56
      Width = 79
      Height = 23
      Caption = #201'RT'#201'KE'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
  end
  object Panel9: TPanel
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
  object Panel13: TPanel
    Left = 724
    Top = 498
    Width = 138
    Height = 21
    Caption = 'Kezel'#233'si k'#246'lts'#233'g:'
    Color = clWhite
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 17
  end
  object Panel10: TPanel
    Left = 42
    Top = 522
    Width = 103
    Height = 21
    BevelOuter = bvNone
    Caption = 'Kezel'#233'si d'#237'j'
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Times New Roman'
    Font.Style = [fsItalic]
    ParentFont = False
    TabOrder = 18
  end
  object NOINTERNETPANEL: TPanel
    Left = 56
    Top = 136
    Width = 233
    Height = 33
    Caption = 'NINCS INTERNET'
    Color = clYellow
    Font.Charset = EASTEUROPE_CHARSET
    Font.Color = clRed
    Font.Height = -24
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 19
    Visible = False
  end
  object QUITSUREPANEL: TPanel
    Left = -1897
    Top = 208
    Width = 465
    Height = 153
    BevelOuter = bvNone
    Color = clWhite
    TabOrder = 5
    Visible = False
    object Shape21: TShape
      Left = 0
      Top = 0
      Width = 465
      Height = 153
      Align = alClient
      Brush.Color = 16728319
      Pen.Color = clMaroon
      Pen.Width = 5
      Shape = stRoundRect
    end
    object Label13: TLabel
      Left = 16
      Top = 32
      Width = 427
      Height = 24
      Caption = 'BIZTOSAN ELDOBJA EZT A V'#193'S'#193'RL'#193'ST ?'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clBlack
      Font.Height = -21
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      Transparent = True
    end
    object IGENKILEPGOMB: TBitBtn
      Left = 112
      Top = 96
      Width = 113
      Height = 25
      Cursor = crHandPoint
      Caption = 'IGEN'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = IGENKILEPGOMBClick
      OnEnter = NEMLEPKIGOMBEnter
      OnExit = NEMLEPKIGOMBExit
    end
    object NEMLEPKIGOMB: TBitBtn
      Left = 256
      Top = 96
      Width = 115
      Height = 25
      Cursor = crHandPoint
      Caption = 'NEM'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = NEMLEPKIGOMBClick
      OnEnter = NEMLEPKIGOMBEnter
      OnExit = NEMLEPKIGOMBExit
    end
  end
  object ENGEDELYADOPANEL: TPanel
    Left = -1989
    Top = 224
    Width = 425
    Height = 241
    TabOrder = 22
    Visible = False
    object ENGSHAPE: TShape
      Left = 1
      Top = 1
      Width = 423
      Height = 239
      Align = alClient
      OnMouseMove = ENGSHAPEMouseMove
    end
    object Label2: TLabel
      Left = 40
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
      Transparent = True
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
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      OnClick = ETGOMBClick
      OnMouseMove = ETGOMBMouseMove
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
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 1
      OnClick = ETGOMBClick
      OnMouseMove = ETGOMBMouseMove
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
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 2
      OnClick = ETGOMBClick
      OnMouseMove = ETGOMBMouseMove
    end
    object MENTESGOMB: TPanel
      Tag = 128
      Left = 40
      Top = 176
      Width = 353
      Height = 25
      Cursor = crHandPoint
      Caption = 'JUTAL'#201'KMENTES ENGED'#201'LYEZ'#201'S'
      Font.Charset = EASTEUROPE_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Calibri'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 3
      OnClick = ETGOMBClick
      OnMouseMove = ETGOMBMouseMove
    end
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
    Left = 224
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
    Left = 256
    Top = 16
  end
  object VALUTAQUERY: TIBQuery
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 192
    Top = 16
  end
  object TETQUERY: TIBQuery
    Database = TETDBASE
    Transaction = TETTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 696
    Top = 144
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
    Left = 728
    Top = 144
  end
  object TETTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TETDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 760
    Top = 144
  end
  object TEMPQUERY: TIBQuery
    Database = TEMPDBASE
    Transaction = TEMPTRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 816
    Top = 144
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
    Left = 848
    Top = 144
  end
  object TEMPTRANZ: TIBTransaction
    Active = False
    DefaultDatabase = TEMPDBASE
    Params.Strings = (
      'read_committed'
      'rec_version'
      'nowait')
    AutoStopAction = saNone
    Left = 880
    Top = 144
  end
  object KILEP: TTimer
    Enabled = False
    Interval = 100
    OnTimer = KILEPTimer
    Left = 8
    Top = 568
  end
  object VALUTATABLA: TIBTable
    Database = VALUTADBASE
    Transaction = VALUTATRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 160
    Top = 16
  end
  object REMOTEQUERY: TIBQuery
    Database = REMOTEDBASE
    Transaction = REMOTETRANZ
    BufferChunks = 1000
    CachedUpdates = False
    Left = 368
    Top = 16
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
    Left = 400
    Top = 16
  end
  object REMOTETRANZ: TIBTransaction
    Active = False
    DefaultDatabase = REMOTEDBASE
    AutoStopAction = saNone
    Left = 432
    Top = 16
  end
end
